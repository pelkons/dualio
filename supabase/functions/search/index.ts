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

type MatchRow = {
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

Deno.serve(async (request: Request): Promise<Response> => {
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
});

async function searchWithRpc(
  supabase: any,
  query: string,
  queryEmbedding: string,
  inferred: SemanticContentType | null,
  limit: number,
): Promise<
  {
    strategy: string;
    fallbackReason?: string;
    results: Array<Record<string, unknown>>;
  }
> {
  const { data, error } = await supabase.rpc("match_semantic_items", {
    query_embedding: queryEmbedding,
    query_text: query,
    inferred,
    match_count: limit,
  });

  if (error || !Array.isArray(data)) {
    return await fallbackLexicalSearch(
      supabase,
      query,
      inferred,
      limit,
      error?.code ?? "rpc_failed",
    );
  }

  const combined = combineMatches(data as MatchRow[], limit);
  if (combined.length === 0) {
    return { strategy: "hybrid_rpc", results: [] };
  }

  const items = await fetchItemsByIds(
    supabase,
    combined.map((match) => match.itemId),
  );
  const byId = new Map(items.map((item) => [item.id, item]));
  return {
    strategy: "hybrid_rpc",
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
): Promise<
  {
    strategy: string;
    fallbackReason?: string;
    results: Array<Record<string, unknown>>;
  }
> {
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
    return {
      strategy: "lexical_fallback",
      fallbackReason: error?.code ?? fallbackReason,
      results: [],
    };
  }

  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  const scored = (data as ItemRow[])
    .map((item) => ({ item, ...scoreItem(item, terms) }))
    .filter((entry) => entry.score > 0)
    .sort((left, right) => right.score - left.score)
    .slice(0, limit)
    .map((entry) => ({
      item: entry.item,
      score: entry.score / 100,
      match_reason: entry.reasons.join(", "),
    }));

  return { strategy: "lexical_fallback", fallbackReason, results: scored };
}

async function fetchItemsByIds(
  supabase: any,
  ids: string[],
): Promise<ItemRow[]> {
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

function combineMatches(rows: MatchRow[], limit: number): CombinedMatch[] {
  const matches = new Map<string, CombinedMatch>();
  for (const row of rows) {
    const existing = matches.get(row.item_id);
    if (!existing) {
      matches.set(row.item_id, {
        itemId: row.item_id,
        score: Number(row.score) || 0,
        reasons: new Set(
          row.match_reason.split(",").map((value) => value.trim()).filter(
            Boolean,
          ),
        ),
      });
      continue;
    }
    existing.score = Math.max(existing.score, Number(row.score) || 0);
    for (const reason of row.match_reason.split(",")) {
      const trimmed = reason.trim();
      if (trimmed) {
        existing.reasons.add(trimmed);
      }
    }
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
