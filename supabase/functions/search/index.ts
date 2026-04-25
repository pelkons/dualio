import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  embeddingToPgVector,
  generateEmbeddings,
} from "../_shared/embeddings.ts";
import { inferItemTypeFromQuery } from "../_shared/search_intent.ts";
import type { SemanticContentType } from "../_shared/semantic_extraction.ts";

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
  const inferred = inferItemTypeFromQuery(query);
  const embedding = await generateEmbeddings([query]);
  const searchResult = embedding.status === "complete" && embedding.vectors[0]
    ? await searchWithRpc(
      supabase,
      query,
      embeddingToPgVector(embedding.vectors[0]),
      inferred,
      limit,
    )
    : await fallbackLexicalSearch(supabase, query, inferred, limit);

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
      }
      : undefined,
  });
}

export async function searchWithRpc(
  supabase: any,
  query: string,
  queryEmbedding: string,
  inferred: SemanticContentType | null,
  limit: number,
): Promise<SearchExecutionResult> {
  const weights = weightsForQuery(query);
  const semantic = await fetchRowsWithTypeRelaxation(
    (type) => fetchSemanticRows(supabase, query, queryEmbedding, type, limit),
    inferred,
    "type_filter_relaxed",
  );
  const trigram = await fetchRowsWithTypeRelaxation(
    (type) => fetchTrigramRows(supabase, query, type, limit),
    inferred,
    "trigram_type_filter_relaxed",
  );

  if (
    semantic.errorCode && semantic.rows.length === 0 &&
    trigram.rows.length === 0
  ) {
    return await fallbackLexicalSearch(
      supabase,
      query,
      inferred,
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
  inferred: SemanticContentType | null,
  limit: number,
  fallbackReason?: string,
): Promise<SearchExecutionResult> {
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
  if (lexicalRows.length === 0 && inferred) {
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

  return { rows: data as MatchRow[] };
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

  return { rows: data as MatchRow[] };
}

async function fetchRowsWithTypeRelaxation(
  fetcher: (inferred: SemanticContentType | null) => Promise<RowsResult>,
  inferred: SemanticContentType | null,
  relaxedReason: string,
): Promise<RowsResult> {
  const constrained = await fetcher(inferred);
  if (
    constrained.rows.length > 0 || inferred === null || constrained.errorCode
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
} {
  const length = [...query.replace(/\s+/g, "")].length;
  if (length <= 4) {
    return { semantic: 0.75, lexical: 1.2, trigram: 1.8 };
  }
  return { semantic: 1, lexical: 1, trigram: 1.15 };
}

function trigramThresholdFor(query: string): number {
  const length = [...query.replace(/\s+/g, "")].length;
  if (length <= 4) {
    return 0.08;
  }
  if (length <= 8) {
    return 0.12;
  }
  return 0.15;
}

function strategyForSignals(
  signals: RankedSignal[],
  fallback = "hybrid_rpc",
): string {
  const names = new Set(signals.map((signal) => signal.name));
  if (names.has("hybrid_rpc") && names.has("trigram_rpc")) {
    return "hybrid_rpc_trigram";
  }
  if (names.has("lexical_fallback") && names.has("trigram_rpc")) {
    return "lexical_fallback_trigram";
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
