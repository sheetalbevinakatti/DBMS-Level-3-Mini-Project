import { embedText } from "@/lib/embeddings";

const collection = "patentpath_inventions";
const vectorSize = 384;

type QdrantPoint = {
  id: number;
  score: number;
  payload?: Record<string, unknown>;
};

function getQdrantUrl(): string {
  const url = process.env.QDRANT_URL;
  if (!url) throw new Error("QDRANT_URL must be configured.");
  return url.replace(/\/+$/, "");
}

async function qdrantRequest(path: string, init?: RequestInit): Promise<Response> {
  const headers = new Headers(init?.headers);
  headers.set("Content-Type", "application/json");
  if (process.env.QDRANT_API_KEY) headers.set("api-key", process.env.QDRANT_API_KEY);
  return fetch(`${getQdrantUrl()}${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });
}

async function ensureCollection(): Promise<void> {
  const response = await qdrantRequest(`/collections/${collection}`);
  if (response.ok) return;
  if (response.status !== 404) {
    throw new Error(`Qdrant collection check failed (${response.status}): ${await response.text()}`);
  }

  const createResponse = await qdrantRequest(`/collections/${collection}`, {
    method: "PUT",
    body: JSON.stringify({ vectors: { size: vectorSize, distance: "Cosine" } }),
  });
  if (!createResponse.ok && createResponse.status !== 409) {
    throw new Error(`Qdrant collection creation failed (${createResponse.status}): ${await createResponse.text()}`);
  }
}

export async function upsertInventionVector(
  invention: { invention_id: number; title: string; abstract: string | null; description: string | null; category: string },
): Promise<void> {
  await ensureCollection();
  const text = [invention.title, invention.category, invention.abstract, invention.description]
    .filter(Boolean)
    .join(". ");
  const vector = await embedText(text);
  const response = await qdrantRequest(`/collections/${collection}/points?wait=true`, {
    method: "PUT",
    body: JSON.stringify({
      points: [{
        id: invention.invention_id,
        vector,
        payload: { title: invention.title, category: invention.category },
      }],
    }),
  });
  if (!response.ok) {
    throw new Error(`Qdrant upsert failed (${response.status}): ${await response.text()}`);
  }
}

export async function removeInventionVector(inventionId: number): Promise<void> {
  const response = await qdrantRequest(`/collections/${collection}/points/delete?wait=true`, {
    method: "POST",
    body: JSON.stringify({ points: [inventionId] }),
  });
  if (!response.ok && response.status !== 404) {
    throw new Error(`Qdrant delete failed (${response.status}): ${await response.text()}`);
  }
}

export async function searchInventionVectors(query: string, limit = 10): Promise<QdrantPoint[]> {
  await ensureCollection();
  const vector = await embedText(query);
  const response = await qdrantRequest(`/collections/${collection}/points/query`, {
    method: "POST",
    body: JSON.stringify({
      query: vector,
      limit,
      with_payload: true,
      with_vector: false,
    }),
  });
  if (!response.ok) {
    throw new Error(`Qdrant search failed (${response.status}): ${await response.text()}`);
  }

  const body = (await response.json()) as { result?: { points?: QdrantPoint[] } };
  return body.result?.points ?? [];
}
