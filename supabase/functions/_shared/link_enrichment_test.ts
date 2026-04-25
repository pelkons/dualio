import { enrichLinkUnofficial } from "./link_enrichment.ts";
import type { LinkResolverResult } from "./link_resolver.ts";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

async function withEnv<T>(
  values: Record<string, string | undefined>,
  callback: () => Promise<T>,
): Promise<T> {
  const previous = new Map<string, string | undefined>();
  for (const key of Object.keys(values)) {
    previous.set(key, Deno.env.get(key));
    const value = values[key];
    if (value === undefined) {
      Deno.env.delete(key);
    } else {
      Deno.env.set(key, value);
    }
  }

  try {
    return await callback();
  } finally {
    for (const [key, value] of previous.entries()) {
      if (value === undefined) {
        Deno.env.delete(key);
      } else {
        Deno.env.set(key, value);
      }
    }
  }
}

function resolvedLink(
  platform: LinkResolverResult["platform"],
): LinkResolverResult {
  return {
    url: `https://${
      platform === "generic" ? "example.com" : `${platform}.example.com`
    }/post/123`,
    platform,
    resolver: "fallback",
    extractionStatus: "partial",
    title: "Saved link",
    providerName: "Example",
    needsUserContext: true,
  };
}

Deno.test("enrichLinkUnofficial skips social HTML unless social flag is explicitly enabled", async () => {
  const originalFetch = globalThis.fetch;
  let fetchCalled = false;
  globalThis.fetch = (() => {
    fetchCalled = true;
    throw new Error("fetch should not be called");
  }) as typeof fetch;

  try {
    const result = await withEnv({
      ENABLE_UNOFFICIAL_LINK_ENRICHMENT: "true",
      ENABLE_SOCIAL_HTML_ENRICHMENT: undefined,
    }, () => enrichLinkUnofficial(resolvedLink("instagram")));

    assertEquals(result.enabled, true);
    assertEquals(result.attempted, false);
    assertEquals(result.status, "skipped");
    assertEquals(fetchCalled, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("enrichLinkUnofficial still attempts generic HTML when general flag is enabled", async () => {
  const originalFetch = globalThis.fetch;
  let fetchCalled = false;
  globalThis.fetch = (() => {
    fetchCalled = true;
    const response = new Response(
      "<html><head><title>Saved article</title></head></html>",
      {
        headers: { "content-type": "text/html" },
      },
    );
    Object.defineProperty(response, "url", {
      value: "https://example.com/post/123",
    });
    return Promise.resolve(response);
  }) as typeof fetch;

  try {
    const result = await withEnv({
      ENABLE_UNOFFICIAL_LINK_ENRICHMENT: "true",
      ENABLE_SOCIAL_HTML_ENRICHMENT: undefined,
    }, () => enrichLinkUnofficial(resolvedLink("generic")));

    assertEquals(fetchCalled, true);
    assertEquals(result.attempted, true);
    assertEquals(result.status, "partial");
    assertEquals(result.title, "Saved article");
  } finally {
    globalThis.fetch = originalFetch;
  }
});
