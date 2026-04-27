import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { planSearchQuery } from "../_shared/search_intent.ts";
import {
  rankAndExplain,
  sanitizeRankingForCandidates,
  type SearchRankCandidate,
  type SearchRanking,
  type SearchRankLocale,
} from "../_shared/search_ranker.ts";

type SearchRankRequest = {
  query?: string;
  locale?: SearchRankLocale;
  candidate_item_ids?: string[];
};

type RankerStatus = "complete" | "failed" | "disabled" | "quota_exceeded";

type AuthenticatedUser = {
  id: string;
};

type QuotaDecision = {
  allowed: boolean;
  status?: "quota_exceeded" | "failed";
  plan?: string;
  rankedSearchesToday?: number;
  resetAt?: string;
  error?: string;
};

type MaybePromise<T> = T | Promise<T>;

type SupabaseQueryResult<T = unknown> = {
  data?: T;
  error?: { code?: string } | null;
};

type SupabaseQueryBuilder = {
  select: (columns?: string) => SupabaseQueryBuilder;
  eq: (column: string, value: unknown) => SupabaseQueryBuilder;
  in: (
    column: string,
    values: unknown[],
  ) => Promise<SupabaseQueryResult<unknown[]>>;
  update: (values: Record<string, unknown>) => SupabaseQueryBuilder;
  insert: (values: Record<string, unknown>) => Promise<SupabaseQueryResult>;
  maybeSingle: () => Promise<SupabaseQueryResult<Record<string, unknown>>>;
};

type SupabaseClientLike = {
  auth: {
    getUser: () => Promise<
      SupabaseQueryResult<{ user?: { id?: string } | null }>
    >;
  };
  from: (table: string) => SupabaseQueryBuilder;
};

type CreateSupabaseClient = (
  url: string,
  key: string,
  options?: Record<string, unknown>,
) => SupabaseClientLike;

type RankAndExplain = (
  options: Parameters<typeof rankAndExplain>[0],
) => MaybePromise<SearchRanking | null>;

type SearchRankDeps = {
  getEnv?: (name: string) => string | undefined;
  createClient?: CreateSupabaseClient;
  authenticate?: (
    supabase: SupabaseClientLike,
    authorization: string,
  ) => MaybePromise<AuthenticatedUser | null>;
  checkAndIncrementQuota?: (
    supabase: SupabaseClientLike,
    userId: string,
    now: Date,
  ) => MaybePromise<QuotaDecision>;
  fetchCandidateItems?: (
    supabase: SupabaseClientLike,
    userId: string,
    ids: string[],
  ) => MaybePromise<SearchRankCandidate[]>;
  rankAndExplain?: RankAndExplain;
  now?: () => Date;
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
  Deno.serve((request) => handleSearchRankRequest(request));
}

