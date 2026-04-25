import type {
  SemanticContentType,
  SemanticEntity,
} from "./semantic_extraction.ts";

export type MemoryProfile = {
  domain: string;
  objectType: string;
  canonicalConcepts: string[];
  primaryConcepts: string[];
  searchIntents: string[];
  usageContexts: string[];
  facets: Record<string, string[]>;
  incidentalMentions: string[];
  possibleRecallPhrases: string[];
  negativeSignals: string[];
  confidence: number;
};

export type MemoryProfileInput = {
  contentType: SemanticContentType;
  title: string;
  summary: string;
  language?: string;
  aliases?: string[];
  ingredients?: string[];
  materials?: string[];
  steps?: string[];
  existing?: unknown;
};

const domainByType: Record<SemanticContentType, string> = {
  recipe: "food",
  film: "entertainment",
  place: "place",
  article: "article",
  product: "shopping",
  video: "media",
  manual: "knowledge",
  note: "personal",
  unknown: "unknown",
};

export function emptyMemoryProfile(
  contentType: SemanticContentType = "unknown",
): MemoryProfile {
  return {
    domain: domainByType[contentType] ?? "unknown",
    objectType: contentType === "unknown" ? "" : contentType,
    canonicalConcepts: contentType === "unknown" ? [] : [contentType],
    primaryConcepts: [],
    searchIntents: [],
    usageContexts: [],
    facets: {},
    incidentalMentions: [],
    possibleRecallPhrases: [],
    negativeSignals: [],
    confidence: 0.3,
  };
}

export function normalizeMemoryProfile(
  value: unknown,
  contentType: SemanticContentType = "unknown",
): MemoryProfile {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return emptyMemoryProfile(contentType);
  }

  const row = value as Record<string, unknown>;
  return {
    domain: cleanToken(row.domain) || domainByType[contentType] || "unknown",
    objectType: cleanToken(row.objectType),
    canonicalConcepts: normalizeTermArray(row.canonicalConcepts),
    primaryConcepts: normalizeTermArray(row.primaryConcepts),
    searchIntents: normalizeTermArray(row.searchIntents),
    usageContexts: normalizeTermArray(row.usageContexts),
    facets: normalizeFacetMap(row.facets),
    incidentalMentions: normalizeTermArray(row.incidentalMentions),
    possibleRecallPhrases: normalizeTermArray(row.possibleRecallPhrases),
    negativeSignals: normalizeTermArray(row.negativeSignals),
    confidence: normalizeConfidence(row.confidence),
  };
}

export function enrichMemoryProfileForContent(
  input: MemoryProfileInput,
): MemoryProfile {
  const profile = normalizeMemoryProfile(input.existing, input.contentType);
  profile.domain = profile.domain || domainByType[input.contentType] ||
    "unknown";
  profile.objectType = profile.objectType || input.contentType;
  addTerms(profile.canonicalConcepts, [input.contentType, profile.domain]);

  profile.canonicalConcepts = uniqueTerms(profile.canonicalConcepts).slice(
    0,
    24,
  );
  profile.primaryConcepts = uniqueTerms(profile.primaryConcepts).slice(0, 24);
  profile.searchIntents = uniqueTerms(profile.searchIntents).slice(0, 32);
  profile.usageContexts = uniqueTerms(profile.usageContexts).slice(0, 32);
  profile.incidentalMentions = uniqueTerms(profile.incidentalMentions).slice(
    0,
    24,
  );
  profile.possibleRecallPhrases = uniqueTerms(profile.possibleRecallPhrases)
    .slice(0, 32);
  profile.negativeSignals = uniqueTerms(profile.negativeSignals).slice(0, 24);

  return profile;
}

export function memoryProfileSearchTerms(profile: MemoryProfile): string[] {
  const facetValues = Object.values(profile.facets).flat();
  return uniqueTerms([
    profile.domain,
    profile.objectType,
    ...profile.canonicalConcepts,
    ...profile.primaryConcepts,
    ...profile.searchIntents,
    ...profile.usageContexts,
    ...profile.possibleRecallPhrases,
    ...facetValues,
  ]).filter((term) => term !== "unknown");
}

export function memoryProfileChunkContent(profile: MemoryProfile): string {
  const facets = Object.entries(profile.facets)
    .flatMap(([key, values]) => values.map((value) => `${key}: ${value}`));
  return [
    `domain: ${profile.domain}`,
    `object type: ${profile.objectType}`,
    `canonical concepts: ${profile.canonicalConcepts.join(", ")}`,
    `primary concepts: ${profile.primaryConcepts.join(", ")}`,
    `search intents: ${profile.searchIntents.join(", ")}`,
    `usage contexts: ${profile.usageContexts.join(", ")}`,
    `possible recall phrases: ${profile.possibleRecallPhrases.join(", ")}`,
    `facets: ${facets.join(", ")}`,
  ].filter((line) => !line.endsWith(": ") && !line.endsWith(": "))
    .join("\n");
}

export function memoryProfileEntities(
  profile: MemoryProfile,
): SemanticEntity[] {
  const entities: SemanticEntity[] = [];
  for (const value of profile.primaryConcepts) {
    entities.push(memoryEntity(value, "primary_concept"));
  }
  for (const value of profile.searchIntents) {
    entities.push(memoryEntity(value, "search_intent"));
  }
  for (const value of profile.usageContexts) {
    entities.push(memoryEntity(value, "usage_context"));
  }
  for (const [facet, values] of Object.entries(profile.facets)) {
    for (const value of values) {
      entities.push({
        ...memoryEntity(value, "facet"),
        metadata: { role: "strong_memory_profile", facet },
      });
    }
  }
  return entities.slice(0, 40);
}

function memoryEntity(value: string, entityType: string): SemanticEntity {
  return {
    entity: value,
    entityType,
    normalizedValue: value.toLocaleLowerCase(),
    metadata: { role: "strong_memory_profile" },
  };
}

function normalizeFacetMap(value: unknown): Record<string, string[]> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  const facets: Record<string, string[]> = {};
  for (const [key, rawValues] of Object.entries(value)) {
    const facetKey = cleanToken(key);
    const values = normalizeTermArray(rawValues);
    if (facetKey && values.length > 0) {
      facets[facetKey] = values;
    }
  }
  return facets;
}

function normalizeTermArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return uniqueTerms(value.map((item) => cleanToken(item)).filter(Boolean));
}

function addTerms(target: string[], values: string[]) {
  target.push(...values.map((value) => cleanToken(value)).filter(Boolean));
}

function uniqueTerms(values: string[]): string[] {
  return [
    ...new Set(values.map((value) => cleanToken(value)).filter(Boolean)),
  ];
}

function normalizeConfidence(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return 0.7;
  }
  return Math.max(0, Math.min(1, value));
}

function cleanToken(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.replace(/\s+/g, " ").trim();
}
