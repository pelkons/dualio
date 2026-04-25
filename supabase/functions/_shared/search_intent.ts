import type { SemanticContentType } from "./semantic_extraction.ts";

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

export function inferItemTypeFromQuery(
  query: string,
): SemanticContentType | null {
  const normalized = query.toLocaleLowerCase().normalize("NFC");
  for (const group of orderedKeywordGroups()) {
    if (
      group.keywords.some((keyword) => includesKeyword(normalized, keyword))
    ) {
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

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
