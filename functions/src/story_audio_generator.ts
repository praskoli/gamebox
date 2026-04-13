import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

const DEFAULT_REGION = "us-central1";

export const onSceneWriteGenerateNarrationAudio = onDocumentWritten(
  {
    document: "stories/{storyId}/scenes/{sceneId}",
    region: DEFAULT_REGION,
    retry: false,
  },
  async (event) => {
    logger.info("Narration audio generation is disabled by configuration.", {
      storyId: event.params.storyId,
      sceneId: event.params.sceneId,
    });
    return;
  }
);