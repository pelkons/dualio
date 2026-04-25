import {
  filterWeakSemanticRows,
  filterWeakTrigramRows,
  searchWithRpc,
} from "./index.ts";

const delikatesItemId = "79297971-852e-4e0f-bc8e-6562c493fca2";
const russianShopQuery = "\u043c\u0430\u0433\u0430\u0437\u0438\u043d";
const mixedScriptShopTypoQuery = "\u043c\u0061\u0433\u0430\u0437\u0438\u043d";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

function assertIncludes(actual: string, expected: string) {
  if (!actual.includes(expected)) {
    throw new Error(`Expected "${actual}" to include "${expected}"`);
  }
}

Deno.test("searchWithRpc keeps Russian whole-word recall via trigram", async () => {
  const result = await searchWithRpc(
    fakeSearchClient(russianShopQuery),
    russianShopQuery,
    "[0,0,0]",
    "product",
    20,
  );

  const first = result.results[0] as {
    item?: { id?: string };
    match_reason?: string;
  };
  assertEquals(first.item?.id, delikatesItemId);
  assertIncludes(first.match_reason ?? "", "title_trigram");
  assertIncludes(first.match_reason ?? "", "trigram_type_filter_relaxed");
});

Deno.test("searchWithRpc keeps Russian typo recall via trigram", async () => {
  const result = await searchWithRpc(
    fakeSearchClient(mixedScriptShopTypoQuery),
    mixedScriptShopTypoQuery,
    "[0,0,0]",
    "product",
    20,
  );

  const first = result.results[0] as {
    item?: { id?: string };
    match_reason?: string;
  };
  assertEquals(first.item?.id, delikatesItemId);
  assertIncludes(first.match_reason ?? "", "title_trigram");
});

Deno.test("filterWeakSemanticRows drops weak embedding-only matches", () => {
  const rows = filterWeakSemanticRows(
    [
      {
        item_id: "00000000-0000-0000-0000-000000000001",
        chunk_id: null,
        score: 0.21,
        match_reason: "chunk_embedding, item_embedding",
      },
      {
        item_id: "00000000-0000-0000-0000-000000000002",
        chunk_id: null,
        score: 0.74,
        match_reason: "full_text_or_alias",
      },
    ],
    "banana",
  );

  assertEquals(rows.length, 1);
  assertEquals(rows[0].match_reason, "full_text_or_alias");
});

Deno.test("filterWeakTrigramRows drops noisy trigram matches", () => {
  const rows = filterWeakTrigramRows(
    [
      {
        item_id: "00000000-0000-0000-0000-000000000001",
        chunk_id: null,
        score: 0.37,
        match_reason: "summary_trigram",
      },
      {
        item_id: "00000000-0000-0000-0000-000000000002",
        chunk_id: null,
        score: 0.64,
        match_reason: "title_trigram",
      },
    ],
    russianShopQuery,
  );

  assertEquals(rows.length, 1);
  assertEquals(rows[0].match_reason, "title_trigram");
});

Deno.test("searchWithRpc does not return weak vector-only results", async () => {
  const result = await searchWithRpc(
    fakeSearchClient("zzzznotfound", {
      semanticRows: [
        {
          item_id: delikatesItemId,
          chunk_id: null,
          score: 0.2,
          match_reason: "chunk_embedding, item_embedding",
        },
      ],
      trigramRows: [],
    }),
    "zzzznotfound",
    "[0,0,0]",
    null,
    20,
  );

  assertEquals(result.results.length, 0);
});

function fakeSearchClient(
  query: string,
  options: {
    semanticRows?: Array<{
      item_id: string;
      chunk_id: string | null;
      score: number;
      match_reason: string;
    }>;
    trigramRows?: Array<{
      item_id: string;
      chunk_id: string | null;
      score: number;
      match_reason: string;
    }>;
  } = {},
) {
  const item = {
    id: delikatesItemId,
    title:
      "\u041e\u043d\u043b\u0430\u0439\u043d \u043c\u0430\u0433\u0430\u0437\u0438\u043d \u043f\u0440\u043e\u0434\u0443\u043a\u0442\u043e\u0432 \u043f\u0440\u0435\u043c\u0438\u0443\u043c \u043a\u0430\u0447\u0435\u0441\u0442\u0432\u0430 \u0432 \u0418\u0437\u0440\u0430\u0438\u043b\u0435 | \u0414\u0435\u043b\u0438\u043a\u0430\u0442\u0435\u0441",
    type: "unknown",
    searchable_summary:
      "\u041e\u043d\u043b\u0430\u0439\u043d \u043c\u0430\u0433\u0430\u0437\u0438\u043d \u043f\u0440\u043e\u0434\u0443\u043a\u0442\u043e\u0432 \u043f\u0440\u0435\u043c\u0438\u0443\u043c \u043a\u0430\u0447\u0435\u0441\u0442\u0432\u0430 \u0432 \u0418\u0437\u0440\u0430\u0438\u043b\u0435.",
    searchable_aliases: [
      "delikates",
      "\u0434\u0435\u043b\u0438\u043a\u0430\u0442\u0435\u0441",
      "\u043c\u0430\u0433\u0430\u0437\u0438\u043d \u043f\u0440\u043e\u0434\u0443\u043a\u0442\u043e\u0432",
    ],
    parsed_content: {},
    created_at: "2026-04-25T00:00:00Z",
  };

  return {
    rpc(name: string, args: { inferred?: string | null }) {
      if (name === "match_semantic_items") {
        return Promise.resolve({
          data: options.semanticRows ?? [],
          error: null,
        });
      }
      if (name === "match_items_trgm") {
        if (options.trigramRows) {
          return Promise.resolve({ data: options.trigramRows, error: null });
        }
        if (args.inferred != null) {
          return Promise.resolve({ data: [], error: null });
        }
        return Promise.resolve({
          data: [{
            item_id: delikatesItemId,
            chunk_id: null,
            score: query === mixedScriptShopTypoQuery ? 0.42 : 0.64,
            match_reason: "title_trigram",
          }],
          error: null,
        });
      }
      return Promise.resolve({ data: [], error: { code: "unknown_rpc" } });
    },
    from(table: string) {
      if (table !== "items") {
        throw new Error(`Unexpected table ${table}`);
      }
      return {
        select(_columns: string) {
          return {
            in(_column: string, ids: string[]) {
              return Promise.resolve({
                data: ids.includes(delikatesItemId) ? [item] : [],
              });
            },
          };
        },
      };
    },
  };
}
