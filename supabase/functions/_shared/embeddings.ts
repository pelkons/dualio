export type EmbeddingGenerationStatus = "complete" | "disabled" | "failed";

export type EmbeddingGenerationResult = {
  status: EmbeddingGenerationStatus;
  model?: string;
  vectors: number[][];
  error?: string;
};

export async function generateEmbeddings(
  input: string[],
): Promise<EmbeddingGenerationResult> {
  const texts = input.map((value) => value.replace(/\s+/g, " ").trim());
  if (texts.length === 0 || texts.every((value) => value.length === 0)) {
    return { status: "complete", vectors: [] };
  }

  const openRouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (openRouterApiKey) {
    const model = Deno.env.get("AI_EMBEDDING_MODEL") ||
      "openai/text-embedding-3-small";
    const result = await requestEmbeddings({
      apiKey: openRouterApiKey,
      url: "https://openrouter.ai/api/v1/embeddings",
      model,
      input: texts,
      provider: {
        allow_fallbacks: true,
        data_collection: "deny",
      },
    });
    if (result.status === "complete" || !Deno.env.get("OPENAI_API_KEY")) {
      return result;
    }
  }

  const model = Deno.env.get("OPENAI_EMBEDDING_MODEL") ||
    "text-embedding-3-small";
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return { status: "disabled", vectors: [] };
  }

  return await requestEmbeddings({
    apiKey,
    url: "https://api.openai.com/v1/embeddings",
    model,
    input: texts,
  });
}

async function requestEmbeddings(input: {
  apiKey: string;
  url: string;
  model: string;
  input: string[];
  provider?: Record<string, unknown>;
}): Promise<EmbeddingGenerationResult> {
  try {
    const response = await fetch(input.url, {
      method: "POST",
      headers: {
        "authorization": `Bearer ${input.apiKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: input.model,
        input: input.input.map((value) => value || " "),
        ...(input.provider ? { provider: input.provider } : {}),
      }),
    });

    if (!response.ok) {
      return {
        status: "failed",
        model: input.model,
        vectors: [],
        error: `http_${response.status}`,
      };
    }

    const payload = await response.json();
    const data = Array.isArray(payload.data) ? payload.data : [];
    const vectors = data
      .slice()
      .sort((left: Record<string, unknown>, right: Record<string, unknown>) =>
        numberValue(left.index) - numberValue(right.index)
      )
      .map((item: Record<string, unknown>) => vectorValue(item.embedding))
      .filter((vector: number[]) => vector.length > 0);

    if (vectors.length !== input.input.length) {
      return {
        status: "failed",
        model: input.model,
        vectors: [],
        error: "embedding_count_mismatch",
      };
    }

    return { status: "complete", model: input.model, vectors };
  } catch (error) {
    return {
      status: "failed",
      model: input.model,
      vectors: [],
      error: error instanceof Error ? error.name : "unknown_error",
    };
  }
}

export function embeddingToPgVector(vector: number[]): string {
  return `[${
    vector.map((value) => Number.isFinite(value) ? String(value) : "0").join(
      ",",
    )
  }]`;
}

function vectorValue(value: unknown): number[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) =>
      typeof item === "number" && Number.isFinite(item) ? item : null
    )
    .filter((item): item is number => item !== null);
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
