import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { mkdir, mkdtemp, readFile, readdir, realpath, rm, stat, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { extname, join, relative, sep } from "node:path";

interface MarkdownFile {
  path: string;
  relativePath: string;
}

interface Rule {
  relativePath: string;
  paths: string[];
}

interface GlobalRules {
  inline: string;
  scoped: Rule[];
}

export interface RuleFrontmatter {
  body: string;
  paths: string[];
}

interface CommandFrontmatter {
  body: string;
  description: string;
}

async function discoverMarkdownFiles(root: string): Promise<MarkdownFile[]> {
  const files: MarkdownFile[] = [];
  const visitedDirectories = new Set<string>();

  async function walk(directory: string): Promise<void> {
    let canonicalDirectory: string;
    try {
      canonicalDirectory = await realpath(directory);
    } catch {
      return;
    }

    if (visitedDirectories.has(canonicalDirectory)) return;
    visitedDirectories.add(canonicalDirectory);

    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch {
      return;
    }

    entries.sort((left, right) => left.name.localeCompare(right.name));

    for (const entry of entries) {
      const path = join(directory, entry.name);
      let isDirectory = entry.isDirectory();
      let isFile = entry.isFile();

      if (entry.isSymbolicLink()) {
        try {
          const target = await stat(path);
          isDirectory = target.isDirectory();
          isFile = target.isFile();
        } catch {
          continue;
        }
      }

      if (isDirectory) {
        await walk(path);
      } else if (isFile && extname(entry.name) === ".md") {
        files.push({ path, relativePath: relative(root, path).split(sep).join("/") });
      }
    }
  }

  await walk(root);
  return files;
}

function unquote(value: string): string {
  return value.replace(/^["']|["']$/g, "");
}

function splitInlinePaths(value: string): string[] {
  return value
    .replace(/^\[|\]$/g, "")
    .split(",")
    .map((entry) => unquote(entry.trim()))
    .filter(Boolean);
}

function parsePaths(frontmatter: string): string[] {
  const lines = frontmatter.split("\n");
  const index = lines.findIndex((line) => /^\s*paths\s*:/.test(line));
  if (index === -1) return [];

  const inline = lines[index].replace(/^\s*paths\s*:/, "").trim();
  if (inline) return splitInlinePaths(inline);

  const paths: string[] = [];
  for (let lineIndex = index + 1; lineIndex < lines.length; lineIndex++) {
    const entry = lines[lineIndex].trimStart();
    if (!entry.startsWith("-")) break;
    const value = entry.slice(1).trim();
    if (!value) break;
    paths.push(unquote(value));
  }
  return paths;
}

/** Extract Claude Code's optional `paths` frontmatter from a rule. */
export function parseRuleFrontmatter(content: string): RuleFrontmatter {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/.exec(content);
  if (!match) return { body: content, paths: [] };
  return { body: content.slice(match[0].length), paths: parsePaths(match[1]) };
}

/** Convert a Claude command into Agent Skills-compatible metadata and content. */
export function parseCommandFrontmatter(content: string): CommandFrontmatter {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/.exec(content);
  const body = match ? content.slice(match[0].length) : content;
  const descriptionMatch = match?.[1].match(/^\s*description\s*:\s*(.*?)\s*$/m);
  const firstContentLine = body
    .split(/\r?\n/)
    .map((line) => line.trim())
    .find(Boolean)
    ?.replace(/^#+\s*/, "");
  const description =
    unquote(descriptionMatch?.[1] ?? "") || firstContentLine || "Claude Code command";
  return { body, description: description.slice(0, 1024) };
}

function commandSkillName(relativePath: string): string {
  const withoutExtension = relativePath.slice(0, -extname(relativePath).length);
  const normalized = withoutExtension
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64)
    .replace(/-+$/g, "");
  return normalized || "claude-command";
}

function formatCommandSkill(name: string, command: CommandFrontmatter): string {
  const argumentCompatibility = command.body.match(/\$(?:ARGUMENTS|[1-9]\d*)\b/)
    ? "Pi appends invocation arguments as a final `User: <arguments>` line. Treat those arguments as `$ARGUMENTS`, and their shell-style positional words as `$1`, `$2`, and so on. If no `User:` line is present, the arguments are empty.\n\n"
    : "";
  return `---\nname: ${name}\ndescription: ${JSON.stringify(command.description)}\n---\n\n${argumentCompatibility}${command.body}`;
}

/** Format a lazy-loaded rule and its optional path scope for the system prompt. */
export function formatRulePointer(
  relativePath: string,
  paths: string[],
  base = ".claude/rules",
): string {
  const pointer = `- ${base}/${relativePath}`;
  return paths.length > 0 ? `${pointer} — applies when working on: ${paths.join(", ")}` : pointer;
}

async function readGlobalRules(rulesDirectory: string): Promise<GlobalRules> {
  const inline: string[] = [];
  const scoped: Rule[] = [];

  for (const file of await discoverMarkdownFiles(rulesDirectory)) {
    try {
      const parsed = parseRuleFrontmatter(await readFile(file.path, "utf8"));
      if (parsed.paths.length > 0) {
        scoped.push({ relativePath: file.relativePath, paths: parsed.paths });
      } else if (parsed.body.trim()) {
        inline.push(parsed.body.trim());
      }
    } catch {
      // One unreadable rule should not prevent the remaining rules from loading.
    }
  }

  return { inline: inline.join("\n\n"), scoped };
}

async function readProjectRules(rulesDirectory: string): Promise<Rule[]> {
  const rules: Rule[] = [];
  for (const file of await discoverMarkdownFiles(rulesDirectory)) {
    try {
      const parsed = parseRuleFrontmatter(await readFile(file.path, "utf8"));
      rules.push({ relativePath: file.relativePath, paths: parsed.paths });
    } catch {
      rules.push({ relativePath: file.relativePath, paths: [] });
    }
  }
  return rules;
}

export default function claudeCodeExtension(pi: ExtensionAPI) {
  let generatedSkillDirectory: string | undefined;
  let globalRules: GlobalRules = { inline: "", scoped: [] };
  let projectRules: Rule[] = [];

  async function cleanup(): Promise<void> {
    if (!generatedSkillDirectory) return;
    const directory = generatedSkillDirectory;
    generatedSkillDirectory = undefined;
    await rm(directory, { force: true, recursive: true });
  }

  pi.on("session_start", async (_event, ctx) => {
    globalRules = await readGlobalRules(join(homedir(), ".claude", "rules"));
    projectRules = ctx.isProjectTrusted()
      ? await readProjectRules(join(ctx.cwd, ".claude", "rules"))
      : [];
  });

  pi.on("resources_discover", async (event, ctx) => {
    await cleanup();

    // Project commands intentionally override user commands with the same skill name.
    const commandsByName = new Map<string, MarkdownFile>();
    for (const command of await discoverMarkdownFiles(join(homedir(), ".claude", "commands"))) {
      commandsByName.set(commandSkillName(command.relativePath), command);
    }

    if (ctx.isProjectTrusted()) {
      for (const command of await discoverMarkdownFiles(join(event.cwd, ".claude", "commands"))) {
        commandsByName.set(commandSkillName(command.relativePath), command);
      }
    }

    if (commandsByName.size === 0) return;

    const skillDirectory = await mkdtemp(join(tmpdir(), "pi-claude-command-skills-"));
    generatedSkillDirectory = skillDirectory;

    await Promise.all(
      [...commandsByName].map(async ([name, command]) => {
        const destination = join(skillDirectory, name);
        await mkdir(destination, { recursive: true });
        const parsed = parseCommandFrontmatter(await readFile(command.path, "utf8"));
        await writeFile(join(destination, "SKILL.md"), formatCommandSkill(name, parsed), "utf8");
      }),
    );

    return { skillPaths: [skillDirectory] };
  });

  pi.on("before_agent_start", (event) => {
    let addition = "";

    if (globalRules.inline || globalRules.scoped.length > 0) {
      addition += "\n\n## Global Rules";
      if (globalRules.inline) {
        addition += `\n\nThese rules always apply:\n\n${globalRules.inline}`;
      }
      if (globalRules.scoped.length > 0) {
        const pointers = globalRules.scoped
          .map((rule) => formatRulePointer(rule.relativePath, rule.paths, "~/.claude/rules"))
          .join("\n");
        addition += `\n\nPath-scoped global rules available in ~/.claude/rules/:\n\n${pointers}\n\nRead the relevant rule file with the read tool before working on files it covers.`;
      }
    }

    if (projectRules.length > 0) {
      const pointers = projectRules
        .map((rule) => formatRulePointer(rule.relativePath, rule.paths))
        .join("\n");
      addition += `\n\n## Project Rules\n\nThe following project rules are available in .claude/rules/:\n\n${pointers}\n\nRead the relevant rule file with the read tool before working on files it covers; rules with an “applies when” scope are path-scoped.`;
    }

    if (!addition) return;
    return { systemPrompt: event.systemPrompt + addition };
  });

  pi.on("session_shutdown", cleanup);
}
