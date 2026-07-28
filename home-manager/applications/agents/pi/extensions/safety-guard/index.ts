/**
 * Safety Guard: Destructive Commands
 *
 * Intercepts bash tool calls that match dangerous patterns and either:
 * - Hard-blocks truly catastrophic commands (dd to disk, mkfs, fork bombs)
 * - Prompts for confirmation on dangerous-but-legitimate commands (rm, sudo, chmod 777)
 *
 * In non-interactive (headless/RPC) mode, all dangerous commands are blocked outright.
 *
 * Patterns are checked against the full command string. The extension is intentionally
 * conservative: it may over-match (e.g. "rm" in a safe context), but that's preferable
 * to missing a real destructive command.
 */

import { isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

// ── Pattern definitions ──────────────────────────────────────────────────────

interface DangerousPattern {
  pattern: RegExp;
  label: string;
  severity: "critical" | "high"; // critical = hard block, high = confirm
}

// Critical: always blocked — no sane reason for an LLM to run these
const CRITICAL_PATTERNS: DangerousPattern[] = [
  {
    pattern: />\s*\/dev\/sd[a-z]/i,
    label: "Write to raw disk device",
    severity: "critical",
  },
  { pattern: /\bmkfs\b/i, label: "Format filesystem", severity: "critical" },
  {
    pattern: /\bdd\b.*\bof=\/dev\//i,
    label: "dd to device",
    severity: "critical",
  },
  {
    pattern: /:\(\)\s*\{\s*:\|:\s*&\s*\}\s*;?\s*:/i,
    label: "Fork bomb",
    severity: "critical",
  },
  {
    pattern: /\brm\s+(-rf?\s+)?\/\s*$/i,
    label: "Delete root filesystem",
    severity: "critical",
  },
  {
    pattern: /\brm\s+(-rf?\s+)?\/\s+/i,
    label: "Delete root filesystem",
    severity: "critical",
  },
  {
    pattern: /\b(shutdown|reboot|halt|poweroff)\b/i,
    label: "System shutdown/reboot",
    severity: "critical",
  },
  {
    pattern: /\biptables\s+-F\b/i,
    label: "Flush firewall rules",
    severity: "critical",
  },
];

// High: require user confirmation
const HIGH_RM_PATTERNS: DangerousPattern[] = [
  {
    pattern: /\brm\s+(-[a-z]*r[a-z]*\s+|--recursive\s+)/i,
    label: "Recursive delete (rm -r)",
    severity: "high",
  },
  {
    pattern: /\brm\s+(-[a-z]*f[a-z]*\s+)/i,
    label: "Force delete (rm -f)",
    severity: "high",
  },
];

const HIGH_PATTERNS: DangerousPattern[] = [
  ...HIGH_RM_PATTERNS,
  {
    pattern: /\bsudo\b/i,
    label: "Elevated privileges (sudo)",
    severity: "high",
  },
  {
    pattern: /\b(chmod|chown)\b.*777/i,
    label: "World-writable permissions",
    severity: "high",
  },
  {
    pattern: /\bchmod\s+-R\b/i,
    label: "Recursive permission change",
    severity: "high",
  },
  {
    pattern: /\bchown\s+-R\b/i,
    label: "Recursive ownership change",
    severity: "high",
  },
  {
    pattern: /\bkillall\b/i,
    label: "Kill all processes by name",
    severity: "high",
  },
  {
    pattern: /\bpkill\s+-9\b/i,
    label: "Force kill processes",
    severity: "high",
  },
  {
    pattern: /\bsystemctl\s+(stop|disable|mask)\b/i,
    label: "Stop/disable system service",
    severity: "high",
  },
  {
    pattern: /\blaunchctl\s+(unload|remove)\b/i,
    label: "Remove macOS service",
    severity: "high",
  },
  {
    pattern: /\b(truncate|shred)\b/i,
    label: "Destructive file operation",
    severity: "high",
  },
];

const ALL_PATTERNS = [...CRITICAL_PATTERNS, ...HIGH_PATTERNS];

function parseShellWords(command: string): string[] | undefined {
  // Compound commands and expansions could hide an additional destructive operation.
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
  // Support the common `rm ... && command` form while rejecting other shell
  // operators and requiring every destructive rm in the chain to be safe.
  const commands = command.split("&&");
  if (commands.some((shellCommand) => shellCommand.trim() === "")) return false;

  let foundDestructiveRm = false;
  for (const shellCommand of commands) {
    const words = parseShellWords(shellCommand);
    if (!words) return false;
    if (words[0] !== "rm") continue;

    const isDestructive = HIGH_RM_PATTERNS.some(({ pattern }) => pattern.test(shellCommand));
    if (!isDestructive) continue;

    foundDestructiveRm = true;
    if (!isSafeRmCommand(shellCommand, cwd)) return false;
  }

  return foundDestructiveRm;
}

function omitSafeGitMessageCleanups(command: string): string {
  // Ignore only this Git-message cleanup fragment, while leaving surrounding
  // shell commands in place so they are still checked against every pattern.
  return command.replace(
    /(^|[;&|\n])\s*gitdir=\$\(git rev-parse --git-dir\)\s*;\s*rm\s+-f\s+"\$gitdir"\/COMMIT_EDITMSG\*\s+"\$gitdir"\/MERGE_MSG\s*;?(?=\s*(?:[;&|\n]|$))/g,
    "$1",
  );
}

function omitSafeFindTargetCleanups(command: string, cwd: string): string {
  // Maven's conventional `target` directories may be deleted without a prompt
  // when find is constrained to roots below the current working directory.
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

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // biome-ignore lint/complexity/noExcessiveCognitiveComplexity: Legacy handler will be refactored
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return undefined;

    const command = event.input.command;
    const commandToCheck = omitSafeFindTargetCleanups(omitSafeGitMessageCleanups(command), ctx.cwd);
    const hasOnlySafeDestructiveRm = areDestructiveRmCommandsSafe(commandToCheck, ctx.cwd);

    // Check all dangerous patterns (first match wins)
    for (const { pattern, label, severity } of ALL_PATTERNS) {
      if (!pattern.test(commandToCheck)) continue;
      if (
        hasOnlySafeDestructiveRm &&
        HIGH_RM_PATTERNS.some(({ pattern: rmPattern }) => rmPattern === pattern)
      ) {
        continue;
      }

      // Critical commands are always hard-blocked
      if (severity === "critical") {
        if (ctx.hasUI) ctx.ui.notify(`🚫 Blocked: ${label}`, "error");
        return {
          block: true,
          reason: `CRITICAL: ${label} — command is never allowed`,
        };
      }

      // High-severity: confirm with user, or block if no UI
      if (!ctx.hasUI) {
        return {
          block: true,
          reason: `${label} blocked (non-interactive mode)`,
        };
      }

      // Tell state integrations that the agent is waiting for user input. Pi does
      // not expose confirmation dialogs as lifecycle events, so Herdr cannot
      // infer this state from the tool_call event alone.
      pi.events.emit("herdr:blocked", { active: true, label });
      try {
        // Truncate very long commands for the confirmation dialog
        const displayCmd = command.length > 120 ? `${command.slice(0, 120)}…` : command;
        const ok = await ctx.ui.confirm(`⚠️ ${label}`, `${displayCmd}\n\nAllow this command?`);

        return ok ? undefined : { block: true, reason: `${label} — blocked by user` };
      } finally {
        pi.events.emit("herdr:blocked", { active: false });
      }
    }

    return undefined;
  });

  // Show active status on session start
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.hasUI) {
      ctx.ui.setStatus("safety-cmds", ctx.ui.theme.fg("success", "🛡️ cmd-guard"));
    }
  });
}
