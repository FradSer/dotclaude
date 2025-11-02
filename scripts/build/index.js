import { generateForPlugin } from "./generators/index.js";
import { loadSharedFragments, readPlatformMetadata, readPromptFiles } from "./readers.js";
import { resetDist, writeClaudeMarketplace, writeManifest } from "./writers.js";

async function main() {
  const sharedFragments = await loadSharedFragments();
  const promptFiles = await readPromptFiles(sharedFragments);
  const platforms = await readPlatformMetadata();

  await resetDist();

  for (const promptFile of promptFiles) {
    await generateForPlugin(promptFile, platforms);
  }

  await writeManifest(promptFiles, platforms);
  await writeClaudeMarketplace(promptFiles);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
