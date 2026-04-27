import { capCandidateItemIds, handleSearchRankRequest } from "./index.ts";
import { rankAndExplain } from "../_shared/search_ranker.ts";
import { planSearchQuery } from "../_shared/search_intent.ts";

const userId = "00000000-0000-4000-8000-000000000001";
const itemA = "00000000-0000-4000-8000-000000000101";
const itemB = "00000000-0000-4000-8000-000000000102";
const hallucinatedId = "00000000-0000-4000-8000-000000009999";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

Deno.test("capCandidateItemIds enforces 20 id limit", () => {
  const ids = Array.from(
    { length: 50 },
    (_, index) => `00000000-0000-4000-8000-${String(index).padStart(12, "0")}`,
  );
  const capped = capCandidateItemIds(ids);
  assertEquals(capped.length, 20);
  assertEquals(capped[0], ids[0]);
  assertEquals(capped[19], ids[19]);
});

Deno.test("feature flag off returns 503 without calling LLM", async () => {
  let rankerCalled = false;
  const response = await handleSearchRankRequest(searchRankRequest(), {
    getEnv: (name) => name === "SEARCH_RANKER_ENABLED" ? undefined : "value",
    createClient: () => {
      throw new Error("client should not be created");
    },
    rankAndExplain: () => {
      rankerCalled = true;
      return null;
    },
  });

  const body = await response.json();
  assertEquals(response.status, 503);
  assertEquals(body.ranker_status, "disabled");
  assertEquals(rankerCalled, false);
});

Deno.test("hallucinated itemIds are dropped from ranker output", async () => {
  const response = await handleSearchRankRequest(
    searchRankRequest(),
    deps({
      rankAndExplain: () => ({
        queryLanguage: "ru",
        primary: [
          { itemId: itemA, reason: "Primary match." },
          { itemId: hallucinatedId, reason: "Invented result." },
        ],
        secondary: [
          { itemId: itemB, reason: "Less confident match." },
        ],
        suggestion: null,
        filterChips: [
          { type: "recipe", count: 1 },
          { type: "film", count: 1 },
        ],
      }),
    }),
  );

  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.ranker_status, "complete");
  assertEquals(body.primary.length, 1);
  assertEquals(body.primary[0].itemId, itemA);
  assertEquals(body.secondary.length, 1);
  assertEquals(body.secondary[0].itemId, itemB);
});

Deno.test("ranker timeout returns failed status", async () => {
  const result = await rankAndExplain({
    query: "breakfast",
    queryPlan: planSearchQuery("breakfast"),
    candidates: [candidate(itemA, "Recipe from DB", "recipe")],
    locale: "ru",
    timeoutMs: 1,
    getEnv: (name) => name === "SEARCH_RANKER_ENABLED" ? "true" : "value",
    callRanker: ({ signal }) =>
      new Promise((resolve) => {
        const timeoutId = setTimeout(() =>
          resolve({
            status: "complete",
            json: {
              queryLanguage: "ru",
              primary: [{ itemId: itemA, reason: "Late answer." }],
              secondary: [],
              suggestion: null,
              filter_chips: [{ type: "recipe", count: 1 }],
            },
          }), 25);
        signal?.addEventListener("abort", () => clearTimeout(timeoutId), {
          once: true,
        });
      }),
  });
  assertEquals(result, null);

  const response = await handleSearchRankRequest(
    searchRankRequest(),
    deps({
      rankAndExplain: () => null,
    }),
  );
  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.ranker_status, "failed");
  assertEquals(body.primary.length, 0);
});

Deno.test("quota exceeded skips LLM call", async () => {
  let rankerCalled = false;
  const response = await handleSearchRankRequest(
    searchRankRequest(),
    deps({
      checkAndIncrementQuota: () => ({
        allowed: false,
        status: "quota_exceeded",
        plan: "free",
        rankedSearchesToday: 100,
      }),
      rankAndExplain: () => {
        rankerCalled = true;
        return null;
      },
    }),
  );

  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.ranker_status, "quota_exceeded");
  assertEquals(rankerCalled, false);
});

