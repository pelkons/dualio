import {
  openRouterProviderPreferences,
  parseJsonObject,
} from "./openrouter.ts";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

Deno.test("openRouterProviderPreferences requires structured parameters", () => {
  const preferences = openRouterProviderPreferences();
  assertEquals(preferences.require_parameters, true);
  assertEquals(preferences.allow_fallbacks, true);
  assertEquals(preferences.data_collection, "deny");
});

Deno.test("parseJsonObject extracts fenced JSON object", () => {
  const value = parseJsonObject('```json\n{"title":"Saved item"}\n```');
  assertEquals(value.title, "Saved item");
});
