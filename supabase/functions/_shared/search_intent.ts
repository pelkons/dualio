import { callOpenRouterStructuredJson } from "./openrouter.ts";
import type { SemanticContentType } from "./semantic_extraction.ts";

export type SearchFieldScope =
  | "memory"
  | "title"
  | "mentions"
  | "general";

export type SearchDateRange = {
  from?: string;
  to?: string;
  label: string;
};

export type SearchQueryPlan = {
  inferredType: SemanticContentType | null;
  targetTypes: SemanticContentType[];
  excludedTypes: SemanticContentType[];
  concepts: string[];
  intentTerms: string[];
  negativeTerms: string[];
  queryTerms: string[];
  fieldScope: SearchFieldScope;
  strictTypeFilter: boolean;
  dateRange?: SearchDateRange;
  plannerStatus: "ai" | "fallback";
  model?: string;
};

const itemTypes: SemanticContentType[] = [
  "recipe",
  "film",
  "place",
  "article",
  "product",
  "video",
  "manual",
  "note",
  "unknown",
];

const keywordGroups: Array<{
  type: Exclude<SemanticContentType, "unknown">;
  keywords: string[];
}> = [
  {
    type: "recipe",
    keywords: [
      "recipe",
      "cook",
      "ingredient",
      "ingredients",
      "meal",
      "dish",
      "\u05de\u05ea\u05db\u05d5\u05df",
      "\u05de\u05ea\u05db\u05d5\u05e0\u05d9\u05dd",
      "\u0440\u0435\u0446\u0435\u043f\u0442",
      "\u0438\u043d\u0433\u0440\u0435\u0434\u0438\u0435\u043d\u0442",
      "\u0435\u0434\u0430",
      "\u0431\u043b\u044e\u0434\u043e",
    ],
  },
  {
    type: "film",
    keywords: [
      "movie",
      "film",
      "show",
      "watch",
      "director",
      "cast",
      "\u05e1\u05e8\u05d8",
      "\u05e1\u05d3\u05e8\u05d4",
      "\u0444\u0438\u043b\u044c\u043c",
      "\u0441\u0435\u0440\u0438\u0430\u043b",
      "\u043a\u0438\u043d\u043e",
    ],
  },
  {
    type: "place",
    keywords: [
      "place",
      "restaurant",
      "hotel",
      "address",
      "map",
      "near",
      "\u05de\u05e7\u05d5\u05dd",
      "\u05de\u05e1\u05e2\u05d3\u05d4",
      "\u05db\u05ea\u05d5\u05d1\u05ea",
      "\u05de\u05dc\u05d5\u05df",
      "\u043c\u0435\u0441\u0442\u043e",
      "\u0440\u0435\u0441\u0442\u043e\u0440\u0430\u043d",
      "\u0430\u0434\u0440\u0435\u0441",
      "\u043e\u0442\u0435\u043b\u044c",
    ],
  },
  {
    type: "product",
    keywords: [
      "product",
      "price",
      "buy",
      "store",
      "shop",
      "\u05de\u05d5\u05e6\u05e8",
      "\u05de\u05d7\u05d9\u05e8",
      "\u05dc\u05e7\u05e0\u05d5\u05ea",
      "\u05d7\u05e0\u05d5\u05ea",
      "\u0442\u043e\u0432\u0430\u0440",
      "\u0446\u0435\u043d\u0430",
      "\u043a\u0443\u043f\u0438\u0442\u044c",
      "\u043c\u0430\u0433\u0430\u0437\u0438\u043d",
    ],
  },
  {
    type: "video",
    keywords: [
      "video",
      "youtube",
      "tiktok",
      "clip",
      "reel",
      "\u05d5\u05d9\u05d3\u05d0\u05d5",
      "\u05e1\u05e8\u05d8\u05d5\u05df",
      "\u0432\u0438\u0434\u0435\u043e",
      "\u0440\u043e\u043b\u0438\u043a",
      "\u043a\u043b\u0438\u043f",
    ],
  },
  {
    type: "manual",
    keywords: [
      "manual",
      "guide",
      "tutorial",
      "instruction",
      "instructions",
      "how to",
      "step by step",
      "checklist",
      "\u05de\u05d3\u05e8\u05d9\u05da",
      "\u05d4\u05d5\u05e8\u05d0\u05d5\u05ea",
      "\u05e6\u05e2\u05d3\u05d9\u05dd",
      "\u0438\u043d\u0441\u0442\u0440\u0443\u043a\u0446\u0438\u044f",
      "\u0438\u043d\u0441\u0442\u0440\u0443\u043a\u0446\u0438\u0438",
      "\u0440\u0443\u043a\u043e\u0432\u043e\u0434\u0441\u0442\u0432\u043e",
      "\u0433\u0430\u0439\u0434",
      "\u043a\u0430\u043a \u0441\u0434\u0435\u043b\u0430\u0442\u044c",
      "\u043f\u043e\u0448\u0430\u0433\u043e\u0432\u043e",
      "\u0447\u0435\u043a\u043b\u0438\u0441\u0442",
    ],
  },
  {
    type: "note",
    keywords: [
      "note",
      "quote",
      "remember",
      "\u05e4\u05ea\u05e7",
      "\u05e6\u05d9\u05d8\u05d5\u05d8",
      "\u05dc\u05d6\u05db\u05d5\u05e8",
      "\u0437\u0430\u043c\u0435\u0442\u043a\u0430",
      "\u0446\u0438\u0442\u0430\u0442\u0430",
      "\u0437\u0430\u043f\u043e\u043c\u043d\u0438\u0442\u044c",
    ],
  },
];

const queryPlanSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "targetTypes",
    "excludedTypes",
    "concepts",
    "intentTerms",
    "negativeTerms",
    "queryTerms",
    "fieldScope",
    "strictTypeFilter",
    "dateRange",
  ],
  properties: {
    targetTypes: {
      type: "array",
      items: { type: "string", enum: itemTypes },
    },
    excludedTypes: {
      type: "array",
      items: { type: "string", enum: itemTypes },
    },
    concepts: { type: "array", items: { type: "string" } },
    intentTerms: { type: "array", items: { type: "string" } },
    negativeTerms: { type: "array", items: { type: "string" } },
    queryTerms: { type: "array", items: { type: "string" } },
    fieldScope: {
      type: "string",
      enum: ["memory", "title", "mentions", "general"],
    },
    strictTypeFilter: { type: "boolean" },
    dateRange: {
      type: "object",
      additionalProperties: false,
      required: ["from", "to", "label"],
      properties: {
        from: { type: "string" },
        to: { type: "string" },
        label: { type: "string" },
      },
    },
  },
} as const;

export function inferItemTypeFromQuery(
  query: string,
): SemanticContentType | null {
  return planSearchQuery(query).inferredType;
}

export async function planSearchQueryWithAi(
  query: string,
  locale = "en",
  now: Date = new Date(),
): Promise<SearchQueryPlan> {
  const fallback = planSearchQuery(query, now);
  const result = await callOpenRouterStructuredJson({
    models: queryPlannerModels(),
    messages: [{
      role: "user",
      content: buildQueryPlannerPrompt(query, locale, now),
    }],
    schemaName: "dualio_search_query_plan",
    schema: queryPlanSchema,
  });

  if (result.status !== "complete" || !result.json) {
    return fallback;
  }

  return normalizeAiQueryPlan(result.json, fallback, result.model);
}

export function planSearchQuery(
  query: string,
  now: Date = new Date(),
): SearchQueryPlan {
  const normalized = query.toLocaleLowerCase().normalize("NFC");
  const inferredType = inferExplicitType(normalized);
  const targetTypes = inferredType ? [inferredType] : [];
  return {
    inferredType,
    targetTypes,
    excludedTypes: [],
    concepts: [],
    intentTerms: [],
    negativeTerms: [],
    queryTerms: splitQueryTerms(query),
    fieldScope: "general",
    strictTypeFilter: false,
    dateRange: inferSavedDateRange(normalized, now),
    plannerStatus: "fallback",
  };
}

function queryPlannerModels(): string[] {
  return [
    Deno.env.get("AI_QUERY_PLAN_PRIMARY") || "openai/gpt-5.4-nano",
    Deno.env.get("AI_TEXT_ONLY_FALLBACK") || "deepseek/deepseek-v4-flash",
  ];
}

function buildQueryPlannerPrompt(
  query: string,
  locale: string,
  now: Date,
): string {
  return [
    "You plan retrieval for Dualio, a private personal semantic memory app.",
    "Return JSON only.",
    "Interpret the user's query as a memory request, not as plain keyword search.",
    "Identify what kind of saved object the user is probably asking for, what concepts matter, which words are central intent, which words should be treated as title-only or incidental mentions, and whether a saved-at time range is requested.",
    "Use targetTypes only when the user clearly asks for a kind of saved object. Use strictTypeFilter only when other item types should be excluded.",
    "Use fieldScope=memory for meaning/intent/usage-context recall, title when the user says the name/title was related to something, mentions when the user explicitly asks where something was mentioned, and general otherwise.",
    "Use stable English concepts where possible, but preserve useful query terms in the user's language.",
    "Do not invent saved content. Plan retrieval only.",
    "If there is no saved-at time constraint, dateRange must be empty strings with label none.",
    `Current ISO time: ${now.toISOString()}`,
    `User locale: ${locale}`,
    `Query: ${query}`,
  ].join(" ");
}

