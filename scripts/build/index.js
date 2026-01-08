import { generateForPlugin } from "./generators/index.js";
import { loadSharedFragments, readPlatformMetadata, readPromptFiles, readSkills } from "./readers.js";
import { copySkills, resetDist, writeClaudeMarketplace, writeManifest } from "./writers.js";

async function main() {
  const sharedFragments = await loadSharedFragments();
  const promptFiles = await readPromptFiles(sharedFragments);
  const platforms = await readPlatformMetadata();
  const skills = await readSkills();

  await resetDist();

  for (const promptFile of promptFiles) {
    await generateForPlugin(promptFile, platforms);
  }

  await copySkills(skills);
  await writeManifest(promptFiles, platforms);
  await writeClaudeMarketplace(promptFiles, skills);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
