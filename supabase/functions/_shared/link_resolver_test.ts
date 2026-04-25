import { detectPlatform, isSocialLoginRedirect, normalizeLinkUrl, redditJsonEndpoint } from "./link_resolver.ts";

function assertEquals<T>(actual: T, expected: T) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, got ${String(actual)}`);
  }
}

function assertNotEquals<T>(actual: T, unexpected: T) {
  if (actual === unexpected) {
    throw new Error(`Did not expect ${String(unexpected)}`);
  }
}

Deno.test("normalizeLinkUrl accepts http and https URLs", () => {
  assertEquals(normalizeLinkUrl("https://example.com/path#section")?.toString(), "https://example.com/path");
  assertEquals(normalizeLinkUrl(" http://example.com/a?b=1 ")?.toString(), "http://example.com/a?b=1");
});

Deno.test("normalizeLinkUrl rejects invalid and unsupported URLs", () => {
  assertEquals(normalizeLinkUrl("not a url"), null);
  assertEquals(normalizeLinkUrl("mailto:user@example.com"), null);
});

Deno.test("detectPlatform detects TikTok URLs", () => {
  assertEquals(detectPlatform(new URL("https://www.tiktok.com/@dualio/video/123")), "tiktok");
  assertEquals(detectPlatform(new URL("https://vt.tiktok.com/ZS92aC6uj/")), "tiktok");
});

Deno.test("detectPlatform detects Instagram URLs", () => {
  assertEquals(detectPlatform(new URL("https://www.instagram.com/reel/abc/")), "instagram");
  assertEquals(detectPlatform(new URL("https://instagram.com/p/abc/")), "instagram");
});

Deno.test("detectPlatform detects Facebook URLs", () => {
  assertEquals(detectPlatform(new URL("https://www.facebook.com/share/p/abc/")), "facebook");
  assertEquals(detectPlatform(new URL("https://fb.watch/abc/")), "facebook");
});

Deno.test("detectPlatform detects X and Twitter URLs", () => {
  assertEquals(detectPlatform(new URL("https://x.com/dualio/status/123")), "x");
  assertEquals(detectPlatform(new URL("https://twitter.com/dualio/status/123")), "x");
});

Deno.test("detectPlatform detects YouTube URLs", () => {
  assertEquals(detectPlatform(new URL("https://www.youtube.com/watch?v=abc")), "youtube");
  assertEquals(detectPlatform(new URL("https://youtu.be/abc")), "youtube");
  assertEquals(detectPlatform(new URL("https://m.youtube.com/shorts/abc")), "youtube");
});

Deno.test("detectPlatform detects Reddit URLs", () => {
  assertEquals(detectPlatform(new URL("https://www.reddit.com/r/ChatGPTCoding/comments/abc/post/")), "reddit");
  assertEquals(detectPlatform(new URL("https://old.reddit.com/r/flutterdev/comments/abc/post/")), "reddit");
});

Deno.test("redditJsonEndpoint builds canonical JSON endpoint", () => {
  assertEquals(
    redditJsonEndpoint(new URL("https://www.reddit.com/r/vibecoding/comments/1suu522/the_doubters_were_so_right/?share_id=abc")).toString(),
    "https://www.reddit.com/r/vibecoding/comments/1suu522/the_doubters_were_so_right/.json?raw_json=1",
  );
});

Deno.test("detectPlatform returns generic for other URLs", () => {
  assertEquals(detectPlatform(new URL("https://www.ynet.co.il/news/article/abc")), "generic");
  assertNotEquals(detectPlatform(new URL("https://example.com")), "facebook");
});

Deno.test("isSocialLoginRedirect detects social login pages only", () => {
  assertEquals(isSocialLoginRedirect("facebook", new URL("https://de-de.facebook.com/login")), true);
  assertEquals(isSocialLoginRedirect("instagram", new URL("https://www.instagram.com/accounts/login/")), true);
  assertEquals(isSocialLoginRedirect("reddit", new URL("https://www.reddit.com/login")), false);
  assertEquals(isSocialLoginRedirect("generic", new URL("https://example.com/login")), false);
});