function normalizeAiQueryPlan(
  value: Record<string, unknown>,
  fallback: SearchQueryPlan,
  model?: string,
): SearchQueryPlan {
  const targetTypes = toItemTypeArray(value.targetTypes);
  const excludedTypes = toItemTypeArray(value.excludedTypes);
  const fieldScope = normalizeFieldScope(value.fieldScope);
  const dateRange = normalizeDateRange(value.dateRange) ?? fallback.dateRange;
  return {
    inferredType: targetTypes[0] ?? fallback.inferredType,
    targetTypes,
    excludedTypes,
    concepts: toStringArray(value.concepts),
    intentTerms: toStringArray(value.intentTerms),
    negativeTerms: toStringArray(value.negativeTerms),
    queryTerms: uniqueTerms([
      ...toStringArray(value.queryTerms),
      ...fallback.queryTerms,
    ]),
    fieldScope,
    strictTypeFilter: value.strictTypeFilter === true,
    dateRange,
    plannerStatus: "ai",
    model,
  };
}

function inferExplicitType(query: string): SemanticContentType | null {
  for (const group of orderedKeywordGroups()) {
    if (group.keywords.some((keyword) => includesKeyword(query, keyword))) {
      return group.type;
    }
  }
  return null;
}

function orderedKeywordGroups(): typeof keywordGroups {
  return keywordGroups.slice().sort((left, right) =>
    itemTypePriority(left.type) - itemTypePriority(right.type)
  );
}

function itemTypePriority(
  type: Exclude<SemanticContentType, "unknown">,
): number {
  if (type === "video") {
    return -2;
  }
  return type === "manual" ? -1 : 0;
}

function includesKeyword(query: string, keyword: string): boolean {
  const normalizedKeyword = keyword.toLocaleLowerCase().normalize("NFC");
  if (/^[a-z0-9]+$/.test(normalizedKeyword)) {
    return new RegExp(
      `(^|[^a-z0-9])${escapeRegExp(normalizedKeyword)}($|[^a-z0-9])`,
    ).test(query);
  }
  return query.includes(normalizedKeyword);
}

function inferSavedDateRange(
  query: string,
  now: Date,
): SearchDateRange | undefined {
  if (
    hasAnyPhrase(query, [
      "year ago",
      "a year ago",
      "last year",
      "\u0433\u043e\u0434 \u043d\u0430\u0437\u0430\u0434",
      "\u043f\u0440\u043e\u0448\u043b\u044b\u0439 \u0433\u043e\u0434",
      "\u05dc\u05e4\u05e0\u05d9 \u05e9\u05e0\u05d4",
      "\u05e9\u05e0\u05d4 \u05e9\u05e2\u05d1\u05e8\u05d4",
    ])
  ) {
    return {
      from: monthsAgo(now, 15).toISOString(),
      to: monthsAgo(now, 9).toISOString(),
      label: "about_one_year_ago",
    };
  }

  if (
    hasAnyPhrase(query, [
      "few months ago",
      "several months ago",
      "a few months ago",
      "\u043d\u0435\u0441\u043a\u043e\u043b\u044c\u043a\u043e \u043c\u0435\u0441\u044f\u0446\u0435\u0432 \u043d\u0430\u0437\u0430\u0434",
      "\u043f\u0430\u0440\u0443 \u043c\u0435\u0441\u044f\u0446\u0435\u0432 \u043d\u0430\u0437\u0430\u0434",
      "\u05dc\u05e4\u05e0\u05d9 \u05db\u05de\u05d4 \u05d7\u05d5\u05d3\u05e9\u05d9\u05dd",
      "\u05db\u05de\u05d4 \u05d7\u05d5\u05d3\u05e9\u05d9\u05dd",
    ])
  ) {
    return {
      from: monthsAgo(now, 6).toISOString(),
      to: monthsAgo(now, 2).toISOString(),
      label: "a_few_months_ago",
    };
  }

  return undefined;
}

function normalizeDateRange(value: unknown): SearchDateRange | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  const row = value as Record<string, unknown>;
  const label = cleanString(row.label);
  if (!label || label === "none") {
    return undefined;
  }
  const from = cleanString(row.from);
  const to = cleanString(row.to);
  return { from: from || undefined, to: to || undefined, label };
}

function toItemTypeArray(value: unknown): SemanticContentType[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item): item is SemanticContentType =>
    typeof item === "string" && itemTypes.includes(item as SemanticContentType)
  );
}

function normalizeFieldScope(value: unknown): SearchFieldScope {
  return value === "memory" || value === "title" || value === "mentions" ||
      value === "general"
    ? value
    : "general";
}

function hasAnyPhrase(query: string, phrases: string[]): boolean {
  return phrases.some((phrase) =>
    query.includes(phrase.toLocaleLowerCase().normalize("NFC"))
  );
}

function splitQueryTerms(query: string): string[] {
  return uniqueTerms(query.toLocaleLowerCase().split(/\s+/).map(cleanString))
    .filter((term) => term.length > 1)
    .slice(0, 16);
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return uniqueTerms(value.map(cleanString).filter(Boolean)).slice(0, 32);
}

function uniqueTerms(values: string[]): string[] {
  return [...new Set(values.map(cleanString).filter(Boolean))];
}

function cleanString(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.replace(/\s+/g, " ").trim();
}

function monthsAgo(now: Date, months: number): Date {
  const value = new Date(now);
  value.setUTCMonth(value.getUTCMonth() - months);
  return value;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
