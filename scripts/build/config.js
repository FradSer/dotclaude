import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");

export const config = {
  repoRoot,
  configRoot: path.join(repoRoot, "config"),
  distRoot: path.join(repoRoot, "dist"),
  sharedRoot: path.join(repoRoot, "prompts", "_shared"),
  claudeMarketplacePath: path.join(repoRoot, ".claude-plugin", "marketplace.json"),
  platformOrder: ["claude", "cursor", "codex", "gemini"],
};

export async function safeReadDir(directory) {
  const { promises: fs } = await import("node:fs");
  try {
    return await fs.readdir(directory, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}
