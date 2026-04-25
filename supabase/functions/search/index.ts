import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  embeddingToPgVector,
  generateEmbeddings,
} from "../_shared/embeddings.ts";
import {
  planSearchQueryWithAi,
  type SearchQueryPlan,
} from "../_shared/search_intent.ts";
import type { SemanticContentType } from "../_shared/semantic_extraction.ts";
import {
  memoryProfileSearchTerms,
  normalizeMemoryProfile,
} from "../_shared/memory_profile.ts";

type SearchRequest = {
  query: string;
  locale?: "en" | "he" | "ru" | "it" | "fr" | "es" | "de";
  limit?: number;
  debug?: boolean;
};

export type MatchRow = {
  item_id: string;
  chunk_id: string | null;
  score: number;
  match_reason: string;
};

type ItemRow = {
  id: string;
  title: string;
  type: string;
  searchable_summary?: string;
  searchable_aliases?: string[];
  parsed_content?: Record<string, unknown>;
  created_at?: string;
};

type CombinedMatch = {
  itemId: string;
  score: number;
  reasons: Set<string>;
};

type SearchExecutionResult = {
  strategy: string;
  fallbackReason?: string;
  results: Array<Record<string, unknown>>;
};

type RowsResult = {
  rows: MatchRow[];
  errorCode?: string;
  typeFilterRelaxed?: boolean;
};

type RankedSignal = {
  name: string;
  weight: number;
  rows: MatchRow[];
};

const itemSelect = [
  "id",
  "user_id",
  "type",
  "source_url",
  "source_type",
  "raw_content",
  "parsed_content",
  "title",
  "thumbnail_url",
  "language",
  "searchable_summary",
  "searchable_aliases",
  "processing_status",
  "clarification_question",
  "created_at",
  "updated_at",
].join(",");

if (import.meta.main) {
  Deno.serve(handleSearchRequest);
}

