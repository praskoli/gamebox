const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

const serviceAccountPath = path.join(__dirname, "..", "serviceAccountKey.json");

if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    "Missing serviceAccountKey.json in functions folder.\n" +
      "Place it here:\n" +
      "D:\\Prasanth\\FlutterProjects\\gamebox\\functions\\serviceAccountKey.json"
  );
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function triggerOldStoryAudio() {
  console.log("Starting old story audio trigger process...");

  const storiesSnap = await db.collection("stories").get();

  if (storiesSnap.empty) {
    console.log("No stories found.");
    return;
  }

  let totalStories = 0;
  let totalScenesChecked = 0;
  let totalTriggered = 0;
  let totalSkippedNoNarration = 0;
  let totalSkippedReady = 0;
  let totalFailed = 0;

  for (const storyDoc of storiesSnap.docs) {
    totalStories++;

    const storyId = storyDoc.id;
    console.log(`\nProcessing story: ${storyId}`);

    const scenesSnap = await db
      .collection("stories")
      .doc(storyId)
      .collection("scenes")
      .get();

    if (scenesSnap.empty) {
      console.log("  No scenes found.");
      continue;
    }

    for (const sceneDoc of scenesSnap.docs) {
      totalScenesChecked++;

      const data = sceneDoc.data() || {};
      const narration = String(data.narration || "").trim();
      const narrationAudioUrl = String(data.narrationAudioUrl || "").trim();
      const audioStatus = String(data.audioStatus || "").trim().toLowerCase();

      if (!narration) {
        totalSkippedNoNarration++;
        console.log(`  Skipping ${sceneDoc.id} -> no narration`);
        continue;
      }

      if (narrationAudioUrl && audioStatus === "ready") {
        totalSkippedReady++;
        console.log(`  Skipping ${sceneDoc.id} -> audio already ready`);
        continue;
      }

      try {
        await sceneDoc.ref.set(
          {
            audioStatus: "pending",
            audioMigrationRequestedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            audioMigrationTriggerNonce: Date.now().toString() +
              "_" +
              Math.random().toString(36).substring(2, 8),
          },
          { merge: true }
        );

        totalTriggered++;
        console.log(`  Triggered ${sceneDoc.id}`);
      } catch (error) {
        totalFailed++;
        console.error(`  Failed ${sceneDoc.id}`, error);
      }
    }
  }

  console.log("\nDone.");
  console.log(`Stories checked: ${totalStories}`);
  console.log(`Scenes checked: ${totalScenesChecked}`);
  console.log(`Triggered: ${totalTriggered}`);
  console.log(`Skipped (no narration): ${totalSkippedNoNarration}`);
  console.log(`Skipped (already ready): ${totalSkippedReady}`);
  console.log(`Failed: ${totalFailed}`);
}

triggerOldStoryAudio()
  .then(() => {
    console.log("\nBulk trigger completed successfully.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\nBulk trigger failed.", error);
    process.exit(1);
  });