export async function handleSearchRankRequest(
  request: Request,
  deps: SearchRankDeps = {},
): Promise<Response> {
  const getEnv = deps.getEnv ?? Deno.env.get;
  if (getEnv("SEARCH_RANKER_ENABLED") !== "true") {
    return rankerJson("disabled", "en", {}, 503);
  }

  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  const body = await readJsonBody(request);
  if (!body) {
    return Response.json({ error: "invalid_json" }, { status: 400 });
  }

  const parsed = parseSearchRankRequest(body);
  if (!parsed) {
    return Response.json({ error: "invalid_search_rank_request" }, {
      status: 400,
    });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  if (parsed.candidateItemIds.length === 0) {
    return rankerJson("failed", parsed.locale);
  }

  const supabaseUrl = getEnv("SUPABASE_URL");
  const supabaseAnonKey = getEnv("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseAnonKey) {
    return Response.json({ error: "supabase_env_missing" }, { status: 500 });
  }

  const clientFactory = deps.createClient ?? createSupabaseClient;
  const supabase = clientFactory(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const authenticate = deps.authenticate ?? authenticateUser;
  const user = await authenticate(supabase, authorization);
  if (!user) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const quota = await (deps.checkAndIncrementQuota ??
    checkAndIncrementRankQuota)(
      supabase,
      user.id,
      (deps.now ?? (() => new Date()))(),
    );
  if (!quota.allowed) {
    return rankerJson(
      quota.status === "quota_exceeded" ? "quota_exceeded" : "failed",
      parsed.locale,
    );
  }

  const fetchItems = deps.fetchCandidateItems ?? fetchCandidateItems;
  const candidates = await fetchItems(
    supabase,
    user.id,
    parsed.candidateItemIds,
  );
  if (candidates.length === 0) {
    return rankerJson("failed", parsed.locale);
  }

  const startedAt = Date.now();
  const ranking = await (deps.rankAndExplain ?? rankAndExplain)({
    query: parsed.query,
    queryPlan: planSearchQuery(parsed.query),
    candidates,
    locale: parsed.locale,
    timeoutMs: 1500,
  });
  const sanitized = sanitizeRankingForCandidates(ranking, candidates);

  console.info("search_rank_request", {
    user_id: user.id,
    status: sanitized ? "complete" : "failed",
    candidate_count: candidates.length,
    primary_count: sanitized?.primary.length ?? 0,
    secondary_count: sanitized?.secondary.length ?? 0,
    duration_ms: Date.now() - startedAt,
    quota_plan: quota.plan,
    ranked_searches_today: quota.rankedSearchesToday,
  });

  if (!sanitized) {
    return rankerJson("failed", parsed.locale);
  }

  return rankerJson("complete", sanitized.queryLanguage, {
    primary: sanitized.primary,
    secondary: sanitized.secondary,
    suggestion: sanitized.suggestion,
    filter_chips: sanitized.filterChips,
  });
}

export function capCandidateItemIds(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const output: string[] = [];
  const seen = new Set<string>();
  for (const raw of value) {
    if (typeof raw !== "string") {
      continue;
    }
    const id = raw.trim();
    if (!isUuid(id) || seen.has(id)) {
      continue;
    }
    output.push(id);
    seen.add(id);
    if (output.length >= 20) {
      break;
    }
  }
  return output;
}

export async function checkAndIncrementRankQuota(
  supabase: SupabaseClientLike,
  userId: string,
  now: Date,
): Promise<QuotaDecision> {
  for (let attempt = 0; attempt < 3; attempt++) {
    const profile = await fetchProfile(supabase, userId);
    if (!profile) {
      const created = await createProfile(supabase, userId, now);
      if (!created) {
        return { allowed: false, status: "failed", error: "profile_missing" };
      }
      continue;
    }

    const plan = profilePlan(profile);
    const paid = isPaidPlan(plan);
    const currentRaw = numberField(profile.ranked_searches_today);
    const resetAtRaw = stringField(profile.ranked_searches_reset_at);
    const shouldReset = shouldResetQuota(resetAtRaw, now);
    const current = shouldReset ? 0 : currentRaw;

    if (!paid && current >= 100) {
      return {
        allowed: false,
        status: "quota_exceeded",
        plan,
        rankedSearchesToday: current,
        resetAt: resetAtRaw,
      };
    }

    const nextCount = current + 1;
    const nextResetAt = shouldReset ? now.toISOString() : resetAtRaw ||
      now.toISOString();
    const { data, error } = await supabase
      .from("profiles")
      .update({
        ranked_searches_today: nextCount,
        ranked_searches_reset_at: nextResetAt,
      })
      .eq("id", userId)
      .eq("ranked_searches_today", currentRaw)
      .select("*")
      .maybeSingle();

    if (error) {
      return {
        allowed: false,
        status: "failed",
        plan,
        error: error.code ?? "quota_update_failed",
      };
    }
    if (data) {
      return {
        allowed: true,
        plan,
        rankedSearchesToday: nextCount,
        resetAt: nextResetAt,
      };
    }
  }

  return { allowed: false, status: "failed", error: "quota_update_conflict" };
}

async function authenticateUser(
  supabase: SupabaseClientLike,
  _authorization: string,
): Promise<AuthenticatedUser | null> {
  const { data, error } = await supabase.auth.getUser();
  const user = data?.user;
  if (error || !user?.id) {
    return null;
  }
  return { id: user.id };
}

async function fetchCandidateItems(
  supabase: SupabaseClientLike,
  userId: string,
  ids: string[],
): Promise<SearchRankCandidate[]> {
  const { data, error } = await supabase
    .from("items")
    .select(itemSelect)
    .eq("user_id", userId)
    .in("id", ids);
  if (error || !Array.isArray(data)) {
    return [];
  }
  const order = new Map(ids.map((id, index) => [id, index]));
  return (data as SearchRankCandidate[]).slice().sort((left, right) =>
    (order.get(left.id) ?? Number.MAX_SAFE_INTEGER) -
    (order.get(right.id) ?? Number.MAX_SAFE_INTEGER)
  );
}

async function fetchProfile(
  supabase: SupabaseClientLike,
  userId: string,
): Promise<Record<string, unknown> | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .maybeSingle();
  if (error || !data) {
    return null;
  }
  return data as Record<string, unknown>;
}

async function createProfile(
  supabase: SupabaseClientLike,
  userId: string,
  now: Date,
): Promise<boolean> {
  const { error } = await supabase.from("profiles").insert({
    id: userId,
    ranked_searches_today: 0,
    ranked_searches_reset_at: now.toISOString(),
  });
  return !error;
}

function parseSearchRankRequest(
  value: Record<string, unknown>,
):
  | { query: string; locale: SearchRankLocale; candidateItemIds: string[] }
  | null {
  const query = cleanString(value.query);
  const locale = normalizeLocale(value.locale);
  const candidateItemIds = capCandidateItemIds(value.candidate_item_ids);
  if (!query || query.length < 1) {
    return null;
  }
  return { query, locale, candidateItemIds };
}

async function readJsonBody(
  request: Request,
): Promise<Record<string, unknown> | null> {
  try {
    const value = await request.json();
    return value && typeof value === "object" && !Array.isArray(value)
      ? value as Record<string, unknown>
      : null;
  } catch {
    return null;
  }
}

function rankerJson(
  status: RankerStatus,
  queryLanguage: SearchRankLocale,
  overrides: Partial<{
    primary: Array<{ itemId: string; reason: string }>;
    secondary: Array<{ itemId: string; reason: string }>;
    suggestion: string | null;
    filter_chips: Array<{ type: string; count: number }>;
  }> = {},
  httpStatus = 200,
): Response {
  return Response.json({
    ranker_status: status,
    queryLanguage,
    primary: overrides.primary ?? [],
    secondary: overrides.secondary ?? [],
    suggestion: overrides.suggestion ?? null,
    filter_chips: overrides.filter_chips ?? [],
  }, { status: httpStatus });
}

function normalizeLocale(value: unknown): SearchRankLocale {
  return value === "he" || value === "ru" || value === "it" ||
      value === "fr" || value === "es" || value === "de" || value === "en"
    ? value
    : "en";
}

function shouldResetQuota(resetAt: string, now: Date): boolean {
  const parsed = Date.parse(resetAt);
  if (!Number.isFinite(parsed)) {
    return true;
  }
  return parsed < now.getTime() - 24 * 60 * 60 * 1000;
}

function profilePlan(profile: Record<string, unknown>): string {
  return cleanString(
    profile.plan ??
      profile.account_plan ??
      profile.subscription_plan ??
      profile.tier ??
      "free",
  ).toLowerCase();
}

function isPaidPlan(plan: string): boolean {
  return ["paid", "pro", "premium", "plus", "subscriber"].includes(plan);
}

function numberField(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.max(0, Math.trunc(value))
    : 0;
}

function stringField(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function cleanString(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.replace(/\s+/g, " ").trim();
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function createSupabaseClient(
  url: string,
  key: string,
  options?: Record<string, unknown>,
): SupabaseClientLike {
  return createClient(url, key, options) as unknown as SupabaseClientLike;
}
