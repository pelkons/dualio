import {
  type OpenRouterMessage,
  openRouterProviderPreferences,
  parseJsonObject,
} from "./openrouter.ts";
import { normalizeMemoryProfile } from "./memory_profile.ts";
import type { SearchQueryPlan } from "./search_intent.ts";
import type { SemanticContentType } from "./semantic_extraction.ts";

export type SearchRankLocale = "en" | "he" | "ru" | "it" | "fr" | "es" | "de";

export type SearchRankCandidate = {
  id: string;
  title: string;
  type: string;
  language?: string | null;
  searchable_summary?: string | null;
  searchable_aliases?: string[] | null;
  parsed_content?: Record<string, unknown> | null;
  match_reason?: string | null;
  created_at?: string | null;
};

export type RankedSearchItem = {
  itemId: string;
  reason: string;
};

export type RankerFilterChip = {
  type: string;
  count: number;
};

export type SearchRanking = {
  queryLanguage: SearchRankLocale;
  primary: RankedSearchItem[];
  secondary: RankedSearchItem[];
  suggestion: string | null;
  filterChips: RankerFilterChip[];
};

export type RankerUsage = {
  prompt_tokens?: number;
  completion_tokens?: number;
  total_tokens?: number;
};

type RankAndExplainOptions = {
  query: string;
  queryPlan: SearchQueryPlan;
  candidates: SearchRankCandidate[];
  locale: SearchRankLocale;
  timeoutMs?: number;
  callRanker?: RankerCall;
  getEnv?: (name: string) => string | undefined;
};

type RankerCallOptions = {
  models: string[];
  messages: OpenRouterMessage[];
  schemaName: string;
  schema: Record<string, unknown>;
  signal?: AbortSignal;
};

type RankerCallResult = {
  status: "complete" | "disabled" | "failed";
  model?: string;
  json?: Record<string, unknown>;
  usage?: RankerUsage;
  error?: string;
};

type RankerCall = (options: RankerCallOptions) => Promise<RankerCallResult>;

const supportedLocales: SearchRankLocale[] = [
  "en",
  "he",
  "ru",
  "it",
  "fr",
  "es",
  "de",
];

const maxReasonLength = 220;

export async function rankAndExplain(
  options: RankAndExplainOptions,
): Promise<SearchRanking | null> {
  const getEnv = options.getEnv ?? Deno.env.get;
  if (getEnv("SEARCH_RANKER_ENABLED") !== "true") {
    return null;
  }

  const query = cleanString(options.query);
  if (query.length < 3 || options.candidates.length === 0) {
    return null;
  }

  const candidates = options.candidates.slice(0, 20);
  const controller = new AbortController();
  let timeoutId: number | undefined;
  const timeoutMs = options.timeoutMs ?? 1500;
  const callRanker = options.callRanker ?? callOpenRouterRanker;

  const timeout = new Promise<RankerCallResult>((resolve) => {
    timeoutId = setTimeout(() => {
      controller.abort("search_ranker_timeout");
      resolve({ status: "failed", error: "timeout" });
    }, timeoutMs);
  });

  const startedAt = Date.now();
  try {
    const result = await Promise.race([
      callRanker({
        models: searchRankerModels(getEnv),
        messages: buildRankerMessages({
          query,
          queryPlan: options.queryPlan,
          candidates,
          locale: options.locale,
        }),
        schemaName: "dualio_search_ranker",
        schema: rankerOutputSchema,
        signal: controller.signal,
      }),
      timeout,
    ]);

    console.info("search_ranker_openrouter", {
      status: result.status,
      model: result.model,
      duration_ms: Date.now() - startedAt,
      prompt_tokens: result.usage?.prompt_tokens ?? null,
      completion_tokens: result.usage?.completion_tokens ?? null,
      total_tokens: result.usage?.total_tokens ?? null,
      error: result.error,
    });

    if (result.status !== "complete" || !result.json) {
      return null;
    }

    return sanitizeRankingForCandidates(
      validateRankerJson(result.json, options.locale),
      candidates,
    );
  } catch (error) {
    console.info("search_ranker_openrouter", {
      status: "failed",
      duration_ms: Date.now() - startedAt,
      error: error instanceof Error ? error.name : "unknown_error",
    });
    return null;
  } finally {
    if (timeoutId !== undefined) {
      clearTimeout(timeoutId);
    }
  }
}

