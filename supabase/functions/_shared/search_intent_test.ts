import { inferItemTypeFromQuery, planSearchQuery } from "./search_intent.ts";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

Deno.test("inferItemTypeFromQuery recognizes Russian intent", () => {
  assertEquals(
    inferItemTypeFromQuery(
      "\u0440\u0435\u0446\u0435\u043f\u0442 \u043f\u0430\u0441\u0442\u044b",
    ),
    "recipe",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u0444\u0438\u043b\u044c\u043c \u043f\u0440\u043e \u043a\u043e\u0441\u043c\u043e\u0441",
    ),
    "film",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u0440\u0435\u0441\u0442\u043e\u0440\u0430\u043d \u0432 \u0446\u0435\u043d\u0442\u0440\u0435",
    ),
    "place",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u043a\u0443\u043f\u0438\u0442\u044c \u043d\u0430\u0443\u0448\u043d\u0438\u043a\u0438",
    ),
    "product",
  );
  assertEquals(
    inferItemTypeFromQuery("\u0432\u0438\u0434\u0435\u043e \u0441 youtube"),
    "video",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u0438\u043d\u0441\u0442\u0440\u0443\u043a\u0446\u0438\u044f \u043f\u043e \u0441\u0431\u043e\u0440\u043a\u0435",
    ),
    "manual",
  );
});

Deno.test("inferItemTypeFromQuery recognizes Hebrew intent", () => {
  assertEquals(
    inferItemTypeFromQuery(
      "\u05de\u05ea\u05db\u05d5\u05df \u05dc\u05e4\u05e1\u05d8\u05d4",
    ),
    "recipe",
  );
  assertEquals(
    inferItemTypeFromQuery("\u05e1\u05e8\u05d8 \u05dc\u05e8\u05d0\u05d5\u05ea"),
    "film",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u05de\u05e1\u05e2\u05d3\u05d4 \u05e7\u05e8\u05d5\u05d1\u05d4",
    ),
    "place",
  );
  assertEquals(
    inferItemTypeFromQuery("\u05de\u05d7\u05d9\u05e8 \u05de\u05d5\u05e6\u05e8"),
    "product",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u05e1\u05e8\u05d8\u05d5\u05df \u05de\u05d8\u05d9\u05e7\u05d8\u05d5\u05e7",
    ),
    "video",
  );
  assertEquals(
    inferItemTypeFromQuery(
      "\u05de\u05d3\u05e8\u05d9\u05da \u05d4\u05ea\u05e7\u05e0\u05d4",
    ),
    "manual",
  );
});

Deno.test("inferItemTypeFromQuery recognizes English manual intent", () => {
  assertEquals(inferItemTypeFromQuery("how to install a shelf"), "manual");
  assertEquals(
    inferItemTypeFromQuery("step by step setup checklist"),
    "manual",
  );
});

Deno.test("inferItemTypeFromQuery keeps unknown broad queries unconstrained", () => {
  assertEquals(inferItemTypeFromQuery("saved ideas from last week"), null);
});

Deno.test("planSearchQuery keeps broad association queries for AI planning", () => {
  const plan = planSearchQuery(
    "\u043d\u0430\u0439\u0434\u0438 \u0442\u043e, \u0447\u0442\u043e \u044f \u0445\u043e\u0442\u0435\u043b \u043f\u043e\u0434\u0430\u0440\u0438\u0442\u044c",
  );
  assertEquals(plan.inferredType, null);
  assertEquals(plan.strictTypeFilter, false);
  assertEquals(plan.plannerStatus, "fallback");
});

Deno.test("planSearchQuery keeps explicit object type as cheap fallback", () => {
  const plan = planSearchQuery(
    "\u043a\u0438\u043d\u043e \u0441 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435\u043c \u043f\u0440\u043e \u0440\u0435\u043a\u0443",
  );
  assertEquals(plan.inferredType, "film");
  assertEquals(plan.targetTypes[0], "film");
  assertEquals(plan.fieldScope, "general");
});

Deno.test("planSearchQuery parses saved time separately from usage context", () => {
  const plan = planSearchQuery(
    "Find the document I saved a few months ago",
    new Date("2026-04-26T00:00:00Z"),
  );
  assertEquals(plan.dateRange?.label, "a_few_months_ago");
});