export async function handleSearchRequest(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  const body = (await request.json()) as SearchRequest;
  const query = body.query?.trim() ?? "";
  if (!query) {
    return Response.json({ error: "query is required" }, { status: 400 });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseAnonKey) {
    return Response.json({ error: "supabase_env_missing" }, { status: 500 });
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser();
  const user = userData?.user;
  if (userError || !user) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const limit = clampLimit(body.limit);
  const locale = normalizeLocale(body.locale);
  const queryPlan = await planSearchQueryWithAi(query, locale);
  const inferred = queryPlan.inferredType;
  const embedding = await generateEmbeddings([query]);
  const searchResult = embedding.status === "complete" && embedding.vectors[0]
    ? await searchWithRpc(
      supabase,
      query,
      embeddingToPgVector(embedding.vectors[0]),
      queryPlan,
      limit,
    )
    : await fallbackLexicalSearch(supabase, query, queryPlan, limit);

  await supabase.from("search_events").insert({
    user_id: user.id,
    query,
    locale,
    inferred_type: inferred,
    result_count: searchResult.results.length,
  });

  return Response.json({
    query,
    locale,
    inferred_type: inferred,
    limit,
    embedding_status: embedding.status,
    embedding_model: embedding.model,
    strategy: searchResult.strategy,
    results: searchResult.results,
    debug: body.debug === true
      ? {
        embedding_error: embedding.error,
        fallback_reason: searchResult.fallbackReason,
        query_plan: queryPlan,
      }
      : undefined,
  });
}

export async function searchWithRpc(
  supabase: any,
  query: string,
  queryEmbedding: string,
  queryPlan: SearchQueryPlan,
  limit: number,
): Promise<SearchExecutionResult> {
  const weights = weightsForQuery(query);
  const inferred = queryPlan.inferredType;
  const allowTypeRelaxation = !queryPlan.strictTypeFilter;
  const semantic = await fetchRowsWithTypeRelaxation(
    (type) => fetchSemanticRows(supabase, query, queryEmbedding, type, limit),
    inferred,
    "type_filter_relaxed",
    allowTypeRelaxation,
  );
  const trigram = await fetchRowsWithTypeRelaxation(
    (type) => fetchTrigramRows(supabase, query, type, limit),
    inferred,
    "trigram_type_filter_relaxed",
    allowTypeRelaxation,
  );
  const memory = await fetchMemoryPlanRows(
    supabase,
    query,
    queryPlan,
    limit,
  );

  if (
    semantic.errorCode && semantic.rows.length === 0 &&
    trigram.rows.length === 0 && memory.rows.length === 0
  ) {
    return await fallbackLexicalSearch(
      supabase,
      query,
      queryPlan,
      limit,
      semantic.errorCode,
    );
  }

  const signals: RankedSignal[] = [];
  if (semantic.rows.length > 0) {
    signals.push({
      name: "hybrid_rpc",
      weight: weights.semantic,
      rows: semantic.rows,
    });
  }
  if (trigram.rows.length > 0) {
    signals.push({
      name: "trigram_rpc",
      weight: weights.trigram,
      rows: trigram.rows,
    });
  }
  if (memory.rows.length > 0) {
    signals.push({
      name: "memory_plan",
      weight: weights.memory,
      rows: memory.rows,
    });
  }

  const combined = fuseRankedSignals(signals, limit);
  if (combined.length === 0) {
    return {
      strategy: strategyForSignals(signals),
      fallbackReason: combineFallbackReasons(semantic, trigram),
      results: [],
    };
  }

  const items = await fetchItemsByIds(
    supabase,
    combined.map((match) => match.itemId),
  );
  const byId = new Map(items.map((item) => [item.id, item]));
  return {
    strategy: strategyForSignals(signals),
    fallbackReason: combineFallbackReasons(semantic, trigram),
    results: combined.flatMap((match) => {
      const item = byId.get(match.itemId);
      if (!item) {
        return [];
      }
      return [{
        item,
        score: match.score,
        match_reason: [...match.reasons].join(", "),
      }];
    }),
  };
}

async function fallbackLexicalSearch(
  supabase: any,
  query: string,
  queryPlan: SearchQueryPlan,
  limit: number,
  fallbackReason?: string,
): Promise<SearchExecutionResult> {
  const inferred = queryPlan.inferredType;
  const allowTypeRelaxation = !queryPlan.strictTypeFilter;
  let candidateResult = await fetchLexicalCandidates(supabase, inferred);
  if (candidateResult.errorCode) {
    return {
      strategy: "lexical_fallback",
      fallbackReason: candidateResult.errorCode ?? fallbackReason,
      results: [],
    };
  }

  let lexicalRows = lexicalRowsFromItems(candidateResult.items, query);
  let lexicalRelaxed = false;
  if (lexicalRows.length === 0 && inferred && allowTypeRelaxation) {
    candidateResult = await fetchLexicalCandidates(supabase, null);
    lexicalRows = appendReasonToRows(
      lexicalRowsFromItems(candidateResult.items, query),
      "type_filter_relaxed",
    );
    lexicalRelaxed = lexicalRows.length > 0;
  }

  const trigram = await fetchRowsWithTypeRelaxation(
    (type) => fetchTrigramRows(supabase, query, type, limit),
    inferred,
    "trigram_type_filter_relaxed",
    allowTypeRelaxation,
  );
  const memory = await fetchMemoryPlanRows(
    supabase,
    query,
    queryPlan,
    limit,
  );
  const weights = weightsForQuery(query);
  const signals: RankedSignal[] = [];
  if (lexicalRows.length > 0) {
    signals.push({
      name: "lexical_fallback",
      weight: weights.lexical,
      rows: lexicalRows,
    });
  }
  if (trigram.rows.length > 0) {
    signals.push({
      name: "trigram_rpc",
      weight: weights.trigram,
      rows: trigram.rows,
    });
  }
  if (memory.rows.length > 0) {
    signals.push({
      name: "memory_plan",
      weight: weights.memory,
      rows: memory.rows,
    });
  }

  const combined = fuseRankedSignals(signals, limit);
  if (combined.length === 0) {
    return {
      strategy: strategyForSignals(signals, "lexical_fallback"),
      fallbackReason: combineFallbackReasons(
        { rows: [], errorCode: fallbackReason },
        trigram,
        lexicalRelaxed ? "type_filter_relaxed" : undefined,
      ),
      results: [],
    };
  }

  const items = await fetchItemsByIds(
    supabase,
    combined.map((match) => match.itemId),
  );
  const byId = new Map(items.map((item) => [item.id, item]));
  return {
    strategy: strategyForSignals(signals, "lexical_fallback"),
    fallbackReason: combineFallbackReasons(
      { rows: [], errorCode: fallbackReason },
      trigram,
      lexicalRelaxed ? "type_filter_relaxed" : undefined,
    ),
    results: combined.flatMap((match) => {
      const item = byId.get(match.itemId);
      if (!item) {
        return [];
      }
      return [{
        item,
        score: match.score,
        match_reason: [...match.reasons].join(", "),
      }];
    }),
  };
}

async function fetchSemanticRows(
  supabase: any,
  query: string,
  queryEmbedding: string,
  inferred: SemanticContentType | null,
  limit: number,
): Promise<RowsResult> {
  const { data, error } = await supabase.rpc("match_semantic_items", {
    query_embedding: queryEmbedding,
    query_text: query,
    inferred,
    match_count: limit,
  });

  if (error || !Array.isArray(data)) {
    return { rows: [], errorCode: error?.code ?? "semantic_rpc_failed" };
  }

  return { rows: filterWeakSemanticRows(data as MatchRow[], query) };
}

async function fetchTrigramRows(
  supabase: any,
  query: string,
  inferred: SemanticContentType | null,
  limit: number,
): Promise<RowsResult> {
  const { data, error } = await supabase.rpc("match_items_trgm", {
    query_text: query,
    inferred,
    match_count: limit,
    similarity_threshold: trigramThresholdFor(query),
  });

  if (error || !Array.isArray(data)) {
    return { rows: [], errorCode: error?.code ?? "trigram_rpc_failed" };
  }

  return { rows: filterWeakTrigramRows(data as MatchRow[], query) };
}

async function fetchRowsWithTypeRelaxation(
  fetcher: (inferred: SemanticContentType | null) => Promise<RowsResult>,
  inferred: SemanticContentType | null,
  relaxedReason: string,
  allowRelaxation = true,
): Promise<RowsResult> {
  const constrained = await fetcher(inferred);
  if (
    constrained.rows.length > 0 || inferred === null || constrained.errorCode ||
    !allowRelaxation
  ) {
    return constrained;
  }

  const relaxed = await fetcher(null);
  if (relaxed.rows.length === 0) {
    return {
      rows: [],
      errorCode: constrained.errorCode ?? relaxed.errorCode,
    };
  }

  return {
    rows: appendReasonToRows(relaxed.rows, relaxedReason),
    errorCode: constrained.errorCode ?? relaxed.errorCode,
    typeFilterRelaxed: true,
  };
}

async function fetchMemoryPlanRows(
  supabase: any,
  query: string,
  queryPlan: SearchQueryPlan,
  limit: number,
): Promise<RowsResult> {
  if (!shouldRunMemoryPlan(queryPlan)) {
    return { rows: [] };
  }

  const { data, error } = await supabase
    .from("items")
    .select(itemSelect)
    .order("created_at", { ascending: false })
    .limit(Math.max(limit * 12, 120));

  if (error || !Array.isArray(data)) {
    return { rows: [], errorCode: error?.code ?? "memory_plan_fetch_failed" };
  }

  return {
    rows: memoryRowsFromItems(data as ItemRow[], query, queryPlan).slice(
      0,
      limit,
    ),
  };
}

async function fetchLexicalCandidates(
  supabase: any,
  inferred: SemanticContentType | null,
): Promise<{ items: ItemRow[]; errorCode?: string }> {
  let request = supabase
    .from("items")
    .select(itemSelect)
    .order("created_at", { ascending: false })
    .limit(100);

  if (inferred) {
    request = request.eq("type", inferred);
  }

  const { data, error } = await request;
  if (error || !Array.isArray(data)) {
    return { items: [], errorCode: error?.code ?? "lexical_fetch_failed" };
  }

  return { items: data as ItemRow[] };
}

function lexicalRowsFromItems(items: ItemRow[], query: string): MatchRow[] {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  return items
    .map((item) => ({ item, ...scoreItem(item, terms) }))
    .filter((entry) => entry.score > 0)
    .sort((left, right) => right.score - left.score)
    .map((entry) => ({
      item_id: entry.item.id,
      chunk_id: null,
      score: entry.score / 100,
      match_reason: entry.reasons.join(", "),
    }));
}

function memoryRowsFromItems(
  items: ItemRow[],
  query: string,
  queryPlan: SearchQueryPlan,
): MatchRow[] {
  return items
    .map((item) => scoreMemoryPlanItem(item, query, queryPlan))
    .filter((row): row is MatchRow => row !== null)
    .sort((left, right) => right.score - left.score);
}

function scoreMemoryPlanItem(
  item: ItemRow,
  query: string,
  queryPlan: SearchQueryPlan,
): MatchRow | null {
  const itemType = normalizeItemType(item.type);
  if (
    queryPlan.strictTypeFilter &&
    queryPlan.targetTypes.length > 0 &&
    !queryPlan.targetTypes.includes(itemType)
  ) {
    return null;
  }

  const profile = normalizeMemoryProfile(
    item.parsed_content?.memoryProfile,
    itemType,
  );
  const profileTerms = memoryProfileSearchTerms(profile).map(normalizeTerm);
  const aliases = Array.isArray(item.searchable_aliases)
    ? item.searchable_aliases.map(normalizeTerm)
    : [];
  const titleTerms = [item.title, ...aliases].map(normalizeTerm);
  const itemText = normalizeTerm([
    item.title,
    item.searchable_summary ?? "",
    ...aliases,
  ].join(" "));
  const queryTerms = [
    ...queryPlan.concepts,
    ...queryPlan.intentTerms,
    ...queryPlan.queryTerms,
    ...query.split(/\s+/),
  ].map(normalizeTerm).filter(Boolean);
  const negativeTerms = queryPlan.negativeTerms.map(normalizeTerm).filter(
    Boolean,
  );

  let score = 0;
  const reasons = new Set<string>();

  if (queryPlan.targetTypes.includes(itemType)) {
    score += 0.42;
    reasons.add("planned_type");
  }

  if (queryTerms.length > 0 && intersectsTerms(profileTerms, queryTerms)) {
    score += queryPlan.fieldScope === "mentions" ? 0.35 : 0.9;
    reasons.add("memory_profile");
  }

  if (queryTerms.length > 0 && intersectsTerms(aliases, queryTerms)) {
    score += 0.55;
    reasons.add("alias");
  }

  if (
    queryPlan.fieldScope === "title" &&
    queryTerms.length > 0 &&
    intersectsTerms(titleTerms, queryTerms)
  ) {
    score += 0.7;
    reasons.add("title_scope");
  }

  if (
    queryPlan.fieldScope === "mentions" &&
    queryTerms.length > 0 &&
    queryTerms.some((term) => itemText.includes(term))
  ) {
    score += 0.32;
    reasons.add("explicit_mention_scope");
  }

  if (
    negativeTerms.length > 0 && intersectsTerms(profileTerms, negativeTerms)
  ) {
    score *= 0.4;
    reasons.add("negative_memory_signal");
  }

  const timeScore = savedDateScore(item.created_at, queryPlan);
  if (timeScore > 0) {
    score += timeScore;
    reasons.add("saved_time_match");
  } else if (queryPlan.dateRange) {
    score *= 0.82;
  }

  if (score < 0.55 || reasons.size === 0) {
    return null;
  }

  return {
    item_id: item.id,
    chunk_id: null,
    score: Math.min(0.99, score),
    match_reason: [...reasons].join(", "),
  };
}

async function fetchItemsByIds(
  supabase: any,
  ids: string[],
): Promise<ItemRow[]> {
  if (ids.length === 0) {
    return [];
  }

  const { data } = await supabase.from("items").select(itemSelect).in(
    "id",
    ids,
  );
  if (!Array.isArray(data)) {
    return [];
  }
  const byId = new Map((data as ItemRow[]).map((item) => [item.id, item]));
  return ids.flatMap((id) => {
    const item = byId.get(id);
    return item ? [item] : [];
  });
}

export function fuseRankedSignals(
  signals: RankedSignal[],
  limit: number,
): CombinedMatch[] {
  const k = 60;
  const matches = new Map<string, CombinedMatch>();
  for (const signal of signals) {
    const seenInSignal = new Set<string>();
    signal.rows.forEach((row, index) => {
      const existing = matches.get(row.item_id) ?? {
        itemId: row.item_id,
        score: 0,
        reasons: new Set<string>(),
      };
      if (!seenInSignal.has(row.item_id)) {
        existing.score += signal.weight / (k + index + 1);
        seenInSignal.add(row.item_id);
      }
      for (const reason of splitReasons(row.match_reason)) {
        existing.reasons.add(reason);
      }
      if (existing.reasons.size === 0) {
        existing.reasons.add(signal.name);
      }
      matches.set(row.item_id, existing);
    });
  }

  return [...matches.values()].sort((left, right) => right.score - left.score)
    .slice(0, limit);
}

function scoreItem(
  item: ItemRow,
  terms: string[],
): { score: number; reasons: string[] } {
  const title = item.title.toLowerCase();
  const summary = (item.searchable_summary ?? "").toLowerCase();
  const aliases = Array.isArray(item.searchable_aliases)
    ? item.searchable_aliases.map((alias) => alias.toLowerCase())
    : [];
  const parsed = JSON.stringify(item.parsed_content ?? {}).toLowerCase();
  let score = 0;
  const reasons = new Set<string>();

  for (const term of terms) {
    if (title.includes(term)) {
      score += 50;
      reasons.add("title");
    }
    if (aliases.some((alias) => alias.includes(term))) {
      score += 35;
      reasons.add("alias");
    }
    if (summary.includes(term)) {
      score += 25;
      reasons.add("summary");
    }
    if (parsed.includes(term)) {
      score += 10;
      reasons.add("parsed_content");
    }
  }

  return { score, reasons: [...reasons] };
}

function shouldRunMemoryPlan(queryPlan: SearchQueryPlan): boolean {
  return queryPlan.strictTypeFilter ||
    queryPlan.concepts.length > 0 ||
    queryPlan.intentTerms.length > 0 ||
    queryPlan.fieldScope !== "general" ||
    Boolean(queryPlan.dateRange);
}

function savedDateScore(
  createdAt: string | undefined,
  queryPlan: SearchQueryPlan,
): number {
  if (!queryPlan.dateRange || !createdAt) {
    return 0;
  }
  const savedAt = Date.parse(createdAt);
  const from = queryPlan.dateRange.from
    ? Date.parse(queryPlan.dateRange.from)
    : Number.NEGATIVE_INFINITY;
  const to = queryPlan.dateRange.to
    ? Date.parse(queryPlan.dateRange.to)
    : Number.POSITIVE_INFINITY;
  if (!Number.isFinite(savedAt)) {
    return 0;
  }
  return savedAt >= from && savedAt <= to ? 0.28 : 0;
}

function intersectsTerms(left: string[], right: string[]): boolean {
  for (const leftTerm of left) {
    if (!leftTerm) {
      continue;
    }
    for (const rightTerm of right) {
      if (!rightTerm) {
        continue;
      }
      if (
        leftTerm === rightTerm ||
        leftTerm.includes(rightTerm) ||
        rightTerm.includes(leftTerm)
      ) {
        return true;
      }
    }
  }
  return false;
}

function normalizeTerm(value: string): string {
  return value.toLocaleLowerCase().normalize("NFC").replace(/\s+/g, " ")
    .trim();
}

function normalizeItemType(value: string): SemanticContentType {
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
  return "unknown";
}

function appendReasonToRows(rows: MatchRow[], reason: string): MatchRow[] {
  return rows.map((row) => ({
    ...row,
    match_reason: [...splitReasons(row.match_reason), reason].join(", "),
  }));
}

function splitReasons(value: string): string[] {
  return value.split(",").map((reason) => reason.trim()).filter(Boolean);
}

function weightsForQuery(query: string): {
  semantic: number;
  lexical: number;
  trigram: number;
  memory: number;
} {
  const length = [...query.replace(/\s+/g, "")].length;
  if (length <= 4) {
    return { semantic: 0.75, lexical: 1.2, trigram: 1.8, memory: 2.0 };
  }
  return { semantic: 1, lexical: 1, trigram: 1.15, memory: 1.8 };
}

function trigramThresholdFor(query: string): number {
  const length = [...query.replace(/\s+/g, "")].length;
  if (length <= 4) {
    return 0.2;
  }
  if (length <= 8) {
    return 0.24;
  }
  return 0.3;
}

export function filterWeakSemanticRows(
  rows: MatchRow[],
  query: string,
): MatchRow[] {
  const threshold = semanticEmbeddingThresholdFor(query);
  return rows.filter((row) => {
    const reasons = splitReasons(row.match_reason);
    if (
      reasons.some((reason) =>
        reason === "full_text_or_alias" ||
        reason === "entity" ||
        reason === "chunk_full_text"
      )
    ) {
      return true;
    }
    return row.score >= threshold;
  });
}

export function filterWeakTrigramRows(
  rows: MatchRow[],
  query: string,
): MatchRow[] {
  const threshold = trigramAcceptanceThresholdFor(query);
  return rows.filter((row) => row.score >= threshold);
}

function semanticEmbeddingThresholdFor(query: string): number {
  const length = [...query.replace(/\s+/g, "")].length;
  if (length <= 4) {
    return 0.38;
  }
  if (length <= 10) {
    return 0.35;
  }
  return 0.32;
}

function trigramAcceptanceThresholdFor(query: string): number {
  const compact = query.replace(/\s+/g, "");
  const length = [...compact].length;
  if (length <= 4) {
    return 0.35;
  }
  if (/[\u0400-\u04FF\u0590-\u05FF]/.test(compact)) {
    return 0.4;
  }
  return 0.5;
}

function strategyForSignals(
  signals: RankedSignal[],
  fallback = "hybrid_rpc",
): string {
  const names = new Set(signals.map((signal) => signal.name));
  if (names.has("hybrid_rpc") && names.has("trigram_rpc")) {
    return names.has("memory_plan")
      ? "hybrid_rpc_trigram_memory_plan"
      : "hybrid_rpc_trigram";
  }
  if (names.has("hybrid_rpc") && names.has("memory_plan")) {
    return "hybrid_rpc_memory_plan";
  }
  if (names.has("lexical_fallback") && names.has("trigram_rpc")) {
    return names.has("memory_plan")
      ? "lexical_fallback_trigram_memory_plan"
      : "lexical_fallback_trigram";
  }
  if (names.has("lexical_fallback") && names.has("memory_plan")) {
    return "lexical_fallback_memory_plan";
  }
  if (names.has("memory_plan")) {
    return "memory_plan";
  }
  if (names.has("trigram_rpc")) {
    return "trigram_rpc";
  }
  if (names.has("lexical_fallback")) {
    return "lexical_fallback";
  }
  return fallback;
}

function combineFallbackReasons(
  ...values: Array<RowsResult | string | undefined>
): string | undefined {
  const reasons = new Set<string>();
  for (const value of values) {
    if (!value) {
      continue;
    }
    if (typeof value === "string") {
      reasons.add(value);
      continue;
    }
    if (value.errorCode) {
      reasons.add(value.errorCode);
    }
    if (value.typeFilterRelaxed) {
      reasons.add("type_filter_relaxed");
    }
  }
  return reasons.size > 0 ? [...reasons].join(", ") : undefined;
}

function normalizeLocale(
  value: SearchRequest["locale"],
): SearchRequest["locale"] {
  return value && ["en", "he", "ru", "it", "fr", "es", "de"].includes(value)
    ? value
    : "en";
}

function clampLimit(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return 20;
  }
  return Math.max(1, Math.min(50, Math.trunc(value)));
}
