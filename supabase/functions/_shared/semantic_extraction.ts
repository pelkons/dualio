import type { LinkResolverResult } from "./link_resolver.ts";
import { callOpenRouterStructuredJson, parseJsonObject } from "./openrouter.ts";

export type SemanticContentType =
  | "recipe"
  | "film"
  | "place"
  | "article"
  | "product"
  | "video"
  | "manual"
  | "note"
  | "unknown";

export type SemanticExtractionStatus =
  | "complete"
  | "partial"
  | "ai_disabled"
  | "failed";

export type SemanticEntity = {
  entity: string;
  entityType: string;
  normalizedValue: string;
  metadata?: Record<string, unknown>;
};

export type SemanticChunk = {
  chunkType: string;
  content: string;
  metadata?: Record<string, unknown>;
};

export type SemanticExtraction = {
  title: string;
  summary: string;
  contentType: SemanticContentType;
  language: string;
  aliases: string[];
  entities: SemanticEntity[];
  chunks: SemanticChunk[];
  structuredFields: Record<string, unknown>;
  needsClarification: boolean;
  clarificationQuestion?: string;
  extractionStatus: SemanticExtractionStatus;
  model?: string;
};

export type SemanticExtractionInput =
  | {
    sourceType: "link";
    url: string;
    title: string;
    summary: string;
    fallbackContentType: SemanticContentType;
    resolvedLink: LinkResolverResult;
  }
  | {
    sourceType: "text";
    text: string;
    title: string;
    fallbackContentType: SemanticContentType;
    userNote?: string;
  };

