import { execFile } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");

async function main() {
  await execFileAsync("node", [path.join("scripts", "build", "index.js")], {
    cwd: repoRoot,
    stdio: "inherit",
  });

  const { stdout } = await execFileAsync("git", ["status", "--porcelain", "dist"], {
    cwd: repoRoot,
  });

  if (stdout.trim().length > 0) {
    console.error("dist/ is not up to date. Run pnpm build:prompts and commit the results.");
    process.exitCode = 1;
    return;
  }

  console.log("dist/ artifacts are up to date.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
