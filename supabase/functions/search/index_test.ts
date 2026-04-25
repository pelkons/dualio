import { searchWithRpc } from "./index.ts";

const delikatesItemId = "79297971-852e-4e0f-bc8e-6562c493fca2";

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
    fakeSearchClient("магазин"),
    "магазин",
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
    fakeSearchClient("мaгазин"),
    "мaгазин",
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

function fakeSearchClient(query: string) {
  const item = {
    id: delikatesItemId,
    title: "Онлайн магазин продуктов премиум качества в Израиле | Деликатес",
    type: "unknown",
    searchable_summary: "Онлайн магазин продуктов премиум качества в Израиле.",
    searchable_aliases: ["delikates", "деликатес", "магазин продуктов"],
    parsed_content: {},
    created_at: "2026-04-25T00:00:00Z",
  };

  return {
    rpc(name: string, args: { inferred?: string | null }) {
      if (name === "match_semantic_items") {
        return Promise.resolve({ data: [], error: null });
      }
      if (name === "match_items_trgm") {
        if (args.inferred != null) {
          return Promise.resolve({ data: [], error: null });
        }
        return Promise.resolve({
          data: [{
            item_id: delikatesItemId,
            chunk_id: null,
            score: query === "мaгазин" ? 0.42 : 0.64,
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