export function sanitizeRankingForCandidates(
  ranking: SearchRanking | null,
  candidates: SearchRankCandidate[],
): SearchRanking | null {
  if (!ranking) {
    return null;
  }

  const byId = new Map(
    candidates.map((candidate) => [candidate.id, candidate]),
  );
  const used = new Set<string>();
  const primary = sanitizeRankedItems(ranking.primary, byId, used);
  const secondary = sanitizeRankedItems(ranking.secondary, byId, used);

  if (primary.length === 0 && secondary.length === 0) {
    return null;
  }

  return {
    queryLanguage: normalizeLocale(ranking.queryLanguage),
    primary,
    secondary,
    suggestion: cleanNullableString(ranking.suggestion),
    filterChips: sanitizeFilterChips(ranking.filterChips, [
      ...primary,
      ...secondary,
    ], byId),
  };
}

export function validateRankerJson(
  value: Record<string, unknown>,
  fallbackLocale: SearchRankLocale,
): SearchRanking | null {
  const primary = parseRankedArray(value.primary);
  const secondary = parseRankedArray(value.secondary);
  return {
    queryLanguage: normalizeLocale(value.queryLanguage, fallbackLocale),
    primary,
    secondary,
    suggestion: cleanNullableString(value.suggestion),
    filterChips: parseFilterChips(value.filter_chips ?? value.filterChips),
  };
}

function sanitizeRankedItems(
  items: RankedSearchItem[],
  byId: Map<string, SearchRankCandidate>,
  used: Set<string>,
): RankedSearchItem[] {
  const output: RankedSearchItem[] = [];
  for (const item of items) {
    if (!byId.has(item.itemId) || used.has(item.itemId)) {
      continue;
    }
    const reason = cleanReason(item.reason);
    if (!reason) {
      continue;
    }
    used.add(item.itemId);
    output.push({ itemId: item.itemId, reason });
  }
  return output;
}

function sanitizeFilterChips(
  chips: RankerFilterChip[],
  rankedItems: RankedSearchItem[],
  byId: Map<string, SearchRankCandidate>,
): RankerFilterChip[] {
  const rankedTypes = new Map<string, number>();
  for (const item of rankedItems) {
    const type = cleanString(byId.get(item.itemId)?.type);
    if (!type) {
      continue;
    }
    rankedTypes.set(type, (rankedTypes.get(type) ?? 0) + 1);
  }

  const sanitized: RankerFilterChip[] = [];
  const used = new Set<string>();
  for (const chip of chips) {
    const type = cleanString(chip.type);
    if (!type || used.has(type) || !rankedTypes.has(type)) {
      continue;
    }
    const maxCount = rankedTypes.get(type) ?? 0;
    const count = Math.max(1, Math.min(Math.trunc(chip.count), maxCount));
    sanitized.push({ type, count });
    used.add(type);
  }

  if (sanitized.length > 0) {
    return sanitized.slice(0, 8);
  }

  return [...rankedTypes.entries()]
    .map(([type, count]) => ({ type, count }))
    .slice(0, 8);
}

function buildRankerMessages(input: {
  query: string;
  queryPlan: SearchQueryPlan;
  candidates: SearchRankCandidate[];
  locale: SearchRankLocale;
}): OpenRouterMessage[] {
  return [
    {
      role: "system",
      content: [
        "You are the final search ranker for Dualio, a private personal semantic memory app.",
        "You do not retrieve data. You only reorder and explain the candidate items provided.",
        "Use only itemIds from the candidate list. Never invent ids or saved content.",
        "Separate high-confidence matches into primary and weaker/ambiguous/incidental matches into secondary.",
        "Reasons must be short, user-facing, and written in the queryLanguage.",
        "If a word appears only incidentally or only in a title, explain that distinction.",
        "Return JSON only.",
      ].join(" "),
    },
    {
      role: "user",
      content: JSON.stringify({
        query: input.query,
        locale: input.locale,
        queryPlan: summarizeQueryPlan(input.queryPlan),
        candidates: input.candidates.map(toPromptCandidate),
      }),
    },
  ];
}

