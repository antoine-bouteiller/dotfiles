import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
  formatHashlineHeader,
  formatNumberedLines,
  normalizeToLF,
  NodeFilesystem,
  InMemorySnapshotStore,
  Patch,
  Patcher,
} from "@oh-my-pi/hashline";
import { relative, resolve } from "node:path";

const readSchema = Type.Object({
  path: Type.String({ description: "Path to the file to read." }),
});

const writeSchema = Type.Object({
  patch: Type.String({
    description:
      "A hashline patch. Start each file section with [path#TAG], where TAG comes from hashline_read.",
  }),
});

function result(text: string, details: Record<string, unknown> = {}) {
  return { content: [{ type: "text" as const, text }], details };
}

export default function hashline(pi: ExtensionAPI) {
  const fs = new NodeFilesystem();
  const snapshots = new InMemorySnapshotStore();

  pi.registerTool({
    name: "hashline_read",
    label: "Hashline Read",
    description:
      "Read a file with stable line anchors and a content hash for hashline_write. Use this instead of read before editing a file with hashline.",
    parameters: readSchema,
    async execute(_toolCallId, { path }, _signal, _onUpdate, ctx) {
      const absolutePath = resolve(ctx.cwd, path);
      const text = await fs.readText(absolutePath);
      const normalized = normalizeToLF(text);
      const tag = snapshots.record(absolutePath, normalized);
      const displayPath = relative(ctx.cwd, absolutePath) || ".";

      return result(
        `${formatHashlineHeader(displayPath, tag)}\n${formatNumberedLines(normalized)}`,
        { path: displayPath, hash: tag },
      );
    },
  });

  pi.registerTool({
    name: "hashline_write",
    label: "Hashline Write",
    description:
      "Apply a hashline patch produced from hashline_read. Hashline patches are content-hash anchored and reject stale edits instead of silently applying them to the wrong file.",
    parameters: writeSchema,
    promptGuidelines: [
      "Use hashline_read before hashline_write so every section has a current [path#TAG] anchor.",
      "Use hashline_write for targeted edits; use the built-in write tool when creating a new file from scratch.",
    ],
    async execute(_toolCallId, { patch }, _signal, _onUpdate, ctx) {
      const parsed = Patch.parse(patch, { cwd: ctx.cwd });
      const patcher = new Patcher({ fs, snapshots });
      const applied = await patcher.apply(parsed);
      const summary = applied.sections.map((section) => {
        const target = relative(ctx.cwd, section.canonicalPath) || section.canonicalPath;
        return `${section.op} ${target} [${section.fileHash}]`;
      });

      return result(summary.join("\n"), { sections: applied.sections });
    },
  });
}
