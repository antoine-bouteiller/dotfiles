import { isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import {
  ALL_PATTERNS,
  COMMAND_EXCERPT_CONTEXT_LINES,
  COMMAND_EXCERPT_MAX_LENGTH,
  HIGH_RM_PATTERNS,
  PROTECTED_PATH_PATTERNS,
  PUBLIC_ENV_FILENAMES,
  SAFETY_STATUS_KEY,
} from "./constants";

function parseShellWords(command: string): string[] | undefined {
  if (/[;&|<>`$()\r\n{}]/.test(command)) return undefined;

  const words: string[] = [];
  let word = "";
  let quote: "'" | '"' | undefined;
  let escaped = false;

  for (const char of command.trim()) {
    if (escaped) {
      word += char;
      escaped = false;
    } else if (char === "\\" && quote !== "'") {
      escaped = true;
    } else if (quote) {
      if (char === quote) quote = undefined;
      else word += char;
    } else if (char === "'" || char === '"') {
      quote = char;
    } else if (/\s/.test(char)) {
      if (word) {
        words.push(word);
        word = "";
      }
    } else {
      word += char;
    }
  }

  if (escaped || quote) return undefined;
  if (word) words.push(word);
  return words;
}

function isDescendant(root: string, candidate: string): boolean {
  const pathFromRoot = relative(root, candidate);
  return (
    pathFromRoot !== "" &&
    pathFromRoot !== ".." &&
    !pathFromRoot.startsWith(`..${sep}`) &&
    !isAbsolute(pathFromRoot)
  );
}

function isSafeRmCommand(command: string, cwd: string): boolean {
  const words = parseShellWords(command);
  if (!words || words[0] !== "rm") return false;

  let hasForceOrRecursive = false;
  let parsingOptions = true;
  const targets: string[] = [];

  for (const word of words.slice(1)) {
    if (parsingOptions && word === "--") {
      parsingOptions = false;
    } else if (parsingOptions && word.startsWith("--")) {
      if (word === "--force" || word === "--recursive") hasForceOrRecursive = true;
    } else if (parsingOptions && /^-[^-]/.test(word)) {
      if (/[fRr]/.test(word.slice(1))) hasForceOrRecursive = true;
    } else {
      targets.push(word);
    }
  }

  if (!hasForceOrRecursive || targets.length === 0) return false;

  const allowedRoots = [resolve(cwd), resolve("/tmp")];
  return targets.every((target) => {
    if (target.startsWith("~")) return false;
    const resolvedTarget = resolve(cwd, target);
    return allowedRoots.some((root) => isDescendant(root, resolvedTarget));
  });
}

function areDestructiveRmCommandsSafe(command: string, cwd: string): boolean {
  const commands = command.split("&&");
  if (commands.some((shellCommand) => shellCommand.trim() === "")) return false;

  let foundDestructiveRm = false;
  for (const shellCommand of commands) {
    if (!HIGH_RM_PATTERNS.some(({ pattern }) => pattern.test(shellCommand))) continue;
    foundDestructiveRm = true;
    if (!isSafeRmCommand(shellCommand, cwd)) return false;
  }

  return foundDestructiveRm;
}

function omitSafeGitMessageCleanups(command: string): string {
  return command.replace(
    /(^|[;&|\n])\s*gitdir=\$\(git rev-parse --git-dir\)\s*;\s*rm\s+-f\s+"\$gitdir"\/COMMIT_EDITMSG\*\s+"\$gitdir"\/MERGE_MSG\s*;?(?=\s*(?:[;&|\n]|$))/g,
    "$1",
  );
}

function omitSafeFindTargetCleanups(command: string, cwd: string): string {
  return command.replace(
    /(^|[;&|\n])\s*(?:\/usr\/bin\/)?find\s+(.+?)\s+-type\s+d\s+-name\s+(?:target|'target'|"target")\s+-prune\s+-exec\s+rm\s+-rf\s+\{\}\s+\+(?=\s*(?:[;&|\n]|$))/g,
    (match, separator: string, rawRoots: string) => {
      const roots = parseShellWords(rawRoots);
      if (
        !roots ||
        roots.length === 0 ||
        roots.some(
          (root) =>
            root.startsWith("-") ||
            root.startsWith("~") ||
            !isDescendant(resolve(cwd), resolve(cwd, root)),
        )
      ) {
        return match;
      }
      return separator;
    },
  );
}

function commandExcerpt(command: string, pattern: RegExp): string {
  const lines = command.split(/\r?\n/);
  const matchedIndex = Math.max(
    0,
    lines.findIndex((line) => pattern.test(line)),
  );
  const start = Math.max(0, matchedIndex - COMMAND_EXCERPT_CONTEXT_LINES);
  const end = Math.min(lines.length, matchedIndex + COMMAND_EXCERPT_CONTEXT_LINES + 1);
  return lines
    .slice(start, end)
    .map((line, offset) => {
      const lineNumber = start + offset + 1;
      const marker = start + offset === matchedIndex ? ">" : " ";
      const displayed =
        line.length > COMMAND_EXCERPT_MAX_LENGTH
          ? `${line.slice(0, COMMAND_EXCERPT_MAX_LENGTH)}…`
          : line;
      return `${marker} ${lineNumber}: ${displayed}`;
    })
    .join("\n");
}

function isProtectedPath(targetPath: string, cwd: string): boolean {
  const normalized = resolve(cwd, targetPath).replaceAll("\\", "/").toLowerCase();
  const basename = normalized.slice(normalized.lastIndexOf("/") + 1);
  if (PUBLIC_ENV_FILENAMES.has(basename)) return false;

  return PROTECTED_PATH_PATTERNS.some((pattern) => pattern.test(normalized));
}

async function confirmRisk(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  label: string,
  message: string,
): Promise<{ block: true; reason: string } | undefined> {
  if (!ctx.hasUI) return { block: true, reason: `${label} blocked (non-interactive mode)` };

  pi.events.emit("herdr:blocked", { active: true, label });
  try {
    const allowed = await ctx.ui.confirm(`⚠️ ${label}`, `${message}\n\nAllow this operation?`);
    return allowed ? undefined : { block: true, reason: `${label} — blocked by user` };
  } finally {
    pi.events.emit("herdr:blocked", { active: false });
  }
}

export default function safetyGuard(pi: ExtensionAPI) {
  // biome-ignore lint/complexity/noExcessiveCognitiveComplexity: Rule dispatch is intentionally centralized
  pi.on("tool_call", async (event, ctx) => {
    let command: string | undefined;
    if (isToolCallEventType("bash", event)) {
      command = event.input.command;
    } else if (event.toolName === "background_poll") {
      const input = event.input as { command?: unknown };
      if (typeof input.command === "string") command = input.command;
    }

    if (command !== undefined) {
      const commandToCheck = omitSafeFindTargetCleanups(
        omitSafeGitMessageCleanups(command),
        ctx.cwd,
      );
      const hasOnlySafeDestructiveRm = areDestructiveRmCommandsSafe(commandToCheck, ctx.cwd);

      for (const rule of ALL_PATTERNS) {
        if (!rule.pattern.test(commandToCheck)) continue;
        if (
          hasOnlySafeDestructiveRm &&
          HIGH_RM_PATTERNS.some(({ pattern }) => pattern === rule.pattern)
        ) {
          continue;
        }

        if (rule.severity === "critical") {
          if (ctx.hasUI) ctx.ui.notify(`🚫 Blocked: ${rule.label}`, "error");
          return {
            block: true,
            reason: `CRITICAL: ${rule.label} — command is never allowed`,
          };
        }

        return confirmRisk(
          pi,
          ctx,
          rule.label,
          `Category: ${rule.category}\n\n${commandExcerpt(command, rule.pattern)}`,
        );
      }
      return undefined;
    }

    let protectedOperation: "edit" | "read" | "write" | undefined;
    let protectedPath: string | undefined;
    if (isToolCallEventType("read", event)) {
      protectedOperation = "read";
      protectedPath = event.input.path;
    } else if (isToolCallEventType("write", event)) {
      protectedOperation = "write";
      protectedPath = event.input.path;
    } else if (isToolCallEventType("edit", event)) {
      protectedOperation = "edit";
      protectedPath = event.input.path;
    }

    if (
      protectedOperation === undefined ||
      protectedPath === undefined ||
      !isProtectedPath(protectedPath, ctx.cwd)
    ) {
      return undefined;
    }

    const label = `Protected file ${protectedOperation}`;
    return confirmRisk(pi, ctx, label, `${protectedOperation} ${protectedPath}`);
  });

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.hasUI) {
      ctx.ui.setStatus(SAFETY_STATUS_KEY, ctx.ui.theme.fg("success", "🛡️ cmd-guard"));
    }
  });
}