function summarizeQueryPlan(queryPlan: SearchQueryPlan) {
  return {
    inferredType: queryPlan.inferredType,
    targetTypes: queryPlan.targetTypes,
    excludedTypes: queryPlan.excludedTypes,
    concepts: queryPlan.concepts,
    intentTerms: queryPlan.intentTerms,
    negativeTerms: queryPlan.negativeTerms,
    queryTerms: queryPlan.queryTerms,
    fieldScope: queryPlan.fieldScope,
    strictTypeFilter: queryPlan.strictTypeFilter,
    dateRange: queryPlan.dateRange,
    plannerStatus: queryPlan.plannerStatus,
  };
}

function toPromptCandidate(candidate: SearchRankCandidate) {
  const itemType = normalizeItemType(candidate.type);
  const profile = normalizeMemoryProfile(
    candidate.parsed_content?.memoryProfile,
    itemType,
  );
  return {
    itemId: candidate.id,
    title: trimForPrompt(candidate.title, 180),
    type: candidate.type,
    language: candidate.language,
    summary: trimForPrompt(candidate.searchable_summary ?? "", 280),
    aliases: (candidate.searchable_aliases ?? []).slice(0, 12),
    technicalReasons: candidate.match_reason,
    memoryProfile: {
      domain: profile.domain,
      objectType: profile.objectType,
      canonicalConcepts: profile.canonicalConcepts.slice(0, 12),
      primaryConcepts: profile.primaryConcepts.slice(0, 12),
      searchIntents: profile.searchIntents.slice(0, 12),
      usageContexts: profile.usageContexts.slice(0, 12),
      facets: summarizeFacets(profile.facets),
      possibleRecallPhrases: profile.possibleRecallPhrases.slice(0, 12),
      incidentalMentions: profile.incidentalMentions.slice(0, 8),
      negativeSignals: profile.negativeSignals.slice(0, 8),
      confidence: profile.confidence,
    },
  };
}

function summarizeFacets(
  facets: Record<string, string[]>,
): Record<string, string[]> {
  const output: Record<string, string[]> = {};
  for (const [key, values] of Object.entries(facets).slice(0, 10)) {
    output[key] = values.slice(0, 8);
  }
  return output;
}

function normalizeItemType(value: string): SemanticContentType {
  return value === "recipe" || value === "film" || value === "place" ||
      value === "article" || value === "product" || value === "video" ||
      value === "manual" || value === "note" || value === "unknown"
    ? value
    : "unknown";
}

const rankerOutputSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "queryLanguage",
    "primary",
    "secondary",
    "suggestion",
    "filter_chips",
  ],
  properties: {
    queryLanguage: {
      type: "string",
      enum: supportedLocales,
    },
    primary: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["itemId", "reason"],
        properties: {
          itemId: { type: "string" },
          reason: { type: "string" },
        },
      },
    },
    secondary: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["itemId", "reason"],
        properties: {
          itemId: { type: "string" },
          reason: { type: "string" },
        },
      },
    },
    suggestion: {
      anyOf: [{ type: "string" }, { type: "null" }],
    },
    filter_chips: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["type", "count"],
        properties: {
          type: { type: "string" },
          count: { type: "integer" },
        },
      },
    },
  },
} as const;