Deno.test("server fetches DB items and ignores client supplied metadata", async () => {
  let observedTitle = "";
  const response = await handleSearchRankRequest(
    searchRankRequest({
      candidate_item_ids: [itemA],
      candidates: [{ itemId: itemA, title: "Fake client title" }],
    }),
    deps({
      fetchCandidateItems: (_client, _userId, ids) =>
        ids.map((id) => candidate(id, "Real DB title", "recipe")),
      rankAndExplain: ({ candidates }) => {
        observedTitle = candidates[0]?.title ?? "";
        return {
          queryLanguage: "ru",
          primary: [{ itemId: itemA, reason: "Reason from DB data." }],
          secondary: [],
          suggestion: null,
          filterChips: [{ type: "recipe", count: 1 }],
        };
      },
    }),
  );

  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.ranker_status, "complete");
  assertEquals(observedTitle, "Real DB title");
});

Deno.test("handler caps client ids before DB fetch", async () => {
  const ids = Array.from(
    { length: 50 },
    (_, index) => `00000000-0000-4000-8000-${String(index).padStart(12, "0")}`,
  );
  let observedIds: string[] = [];
  const response = await handleSearchRankRequest(
    searchRankRequest({ candidate_item_ids: ids }),
    deps({
      fetchCandidateItems: (_client, _userId, cappedIds) => {
        observedIds = cappedIds;
        return cappedIds.map((id) => candidate(id, "Fetched item", "note"));
      },
      rankAndExplain: ({ candidates }) => ({
        queryLanguage: "ru",
        primary: candidates.slice(0, 1).map((item) => ({
          itemId: item.id,
          reason: "First result.",
        })),
        secondary: [],
        suggestion: null,
        filterChips: [{ type: "note", count: 1 }],
      }),
    }),
  );

  const body = await response.json();
  assertEquals(response.status, 200);
  assertEquals(body.ranker_status, "complete");
  assertEquals(observedIds.length, 20);
  assertEquals(observedIds[19], ids[19]);
});

function searchRankRequest(
  overrides: Record<string, unknown> = {},
): Request {
  return new Request("http://localhost/search-rank", {
    method: "POST",
    headers: {
      "Authorization": "Bearer test-token",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      query: "breakfast",
      locale: "ru",
      candidate_item_ids: [itemA, itemB],
      ...overrides,
    }),
  });
}

function deps(
  overrides: Parameters<typeof handleSearchRankRequest>[1] = {},
): Parameters<typeof handleSearchRankRequest>[1] {
  return {
    getEnv: (name) => {
      if (name === "SEARCH_RANKER_ENABLED") {
        return "true";
      }
      if (name === "SUPABASE_URL") {
        return "https://example.supabase.co";
      }
      if (name === "SUPABASE_ANON_KEY") {
        return "anon";
      }
      return undefined;
    },
    createClient: () => fakeSupabaseClient(),
    authenticate: () => ({ id: userId }),
    checkAndIncrementQuota: () => ({
      allowed: true,
      plan: "free",
      rankedSearchesToday: 1,
    }),
    fetchCandidateItems: (_client, _userId, ids) =>
      ids.map((id, index) =>
        candidate(
          id,
          index === 0 ? "Breakfast recipe" : "Breakfast film",
          index === 0 ? "recipe" : "film",
        )
      ),
    rankAndExplain: ({ candidates }) => ({
      queryLanguage: "ru",
      primary: [{ itemId: candidates[0].id, reason: "Primary match." }],
      secondary: [],
      suggestion: null,
      filterChips: [{ type: candidates[0].type, count: 1 }],
    }),
    ...overrides,
  };
}

function fakeSupabaseClient() {
  return {
    auth: {
      getUser: () => Promise.resolve({ data: { user: { id: userId } } }),
    },
    from: () => {
      throw new Error("fake query builder should not be used");
    },
  };
}

function candidate(
  id: string,
  title: string,
  type: string,
) {
  return {
    id,
    title,
    type,
    language: "ru",
    searchable_summary: title,
    searchable_aliases: [title],
    parsed_content: {
      memoryProfile: {
        domain: type === "recipe" ? "food" : "entertainment",
        objectType: type,
        canonicalConcepts: [type],
        primaryConcepts: [title],
        searchIntents: ["find later"],
        usageContexts: [],
        facets: {},
        incidentalMentions: [],
        possibleRecallPhrases: [title],
        negativeSignals: [],
        confidence: 0.8,
      },
    },
    match_reason: "memory_profile",
    created_at: "2026-04-27T00:00:00Z",
  };
}
