import {
  detectPlatform,
  extractOpenGraph,
  extractStructuredData,
  isSocialLoginRedirect,
  normalizeLinkUrl,
  redditJsonEndpoint,
} from "./link_resolver.ts";

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
  assertEquals(
    normalizeLinkUrl("https://example.com/path#section")?.toString(),
    "https://example.com/path",
  );
  assertEquals(
    normalizeLinkUrl(" http://example.com/a?b=1 ")?.toString(),
    "http://example.com/a?b=1",
  );
});

Deno.test("normalizeLinkUrl rejects invalid and unsupported URLs", () => {
  assertEquals(normalizeLinkUrl("not a url"), null);
  assertEquals(normalizeLinkUrl("mailto:user@example.com"), null);
});

Deno.test("detectPlatform detects TikTok URLs", () => {
  assertEquals(
    detectPlatform(new URL("https://www.tiktok.com/@dualio/video/123")),
    "tiktok",
  );
  assertEquals(
    detectPlatform(new URL("https://vt.tiktok.com/ZS92aC6uj/")),
    "tiktok",
  );
});

Deno.test("detectPlatform detects Instagram URLs", () => {
  assertEquals(
    detectPlatform(new URL("https://www.instagram.com/reel/abc/")),
    "instagram",
  );
  assertEquals(
    detectPlatform(new URL("https://instagram.com/p/abc/")),
    "instagram",
  );
});

Deno.test("detectPlatform detects Facebook URLs", () => {
  assertEquals(
    detectPlatform(new URL("https://www.facebook.com/share/p/abc/")),
    "facebook",
  );
  assertEquals(detectPlatform(new URL("https://fb.watch/abc/")), "facebook");
});

Deno.test("detectPlatform detects X and Twitter URLs", () => {
  assertEquals(detectPlatform(new URL("https://x.com/dualio/status/123")), "x");
  assertEquals(
    detectPlatform(new URL("https://twitter.com/dualio/status/123")),
    "x",
  );
});

Deno.test("detectPlatform detects YouTube URLs", () => {
  assertEquals(
    detectPlatform(new URL("https://www.youtube.com/watch?v=abc")),
    "youtube",
  );
  assertEquals(detectPlatform(new URL("https://youtu.be/abc")), "youtube");
  assertEquals(
    detectPlatform(new URL("https://m.youtube.com/shorts/abc")),
    "youtube",
  );
});

Deno.test("detectPlatform detects Reddit URLs", () => {
  assertEquals(
    detectPlatform(
      new URL("https://www.reddit.com/r/ChatGPTCoding/comments/abc/post/"),
    ),
    "reddit",
  );
  assertEquals(
    detectPlatform(
      new URL("https://old.reddit.com/r/flutterdev/comments/abc/post/"),
    ),
    "reddit",
  );
});

Deno.test("redditJsonEndpoint builds canonical JSON endpoint", () => {
  assertEquals(
    redditJsonEndpoint(
      new URL(
        "https://www.reddit.com/r/vibecoding/comments/1suu522/the_doubters_were_so_right/?share_id=abc",
      ),
    ).toString(),
    "https://www.reddit.com/r/vibecoding/comments/1suu522/the_doubters_were_so_right/.json?raw_json=1",
  );
});

Deno.test("detectPlatform returns generic for other URLs", () => {
  assertEquals(
    detectPlatform(new URL("https://www.ynet.co.il/news/article/abc")),
    "generic",
  );
  assertNotEquals(detectPlatform(new URL("https://example.com")), "facebook");
});

Deno.test("isSocialLoginRedirect detects social login pages only", () => {
  assertEquals(
    isSocialLoginRedirect(
      "facebook",
      new URL("https://de-de.facebook.com/login"),
    ),
    true,
  );
  assertEquals(
    isSocialLoginRedirect(
      "instagram",
      new URL("https://www.instagram.com/accounts/login/"),
    ),
    true,
  );
  assertEquals(
    isSocialLoginRedirect("reddit", new URL("https://www.reddit.com/login")),
    false,
  );
  assertEquals(
    isSocialLoginRedirect("generic", new URL("https://example.com/login")),
    false,
  );
});

Deno.test("extractStructuredData reads schema.org Recipe JSON-LD", () => {
  const html = `
    <script type="application/ld+json">
      {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Simple Pancakes",
        "description": "Fluffy breakfast pancakes.",
        "image": "/images/pancakes.jpg",
        "author": {"@type": "Person", "name": "Dualio Kitchen"},
        "prepTime": "PT10M",
        "cookTime": "PT15M",
        "recipeYield": "4 servings",
        "recipeIngredient": ["1 cup flour", "2 eggs", "1 cup milk"],
        "recipeInstructions": [
          {"@type": "HowToStep", "text": "Mix the batter."},
          {"@type": "HowToStep", "text": "Cook on a hot pan."}
        ],
        "aggregateRating": {"ratingValue": "4.8"}
      }
    </script>
  `;

  const structured = extractStructuredData(
    html,
    new URL("https://example.com/recipes/pancakes"),
  );

  assertEquals(structured.schemaTypes.includes("Recipe"), true);
  assertEquals(structured.recipe?.name, "Simple Pancakes");
  assertEquals(
    structured.recipe?.image,
    "https://example.com/images/pancakes.jpg",
  );
  assertEquals(structured.recipe?.ingredients.length, 3);
  assertEquals(structured.recipe?.instructions[1], "Cook on a hot pan.");
  assertEquals(structured.recipe?.ratingValue, "4.8");
});

Deno.test("extractOpenGraph falls back to link icons when no preview image exists", () => {
  const html = `
    <meta property="og:title" content="Premium Food Store"/>
    <meta property="og:description" content="Imported food and seafood."/>
    <link rel="apple-touch-icon" href="/icons/store.png"/>
    <img src="/images/hero.jpg"/>
  `;

  const preview = extractOpenGraph(html, new URL("https://example.com/"));

  assertEquals(preview.thumbnailUrl, "https://example.com/icons/store.png");
});

Deno.test("extractOpenGraph reads multiline meta attributes", () => {
  const html = `
    <meta property="og:title" content="Premium Food Store"/>
    <meta property="og:description" content="Imported food,
    seafood, and delicatessen delivery."/>
  `;

  const preview = extractOpenGraph(html, new URL("https://example.com/"));

  assertEquals(
    preview.description,
    "Imported food, seafood, and delicatessen delivery.",
  );
});

Deno.test("extractOpenGraph falls back to the first meaningful image", () => {
  const html = `
    <meta property="og:title" content="Storefront"/>
    <img src="/assets/pixel.gif"/>
    <img data-src="/images/storefront.jpg" alt="Storefront"/>
  `;

  const preview = extractOpenGraph(html, new URL("https://example.com/shop"));

  assertEquals(
    preview.thumbnailUrl,
    "https://example.com/images/storefront.jpg",
  );
});