async function callOpenRouterRanker(
  options: RankerCallOptions,
): Promise<RankerCallResult> {
  const apiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) {
    return { status: "disabled", error: "openrouter_api_key_missing" };
  }

  const models = options.models.map((model) => model.trim()).filter(Boolean);
  if (models.length === 0) {
    return { status: "disabled", error: "openrouter_model_missing" };
  }

  let lastError = "unknown_error";
  for (const model of models) {
    try {
      const response = await fetch(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          method: "POST",
          headers: {
            "authorization": `Bearer ${apiKey}`,
            "content-type": "application/json",
          },
          signal: options.signal,
          body: JSON.stringify({
            model,
            messages: options.messages,
            response_format: {
              type: "json_schema",
              json_schema: {
                name: options.schemaName,
                strict: true,
                schema: options.schema,
              },
            },
            provider: openRouterProviderPreferences(),
            stream: false,
          }),
        },
      );

      if (!response.ok) {
        lastError = `http_${response.status}`;
        continue;
      }

      const payload = await response.json();
      const text = extractOpenRouterContent(payload);
      const json = parseJsonObject(text);
      if (Object.keys(json).length === 0) {
        lastError = "invalid_json_response";
        continue;
      }

      return {
        status: "complete",
        model,
        json,
        usage: normalizeUsage(payload.usage),
      };
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") {
        return { status: "failed", model, error: "timeout" };
      }
      lastError = error instanceof Error ? error.name : "unknown_error";
    }
  }

  return { status: "failed", model: models[0], error: lastError };
}

function extractOpenRouterContent(payload: Record<string, unknown>): string {
  const choices = payload.choices;
  if (!Array.isArray(choices) || choices.length === 0) {
    return "";
  }
  const first = choices[0];
  if (!first || typeof first !== "object") {
    return "";
  }
  const message = (first as Record<string, unknown>).message;
  if (!message || typeof message !== "object") {
    return "";
  }
  const content = (message as Record<string, unknown>).content;
  if (typeof content === "string") {
    return content;
  }
  if (!Array.isArray(content)) {
    return "";
  }
  return content.map((part) => {
    if (!part || typeof part !== "object") {
      return "";
    }
    const text = (part as Record<string, unknown>).text;
    return typeof text === "string" ? text : "";
  }).filter(Boolean).join("\n");
}

function normalizeUsage(value: unknown): RankerUsage | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  const row = value as Record<string, unknown>;
  return {
    prompt_tokens: numberField(row.prompt_tokens),
    completion_tokens: numberField(row.completion_tokens),
    total_tokens: numberField(row.total_tokens),
  };
}

function numberField(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.trunc(value)
    : undefined;
}

function searchRankerModels(
  getEnv: (name: string) => string | undefined,
): string[] {
  return [
    getEnv("AI_SEARCH_RANKER_PRIMARY") || getEnv("AI_TEXT_ONLY_PRIMARY") ||
    "openai/gpt-5.4-nano",
    getEnv("AI_SEARCH_RANKER_FALLBACK") || getEnv("AI_TEXT_ONLY_FALLBACK") ||
    "deepseek/deepseek-v4-flash",
  ].filter((model, index, models) => model && models.indexOf(model) === index);
}

function parseRankedArray(value: unknown): RankedSearchItem[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.flatMap((entry) => {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) {
      return [];
    }
    const row = entry as Record<string, unknown>;
    const itemId = cleanString(row.itemId);
    const reason = cleanReason(row.reason);
    return itemId && reason ? [{ itemId, reason }] : [];
  });
}

function parseFilterChips(value: unknown): RankerFilterChip[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.flatMap((entry) => {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) {
      return [];
    }
    const row = entry as Record<string, unknown>;
    const type = cleanString(row.type);
    const count = row.count;
    if (!type || typeof count !== "number" || !Number.isFinite(count)) {
      return [];
    }
    return [{ type, count: Math.max(1, Math.trunc(count)) }];
  });
}

function normalizeLocale(
  value: unknown,
  fallback: SearchRankLocale = "en",
): SearchRankLocale {
  return typeof value === "string" &&
      supportedLocales.includes(value as SearchRankLocale)
    ? value as SearchRankLocale
    : fallback;
}

function cleanNullableString(value: unknown): string | null {
  const cleaned = cleanString(value);
  return cleaned || null;
}

function cleanReason(value: unknown): string {
  return trimForPrompt(cleanString(value), maxReasonLength);
}

function cleanString(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.replace(/\s+/g, " ").trim();
}

function trimForPrompt(value: string, maxLength: number): string {
  const cleaned = cleanString(value);
  if (cleaned.length <= maxLength) {
    return cleaned;
  }
  return `${cleaned.slice(0, maxLength - 1).trim()}…`;
}
