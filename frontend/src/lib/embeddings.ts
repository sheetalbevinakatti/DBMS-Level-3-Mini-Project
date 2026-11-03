import { pipeline, type FeatureExtractionPipeline } from "@huggingface/transformers";

type FeatureExtractor = InstanceType<typeof FeatureExtractionPipeline>;
let extractorPromise: Promise<FeatureExtractor> | undefined;

async function getExtractor(): Promise<FeatureExtractor> {
  if (!extractorPromise) {
    extractorPromise = pipeline("feature-extraction", "Xenova/all-MiniLM-L6-v2", {
      dtype: "q8",
    });
  }
  return extractorPromise;
}

export async function embedText(text: string): Promise<number[]> {
  const extractor = await getExtractor();
  const output = await extractor(text, { pooling: "mean", normalize: true });
  const vector = Array.from(output.data as Float32Array, Number);
  if (vector.length !== 384 || vector.some((value) => !Number.isFinite(value))) {
    throw new Error("The embedding model returned an invalid vector.");
  }
  return vector;
}
