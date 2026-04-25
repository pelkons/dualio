import { embeddingToPgVector, generateEmbeddings } from "./embeddings.ts";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

async function withoutEmbeddingKeys<T>(callback: () => Promise<T>): Promise<T> {
  const previousOpenAi = Deno.env.get("OPENAI_API_KEY");
  const previousOpenRouter = Deno.env.get("OPENROUTER_API_KEY");
  Deno.env.delete("OPENAI_API_KEY");
  Deno.env.delete("OPENROUTER_API_KEY");
  try {
    return await callback();
  } finally {
    if (previousOpenAi === undefined) {
      Deno.env.delete("OPENAI_API_KEY");
    } else {
      Deno.env.set("OPENAI_API_KEY", previousOpenAi);
    }
    if (previousOpenRouter === undefined) {
      Deno.env.delete("OPENROUTER_API_KEY");
    } else {
      Deno.env.set("OPENROUTER_API_KEY", previousOpenRouter);
    }
  }
}

Deno.test("generateEmbeddings is disabled when AI keys are missing", async () => {
  const result = await withoutEmbeddingKeys(() =>
    generateEmbeddings(["Saved semantic memory"])
  );
  assertEquals(result.status, "disabled");
  assertEquals(result.vectors.length, 0);
});

Deno.test("embeddingToPgVector serializes vector literal", () => {
  assertEquals(embeddingToPgVector([0.1, -0.2, Number.NaN]), "[0.1,-0.2,0]");
});