export async function extractSemanticItem(
  input: SemanticExtractionInput,
): Promise<SemanticExtraction> {
  const openRouterResult = await callOpenRouterStructuredJson({
    models: semanticExtractionModels(),
    messages: [{ role: "user", content: buildExtractionPrompt(input) }],
    schemaName: "semantic_item_extraction",
    schema: semanticExtractionSchema,
  });
  if (openRouterResult.status === "complete" && openRouterResult.json) {
    return normalizeSemanticExtraction(
      openRouterResult.json,
      input,
      openRouterResult.model ?? semanticExtractionModels()[0],
    );
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return fallbackSemanticExtraction(
      input,
      openRouterResult.status === "failed" ? "failed" : "ai_disabled",
      openRouterResult.model,
    );
  }

  const model = Deno.env.get("OPENAI_MODEL_TEXT") ||
    Deno.env.get("OPENAI_MODEL") || "gpt-4.1-mini";
  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "authorization": `Bearer ${apiKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.1,
        input: [{
          role: "user",
          content: [{
            type: "input_text",
            text: buildExtractionPrompt(input),
          }],
        }],
      }),
    });

    if (!response.ok) {
      return fallbackSemanticExtraction(input, "failed", model);
    }

    const payload = await response.json();
    const text = extractResponseText(payload);
    return normalizeSemanticExtraction(parseJsonObject(text), input, model);
  } catch {
    return fallbackSemanticExtraction(input, "failed", model);
  }
}

const semanticExtractionSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "title",
    "summary",
    "contentType",
    "language",
    "aliases",
    "entities",
    "chunks",
    "structuredFields",
    "needsClarification",
    "clarificationQuestion",
  ],
  properties: {
    title: { type: "string" },
    summary: { type: "string" },
    contentType: {
      type: "string",
      enum: [
        "recipe",
        "film",
        "place",
        "article",
        "product",
        "video",
        "manual",
        "note",
        "unknown",
      ],
    },
    language: { type: "string" },
    aliases: { type: "array", items: { type: "string" } },
    entities: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["entity", "entityType", "normalizedValue", "metadata"],
        properties: {
          entity: { type: "string" },
          entityType: { type: "string" },
          normalizedValue: { type: "string" },
          metadata: { type: "object", additionalProperties: true },
        },
      },
    },
    chunks: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["chunkType", "content", "metadata"],
        properties: {
          chunkType: { type: "string" },
          content: { type: "string" },
          metadata: { type: "object", additionalProperties: true },
        },
      },
    },
    structuredFields: { type: "object", additionalProperties: true },
    needsClarification: { type: "boolean" },
    clarificationQuestion: { type: "string" },
  },
} as const;

function semanticExtractionModels(): string[] {
  return [
    Deno.env.get("AI_TEXT_EXTRACT_PRIMARY") || "qwen/qwen3.5-flash-02-23",
    Deno.env.get("AI_TEXT_ONLY_FALLBACK") || "deepseek/deepseek-v4-flash",
    Deno.env.get("AI_TEXT_EXTRACT_FALLBACK") || "openai/gpt-5.4-nano",
  ];
}

function buildExtractionPrompt(input: SemanticExtractionInput): string {
  const sourcePayload = input.sourceType === "link"
    ? {
      sourceType: input.sourceType,
      url: input.url,
      fallbackContentType: input.fallbackContentType,
      resolvedLink: {
        platform: input.resolvedLink.platform,
        resolver: input.resolvedLink.resolver,
        extractionStatus: input.resolvedLink.extractionStatus,
        title: input.resolvedLink.title,
        description: input.resolvedLink.description,
        authorName: input.resolvedLink.authorName,
        authorUrl: input.resolvedLink.authorUrl,
        providerName: input.resolvedLink.providerName,
        canonicalUrl: input.resolvedLink.canonicalUrl,
        structuredData: input.resolvedLink.structuredData,
        needsUserContext: input.resolvedLink.needsUserContext,
      },
    }
    : {
      sourceType: input.sourceType,
      fallbackContentType: input.fallbackContentType,
      title: input.title,
      text: input.text,
      userNote: input.userNote,
    };

  return [
    "You extract saved inputs for Dualio, a private personal semantic memory app.",
    "Return JSON only. Do not wrap it in markdown.",
    "Use only the provided data. Do not invent missing facts.",
    "Detect contentType as exactly one of: recipe, film, place, article, product, video, manual, note, unknown.",
    "Write a short user-facing summary in 1-2 sentences explaining what the user likely wanted to remember.",
    "Generate searchable aliases/synonyms useful for cross-lingual retrieval in English, Hebrew, Russian, Italian, French, Spanish, and German when appropriate.",
    "Extract entities such as people, places, brands, ingredients, media titles, organizations, products, and topics.",
    "Create semantic chunks that will later be embedded. Keep chunks concise and meaningful.",
    "For structuredFields, include only fields supported by the detected type and use empty arrays/strings when unavailable.",
    "For recipe links, prefer schema.org Recipe data over generic page metadata. Extract ingredients and steps from structuredData.recipe when present.",
    "Use contentType manual for how-to guides, tutorials, setup instructions, repair guides, checklists, workflows, and step-by-step instructions that are not recipes. This includes Russian instructions such as \u0438\u043d\u0441\u0442\u0440\u0443\u043a\u0446\u0438\u044f, \u0440\u0443\u043a\u043e\u0432\u043e\u0434\u0441\u0442\u0432\u043e, \u043a\u0430\u043a \u0441\u0434\u0435\u043b\u0430\u0442\u044c, and \u043f\u043e\u0448\u0430\u0433\u043e\u0432\u043e.",
    "For manual structuredFields, extract materials/tools/requirements when present and steps as an ordered list. Do not put manuals into article just because they came from a web page.",
    "Supported structuredFields keys: author, authorName, siteName, readMinutes, body, prepTime, cookTime, totalTime, recipeYield, difficulty, ingredients, materials, tools, requirements, steps, year, director, rating, synopsis, cast, address, venueType, hours, notes, price, store, specs, duration.",
    "If the saved input is ambiguous, set needsClarification true and ask exactly one short question.",
    'Schema: {"title":"","summary":"","contentType":"unknown","language":"en","aliases":[],"entities":[{"entity":"","entityType":"","normalizedValue":"","metadata":{}}],"chunks":[{"chunkType":"summary|body|metadata|entity","content":"","metadata":{}}],"structuredFields":{},"needsClarification":false,"clarificationQuestion":""}.',
    `Input: ${JSON.stringify(sourcePayload)}`,
  ].join(" ");
}

function fallbackSemanticExtraction(
  input: SemanticExtractionInput,
  status: Exclude<SemanticExtractionStatus, "complete" | "partial">,
  model?: string,
): SemanticExtraction {
  const recipe = input.sourceType === "link"
    ? input.resolvedLink.structuredData?.recipe
    : undefined;
  const title = input.sourceType === "link"
    ? cleanText(recipe?.name) || cleanText(input.title) ||
      cleanText(input.resolvedLink.title) ||
      hostnameFromUrl(input.url) || "Saved link"
    : cleanText(input.title) || firstTextLine(input.text) || "Saved note";
  const summary = input.sourceType === "link"
    ? cleanText(recipe?.description) || cleanText(input.summary) ||
      cleanText(input.resolvedLink.description) ||
      `Saved link from ${hostnameFromUrl(input.url) || "the web"}.`
    : summarizeText(input.text);
  const structuredFields = input.sourceType === "link"
    ? recipe
      ? {
        authorName: recipe.authorName ?? input.resolvedLink.authorName,
        siteName: input.resolvedLink.providerName,
        prepTime: recipe.prepTime,
        cookTime: recipe.cookTime,
        totalTime: recipe.totalTime,
        recipeYield: recipe.recipeYield,
        ingredients: recipe.ingredients,
        steps: recipe.instructions,
        rating: recipe.ratingValue,
        body: summary,
      }
      : {
        authorName: input.resolvedLink.authorName,
        authorUrl: input.resolvedLink.authorUrl,
        siteName: input.resolvedLink.providerName,
        readMinutes: estimateReadMinutes(summary),
        body: summary,
      }
    : {
      body: input.text,
    };

  return {
    title,
    summary,
    contentType: recipe ? "recipe" : input.fallbackContentType,
    language: "en",
    aliases: buildFallbackAliases(title, summary),
    entities: [],
    chunks: [
      { chunkType: "summary", content: summary },
      ...(recipe?.ingredients.length
        ? [{
          chunkType: "ingredients",
          content: recipe.ingredients.join("\n"),
        }]
        : []),
      ...(recipe?.instructions.length
        ? [{ chunkType: "steps", content: recipe.instructions.join("\n") }]
        : []),
      ...(input.sourceType === "text" && cleanText(input.text)
        ? [{ chunkType: "body", content: cleanText(input.text) }]
        : []),
    ],
    structuredFields,
    needsClarification: false,
    extractionStatus: status,
    model,
  };
}

function normalizeSemanticExtraction(
  value: Record<string, unknown>,
  input: SemanticExtractionInput,
  model: string,
): SemanticExtraction {
  const fallback = fallbackSemanticExtraction(input, "failed", model);
  const title = cleanText(value.title) || fallback.title;
  const summary = cleanText(value.summary) || fallback.summary;
  const contentType = normalizeContentType(
    value.contentType,
    input.fallbackContentType,
  );
  const chunks = toChunkArray(value.chunks);
  chunks.push({ chunkType: "summary", content: summary });
  if (input.sourceType === "text" && cleanText(input.text)) {
    chunks.push({ chunkType: "body", content: cleanText(input.text) });
  }

  return {
    title,
    summary,
    contentType,
    language: cleanText(value.language) || fallback.language,
    aliases: [
      ...new Set(
        [...toStringArray(value.aliases), ...fallback.aliases].map((alias) =>
          alias.toLowerCase()
        ),
      ),
    ].slice(0, 32),
    entities: toEntityArray(value.entities),
    chunks: dedupeChunks(chunks),
    structuredFields: normalizeStructuredFields(value.structuredFields),
    needsClarification: value.needsClarification === true,
    clarificationQuestion: cleanText(value.clarificationQuestion),
    extractionStatus: "complete",
    model,
  };
}

function normalizeContentType(
  value: unknown,
  fallback: SemanticContentType,
): SemanticContentType {
  if (typeof value !== "string") {
    return fallback;
  }
  if (
    [
      "recipe",
      "film",
      "place",
      "article",
      "product",
      "video",
      "manual",
      "note",
      "unknown",
    ].includes(value)
  ) {
    return value as SemanticContentType;
  }
  return fallback;
}

function normalizeStructuredFields(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as Record<string, unknown>;
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map((item) => cleanText(item)).filter(Boolean);
}

function toChunkArray(value: unknown): SemanticChunk[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const chunks: SemanticChunk[] = [];
  for (const item of value) {
    if (!item || typeof item !== "object") {
      continue;
    }
    const row = item as Record<string, unknown>;
    const content = cleanText(row.content);
    if (!content) {
      continue;
    }
    chunks.push({
      chunkType: cleanText(row.chunkType) || "metadata",
      content,
      metadata: normalizeStructuredFields(row.metadata),
    });
  }
  return chunks;
}

function toEntityArray(value: unknown): SemanticEntity[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const entities: SemanticEntity[] = [];
  for (const item of value) {
    if (!item || typeof item !== "object") {
      continue;
    }
    const row = item as Record<string, unknown>;
    const entity = cleanText(row.entity);
    if (!entity) {
      continue;
    }
    entities.push({
      entity,
      entityType: cleanText(row.entityType) || "unknown",
      normalizedValue: cleanText(row.normalizedValue) || entity.toLowerCase(),
      metadata: normalizeStructuredFields(row.metadata),
    });
  }
  return entities.slice(0, 32);
}

function dedupeChunks(chunks: SemanticChunk[]): SemanticChunk[] {
  const seen = new Set<string>();
  return chunks.filter((chunk) => {
    const key = `${chunk.chunkType}:${chunk.content}`;
    if (seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  }).slice(0, 12);
}

function extractResponseText(payload: Record<string, unknown>): string {
  if (typeof payload.output_text === "string") {
    return payload.output_text;
  }
  const output = payload.output;
  if (!Array.isArray(output)) {
    return "";
  }
  const parts: string[] = [];
  for (const item of output) {
    if (!item || typeof item !== "object") {
      continue;
    }
    const content = (item as Record<string, unknown>).content;
    if (!Array.isArray(content)) {
      continue;
    }
    for (const contentItem of content) {
      if (!contentItem || typeof contentItem !== "object") {
        continue;
      }
      const text = (contentItem as Record<string, unknown>).text;
      if (typeof text === "string") {
        parts.push(text);
      }
    }
  }
  return parts.join("\n");
}

function buildFallbackAliases(title: string, summary: string): string[] {
  return [
    ...new Set(
      `${title} ${summary}`.toLowerCase().split(/[\s,.;:!?/|-]+/).filter((
        word,
      ) => word.length > 3),
    ),
  ].slice(0, 16);
}

function summarizeText(text: string): string {
  const cleaned = cleanText(text);
  if (!cleaned) {
    return "Saved note.";
  }
  return cleaned.length > 260 ? `${cleaned.slice(0, 257).trim()}...` : cleaned;
}

function firstTextLine(text: string): string {
  return cleanText(text).split(/[.!?\n]/)[0]?.slice(0, 80).trim() ?? "";
}

function hostnameFromUrl(value: string): string {
  try {
    return new URL(value).hostname;
  } catch {
    return "";
  }
}

function estimateReadMinutes(text: string): number {
  const wordCount = text.split(/\s+/).filter((word) => word.length > 0).length;
  return Math.max(1, Math.ceil(wordCount / 220));
}

function cleanText(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.replace(/\s+/g, " ").trim();
}
