export type LinkPlatform =
  | "tiktok"
  | "instagram"
  | "facebook"
  | "x"
  | "youtube"
  | "reddit"
  | "generic";

export type LinkResolverName =
  | "tiktok_oembed"
  | "meta_oembed"
  | "x_oembed"
  | "youtube_oembed"
  | "reddit_json"
  | "reddit_oembed"
  | "opengraph"
  | "fallback";

export type LinkExtractionStatus = "complete" | "partial" | "failed";

export type LinkResolverResult = {
  url: string;
  canonicalUrl?: string;
  platform: LinkPlatform;
  resolver: LinkResolverName;
  extractionStatus: LinkExtractionStatus;
  title?: string;
  description?: string;
  authorName?: string;
  authorUrl?: string;
  thumbnailUrl?: string;
  providerName?: string;
  htmlEmbed?: string;
  structuredData?: LinkStructuredData;
  needsUserContext: boolean;
  error?: string;
};

export type LinkStructuredData = {
  schemaTypes: string[];
  recipe?: StructuredRecipe;
};

export type StructuredRecipe = {
  name?: string;
  description?: string;
  image?: string;
  authorName?: string;
  prepTime?: string;
  cookTime?: string;
  totalTime?: string;
  recipeYield?: string;
  ingredients: string[];
  instructions: string[];
  ratingValue?: string;
};

export type OpenGraphResult = {
  canonicalUrl?: string;
  title?: string;
  description?: string;
  thumbnailUrl?: string;
  providerName?: string;
  structuredData?: LinkStructuredData;
};

const htmlFetchHeaders = {
  "accept": "text/html,application/xhtml+xml",
  "user-agent":
    "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
};

const facebookHtmlFetchHeaders = {
  "accept": "text/html,application/xhtml+xml",
  "user-agent": "Mozilla/5.0 (compatible; Twitterbot/1.0)",
};

const redditFetchHeaders = {
  "accept": "application/json",
  "user-agent":
    "Mozilla/5.0 (compatible; Dualio/0.1; +https://github.com/pelkons/dualio)",
};

const redditRedirectHeaders = {
  "accept": "text/html,application/xhtml+xml",
  "user-agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36",
};

function isRedditShareUrl(url: URL): boolean {
  return /\/r\/[^/]+\/s\/[^/]+\/?$/i.test(url.pathname);
}

function hasUsefulRedditPreview(result: LinkResolverResult): boolean {
  return Boolean(
    result.title || result.description || result.thumbnailUrl ||
      result.htmlEmbed,
  );
}

type RedditUrlInfo = {
  postId?: string;
  slug?: string;
  subreddit?: string;
};

function extractRedditUrlInfo(url: URL): RedditUrlInfo {
  const match = url.pathname.match(
    /^\/r\/([^/]+)\/comments\/([^/]+)(?:\/([^/]*))?/i,
  );
  if (!match) {
    return {};
  }
  return {
    subreddit: match[1],
    postId: match[2],
    slug: match[3] && match[3].length > 0 ? match[3] : undefined,
  };
}

function titleFromSlug(slug: string): string {
  return slug
    .replace(/[_-]+/g, " ")
    .split(" ")
    .filter((word) => word.length > 0)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ")
    .trim();
}

type RedditFallbackContext = {
  title?: string;
  thumbnailUrl?: string;
  providerName?: string;
  canonicalUrl?: string;
};

function urlInfoToFallback(
  info: RedditUrlInfo,
  canonicalUrl: URL,
): RedditFallbackContext {
  const fallback: RedditFallbackContext = {};
  if (info.slug) {
    fallback.title = titleFromSlug(info.slug);
  }
  if (info.subreddit) {
    fallback.providerName = `r/${info.subreddit}`;
  }
  fallback.canonicalUrl = canonicalUrl.toString();
  return fallback;
}

function isGenericRedditSharePreview(url: string | undefined): boolean {
  if (!url) {
    return false;
  }
  return /^https?:\/\/share\.redd\.it\/preview\/post\/[A-Za-z0-9]+$/i.test(url);
}

function isPlaceholderRedditTitle(value: string | undefined): boolean {
  if (!value) {
    return true;
  }
  if (value === "Reddit link") {
    return true;
  }
  if (/^From the .+ community on Reddit$/i.test(value)) {
    return true;
  }
  if (/please wait for verification/i.test(value)) {
    return true;
  }
  return false;
}

function applySlugFallback(
  result: LinkResolverResult,
  fallback: RedditFallbackContext,
): LinkResolverResult {
  if (
    !fallback.title && !fallback.thumbnailUrl && !fallback.providerName &&
    !fallback.canonicalUrl
  ) {
    return result;
  }
  const title = isPlaceholderRedditTitle(result.title)
    ? fallback.title ?? result.title
    : result.title;
  const thumbnailUrl = result.thumbnailUrl ?? fallback.thumbnailUrl;
  const providerName =
    result.providerName && result.providerName !== "Reddit" &&
      result.providerName !== "www.reddit.com" &&
      result.providerName !== "reddit.com"
      ? result.providerName
      : fallback.providerName ?? result.providerName;
  const canonicalUrl = result.canonicalUrl ?? fallback.canonicalUrl;
  const hasUseful = Boolean(title || result.description || thumbnailUrl);
  return {
    ...result,
    title,
    thumbnailUrl,
    providerName,
    canonicalUrl,
    extractionStatus: hasUseful && result.extractionStatus !== "complete"
      ? "partial"
      : result.extractionStatus,
    needsUserContext: !hasUseful,
  };
}

export async function resolveLink(url: string): Promise<LinkResolverResult> {
  const normalizedUrl = normalizeLinkUrl(url);
  if (!normalizedUrl) {
    return {
      url,
      platform: "generic",
      resolver: "fallback",
      extractionStatus: "failed",
      needsUserContext: true,
      error: "invalid_url",
    };
  }

  const platform = detectPlatform(normalizedUrl);

  if (platform === "tiktok") {
    const tiktokResult = await resolveTikTokOEmbed(normalizedUrl);
    if (tiktokResult.extractionStatus === "complete") {
      return tiktokResult;
    }
  }

  if (platform === "x") {
    const xResult = await resolveXOEmbed(normalizedUrl);
    if (xResult.extractionStatus === "complete") {
      return xResult;
    }
  }

  if (platform === "youtube") {
    const youtubeResult = await resolveYouTubeOEmbed(normalizedUrl);
    if (youtubeResult.extractionStatus === "complete") {
      return youtubeResult;
    }
  }

  if (platform === "reddit") {
    const expandedUrl = await expandRedditShareUrl(normalizedUrl);
    const urlInfo = extractRedditUrlInfo(expandedUrl);
    const slugFallback = urlInfoToFallback(urlInfo, expandedUrl);

    const redditResult = await resolveRedditJson(expandedUrl);
    if (redditResult.extractionStatus === "complete") {
      return redditResult;
    }

    const ogTarget = redditResult.canonicalUrl
      ? normalizeLinkUrl(redditResult.canonicalUrl) ?? expandedUrl
      : expandedUrl;
    const redditOg = await resolveOpenGraph(ogTarget, "reddit");
    if (
      redditOg.extractionStatus !== "failed" && hasUsefulRedditPreview(redditOg)
    ) {
      return applySlugFallback(
        mergeRedditResults(redditResult, redditOg),
        slugFallback,
      );
    }

    if (hasUsefulRedditPreview(redditResult)) {
      return applySlugFallback(redditResult, slugFallback);
    }

    if (redditOg.extractionStatus !== "failed") {
      return applySlugFallback(redditOg, slugFallback);
    }

    return applySlugFallback(redditResult, slugFallback);
  }

  if (platform === "instagram" || platform === "facebook") {
    const metaResult = await resolveMetaOEmbed(normalizedUrl, platform);
    if (metaResult.extractionStatus === "complete") {
      return metaResult;
    }
  }

  const openGraphResult = await resolveOpenGraph(normalizedUrl, platform);
  if (openGraphResult.extractionStatus !== "failed") {
    return openGraphResult;
  }

  return minimalFallback(normalizedUrl, platform, openGraphResult.error);
}

function mergeRedditResults(
  primary: LinkResolverResult,
  og: LinkResolverResult,
): LinkResolverResult {
  const primaryHasRealTitle = primary.resolver === "reddit_json" ||
    primary.resolver === "reddit_oembed";
  const title = primaryHasRealTitle
    ? primary.title ?? og.title
    : og.title ?? primary.title;
  const description = primary.description ?? og.description;
  const thumbnailUrl = primary.thumbnailUrl ?? og.thumbnailUrl;
  const authorName = primary.authorName ?? og.authorName;
  const authorUrl = primary.authorUrl ?? og.authorUrl;
  const providerName =
    (primaryHasRealTitle ? primary.providerName : undefined) ??
      og.providerName ?? primary.providerName;
  const canonicalUrl = primary.canonicalUrl ?? og.canonicalUrl;

  return {
    ...primary,
    canonicalUrl,
    extractionStatus: title || description || thumbnailUrl
      ? "complete"
      : primary.extractionStatus,
    title,
    description,
    authorName,
    authorUrl,
    thumbnailUrl,
    providerName,
    htmlEmbed: primary.htmlEmbed ?? og.htmlEmbed,
    needsUserContext: !(title || description || thumbnailUrl),
  };
}

export function normalizeLinkUrl(value: string): URL | null {
  try {
    const url = new URL(value.trim());
    if (url.protocol !== "http:" && url.protocol !== "https:") {
      return null;
    }
    url.hash = "";
    return url;
  } catch {
    return null;
  }
}

export function detectPlatform(url: URL): LinkPlatform {
  const hostname = url.hostname.toLowerCase();

  if (
    hostname === "tiktok.com" || hostname.endsWith(".tiktok.com") ||
    hostname === "vt.tiktok.com"
  ) {
    return "tiktok";
  }

  if (hostname === "instagram.com" || hostname.endsWith(".instagram.com")) {
    return "instagram";
  }

  if (
    hostname === "facebook.com" || hostname.endsWith(".facebook.com") ||
    hostname === "fb.watch"
  ) {
    return "facebook";
  }

  if (
    hostname === "x.com" || hostname.endsWith(".x.com") ||
    hostname === "twitter.com" || hostname.endsWith(".twitter.com")
  ) {
    return "x";
  }

  if (
    hostname === "youtu.be" || hostname === "youtube.com" ||
    hostname.endsWith(".youtube.com")
  ) {
    return "youtube";
  }

  if (hostname === "reddit.com" || hostname.endsWith(".reddit.com")) {
    return "reddit";
  }

  return "generic";
}

async function resolveTikTokOEmbed(url: URL): Promise<LinkResolverResult> {
  try {
    const endpoint = new URL("https://www.tiktok.com/oembed");
    endpoint.searchParams.set("url", url.toString());

    const response = await fetchWithTimeout(endpoint, {
      headers: { "accept": "application/json" },
    });
    if (!response.ok) {
      return minimalFallback(url, "tiktok", `tiktok_oembed_${response.status}`);
    }

    const payload = await response.json() as Record<string, unknown>;
    return {
      url: url.toString(),
      platform: "tiktok",
      resolver: "tiktok_oembed",
      extractionStatus: "complete",
      title: stringValue(payload.title),
      authorName: stringValue(payload.author_name),
      authorUrl: stringValue(payload.author_url),
      thumbnailUrl: stringValue(payload.thumbnail_url),
      providerName: stringValue(payload.provider_name),
      htmlEmbed: stringValue(payload.html),
      needsUserContext: false,
    };
  } catch (error) {
    return minimalFallback(url, "tiktok", errorName(error));
  }
}

async function resolveXOEmbed(url: URL): Promise<LinkResolverResult> {
  try {
    const endpoint = new URL("https://publish.twitter.com/oembed");
    endpoint.searchParams.set("url", url.toString());
    endpoint.searchParams.set("omit_script", "true");

    const response = await fetchWithTimeout(endpoint, {
      headers: { "accept": "application/json" },
    });
    if (!response.ok) {
      return minimalFallback(url, "x", `x_oembed_${response.status}`);
    }

    const payload = await response.json() as Record<string, unknown>;
    return {
      url: url.toString(),
      platform: "x",
      resolver: "x_oembed",
      extractionStatus: "complete",
      title: stringValue(payload.title) ?? "X post",
      authorName: stringValue(payload.author_name),
      authorUrl: stringValue(payload.author_url),
      providerName: stringValue(payload.provider_name) ?? "X",
      htmlEmbed: stringValue(payload.html),
      needsUserContext: false,
    };
  } catch (error) {
    return minimalFallback(url, "x", errorName(error));
  }
}

async function resolveYouTubeOEmbed(url: URL): Promise<LinkResolverResult> {
  try {
    const endpoint = new URL("https://www.youtube.com/oembed");
    endpoint.searchParams.set("url", url.toString());
    endpoint.searchParams.set("format", "json");

    const response = await fetchWithTimeout(endpoint, {
      headers: { "accept": "application/json" },
    });
    if (!response.ok) {
      return minimalFallback(
        url,
        "youtube",
        `youtube_oembed_${response.status}`,
      );
    }

    const payload = await response.json() as Record<string, unknown>;
    return {
      url: url.toString(),
      platform: "youtube",
      resolver: "youtube_oembed",
      extractionStatus: "complete",
      title: stringValue(payload.title),
      authorName: stringValue(payload.author_name),
      authorUrl: stringValue(payload.author_url),
      thumbnailUrl: stringValue(payload.thumbnail_url),
      providerName: stringValue(payload.provider_name) ?? "YouTube",
      htmlEmbed: stringValue(payload.html),
      needsUserContext: false,
    };
  } catch (error) {
    return minimalFallback(url, "youtube", errorName(error));
  }
}

async function resolveRedditJson(url: URL): Promise<LinkResolverResult> {
  let canonicalPostUrl = url;
  try {
    canonicalPostUrl = await expandRedditShareUrl(url);
    const endpoint = redditJsonEndpoint(canonicalPostUrl);

    const response = await fetchWithTimeout(endpoint, {
      redirect: "follow",
      headers: redditFetchHeaders,
    });
    if (!response.ok) {
      return await resolveRedditOEmbed(
        canonicalPostUrl,
        `reddit_json_${response.status}`,
      );
    }

    const payload = await response.json();
    const post = extractRedditPost(payload);
    if (!post) {
      return await resolveRedditOEmbed(canonicalPostUrl, "reddit_json_no_post");
    }

    return {
      url: url.toString(),
      canonicalUrl: post.permalink
        ? new URL(post.permalink, "https://www.reddit.com").toString()
        : canonicalPostUrl.toString(),
      platform: "reddit",
      resolver: "reddit_json",
      extractionStatus: "complete",
      title: post.title,
      description: redditDescription(post),
      authorName: post.author,
      authorUrl: post.author
        ? `https://www.reddit.com/user/${post.author}`
        : undefined,
      thumbnailUrl: redditThumbnailUrl(post),
      providerName: post.subreddit ? `r/${post.subreddit}` : "Reddit",
      needsUserContext: false,
    };
  } catch (error) {
    return await resolveRedditOEmbed(canonicalPostUrl, errorName(error));
  }
}

async function resolveRedditOEmbed(
  url: URL,
  previousError?: string,
): Promise<LinkResolverResult> {
  try {
    const endpoint = new URL("https://www.reddit.com/oembed");
    endpoint.searchParams.set("url", url.toString());
    const response = await fetchWithTimeout(endpoint, {
      redirect: "follow",
      headers: redditFetchHeaders,
    });
    if (!response.ok) {
      return minimalFallback(
        url,
        "reddit",
        previousError
          ? `${previousError};reddit_oembed_${response.status}`
          : `reddit_oembed_${response.status}`,
      );
    }

    const payload = await response.json() as Record<string, unknown>;
    return {
      url: url.toString(),
      canonicalUrl: url.toString(),
      platform: "reddit",
      resolver: "reddit_oembed",
      extractionStatus: "partial",
      title: stringValue(payload.title),
      authorName: stringValue(payload.author_name),
      providerName: stringValue(payload.provider_name) ?? "Reddit",
      htmlEmbed: stringValue(payload.html),
      needsUserContext: false,
      error: previousError,
    };
  } catch (error) {
    return minimalFallback(
      url,
      "reddit",
      previousError ? `${previousError};${errorName(error)}` : errorName(error),
    );
  }
}

async function expandRedditShareUrl(url: URL): Promise<URL> {
  if (!isRedditShareUrl(url)) {
    return url;
  }

  try {
    const manualResponse = await fetchWithTimeout(url, {
      redirect: "manual",
      headers: redditRedirectHeaders,
    });
    const location = manualResponse.headers.get("location");
    if (location) {
      const expanded = new URL(location, url);
      expanded.hash = "";
      return expanded;
    }
  } catch {
    // fall through to follow-mode below
  }

  try {
    const followResponse = await fetchWithTimeout(url, {
      redirect: "follow",
      headers: redditRedirectHeaders,
    });
    const finalUrl = new URL(followResponse.url);
    if (!isRedditShareUrl(finalUrl)) {
      finalUrl.hash = "";
      return finalUrl;
    }
  } catch {
    // give up, caller will handle the unexpanded URL
  }

  return url;
}

export function redditJsonEndpoint(url: URL): URL {
  const endpoint = new URL(url.toString());
  endpoint.search = "";
  endpoint.hash = "";
  endpoint.pathname = endpoint.pathname.replace(/\/$/, "") + "/.json";
  endpoint.searchParams.set("raw_json", "1");
  return endpoint;
}

async function resolveMetaOEmbed(
  url: URL,
  platform: "instagram" | "facebook",
): Promise<LinkResolverResult> {
  const accessToken = Deno.env.get("META_OEMBED_ACCESS_TOKEN");
  if (!accessToken) {
    return minimalFallback(url, platform, "meta_oembed_access_token_missing");
  }

  try {
    const endpointName = platform === "instagram"
      ? "instagram_oembed"
      : "oembed_post";
    const endpoint = new URL(
      `https://graph.facebook.com/v19.0/${endpointName}`,
    );
    endpoint.searchParams.set("url", url.toString());
    endpoint.searchParams.set("access_token", accessToken);

    const response = await fetchWithTimeout(endpoint, {
      headers: { "accept": "application/json" },
    });
    if (!response.ok) {
      return minimalFallback(url, platform, `meta_oembed_${response.status}`);
    }

    const payload = await response.json() as Record<string, unknown>;
    return {
      url: url.toString(),
      platform,
      resolver: "meta_oembed",
      extractionStatus: "complete",
      title: stringValue(payload.title),
      authorName: stringValue(payload.author_name),
      authorUrl: stringValue(payload.author_url),
      thumbnailUrl: stringValue(payload.thumbnail_url),
      providerName: stringValue(payload.provider_name),
      htmlEmbed: stringValue(payload.html),
      needsUserContext: false,
    };
  } catch (error) {
    return minimalFallback(url, platform, errorName(error));
  }
}

async function resolveOpenGraph(
  url: URL,
  platform: LinkPlatform,
): Promise<LinkResolverResult> {
  try {
    const headers = platform === "facebook"
      ? facebookHtmlFetchHeaders
      : htmlFetchHeaders;
    const response = await fetchWithTimeout(url, {
      redirect: "follow",
      headers,
    });

    if (!response.ok) {
      return minimalFallback(url, platform, `opengraph_${response.status}`);
    }

    const contentType = response.headers.get("content-type") ?? "";
    if (
      !contentType.includes("text/html") &&
      !contentType.includes("application/xhtml+xml")
    ) {
      return {
        ...minimalFallback(url, platform, "non_html_response"),
        extractionStatus: "partial",
        providerName: url.hostname,
      };
    }

    const html = await response.text();
    const finalUrl = new URL(response.url);
    const extracted = extractOpenGraph(html, finalUrl, platform);
    const weakSocialData = isWeakSocialOpenGraph(platform, finalUrl, extracted);
    const hasUsefulData = Boolean(
      extracted.title || extracted.description || extracted.thumbnailUrl,
    );
    const canonicalUrl =
      weakSocialData && isSocialLoginRedirect(platform, finalUrl)
        ? url.toString()
        : extracted.canonicalUrl ?? finalUrl.toString();

    return {
      url: url.toString(),
      canonicalUrl,
      platform,
      resolver: hasUsefulData ? "opengraph" : "fallback",
      extractionStatus: weakSocialData
        ? "partial"
        : hasUsefulData
        ? "complete"
        : "partial",
      title: extracted.title,
      description: extracted.description,
      thumbnailUrl: extracted.thumbnailUrl,
      providerName: extracted.providerName ?? finalUrl.hostname,
      structuredData: extracted.structuredData,
      needsUserContext: weakSocialData || !hasUsefulData,
      error: weakSocialData ? "weak_social_metadata" : undefined,
    };
  } catch (error) {
    return minimalFallback(url, platform, errorName(error));
  }
}

export function extractOpenGraph(
  html: string,
  baseUrl: URL,
  platform: LinkPlatform = "generic",
): OpenGraphResult {
  const canonicalUrl = linkHref(html, "canonical");
  const ogTitle = cleanText(metaProperty(html, "og:title"));
  const twitterTitle = cleanText(metaName(html, "twitter:title"));
  const documentTitle = cleanText(
    firstMatch(html, /<title[^>]*>([\s\S]*?)<\/title>/i),
  );
  const ogDescription = cleanText(metaProperty(html, "og:description"));
  const twitterDescription = cleanText(metaName(html, "twitter:description"));
  const metaDescription = cleanText(metaName(html, "description"));

  let title = ogTitle || twitterTitle || documentTitle;
  let description = ogDescription || twitterDescription || metaDescription;

  if (platform === "reddit") {
    const cleanedDocumentTitle = stripRedditTitleSuffix(documentTitle);
    if (cleanedDocumentTitle && !isRedditGenericTitle(cleanedDocumentTitle)) {
      title = cleanedDocumentTitle;
    } else if (isRedditGenericTitle(title)) {
      const altTitle = extractRedditTitleFromOgImageAlt(html);
      if (altTitle) {
        title = altTitle;
      }
    }
    if (metaDescription && !isRedditGenericDescription(metaDescription)) {
      description = metaDescription;
    }
  }

  const image = metaProperty(html, "og:image") ??
    metaName(html, "twitter:image");
  const providerName = cleanText(metaProperty(html, "og:site_name"));
  let resolvedImage = image ? resolveImageCandidate(image, baseUrl) : undefined;

  if (isAmazonHost(baseUrl.hostname)) {
    title = cleanAmazonTitle(title);
  }

  const structuredData = extractStructuredData(html, baseUrl);
  if (structuredData.recipe) {
    title = structuredData.recipe.name ?? title;
    description = structuredData.recipe.description ?? description;
    resolvedImage = structuredData.recipe.image ?? resolvedImage;
  }
  resolvedImage = resolvedImage ??
    extractJsonLdImageHint(html, baseUrl) ??
    extractProductImageHint(html, baseUrl) ??
    extractLinkImageHint(html, baseUrl) ??
    extractFirstMeaningfulImage(html, baseUrl);

  return {
    canonicalUrl: canonicalUrl
      ? new URL(decodeHtml(canonicalUrl), baseUrl).toString()
      : undefined,
    title: title || undefined,
    description: description || undefined,
    thumbnailUrl:
      platform === "reddit" && isGenericRedditSharePreview(resolvedImage)
        ? undefined
        : resolvedImage,
    providerName: providerName || undefined,
    structuredData,
  };
}

export function extractStructuredData(
  html: string,
  baseUrl: URL,
): LinkStructuredData {
  const nodes = extractJsonLdNodes(html);
  const schemaTypes = [
    ...new Set(nodes.flatMap((node) => typeValues(node["@type"]))),
  ];
  const recipeNode = nodes.find((node) =>
    typeValues(node["@type"]).some((type) => type.toLowerCase() === "recipe")
  );

  return {
    schemaTypes,
    recipe: recipeNode ? recipeFromJsonLd(recipeNode, baseUrl) : undefined,
  };
}

function extractJsonLdNodes(html: string): Array<Record<string, unknown>> {
  const nodes: Array<Record<string, unknown>> = [];
  for (
    const match of html.matchAll(
      /<script\b[^>]*type\s*=\s*(["'])application\/ld\+json\1[^>]*>([\s\S]*?)<\/script>/gi,
    )
  ) {
    const rawJson = decodeHtml(match[2])
      .replace(/^\s*<!--/, "")
      .replace(/-->\s*$/, "")
      .trim();
    if (!rawJson) {
      continue;
    }
    try {
      collectJsonLdNodes(JSON.parse(rawJson), nodes);
    } catch {
      // Ignore malformed JSON-LD; OpenGraph data can still be useful.
    }
  }
  return nodes;
}

function collectJsonLdNodes(
  value: unknown,
  nodes: Array<Record<string, unknown>>,
) {
  if (Array.isArray(value)) {
    for (const item of value) {
      collectJsonLdNodes(item, nodes);
    }
    return;
  }
  if (!value || typeof value !== "object") {
    return;
  }

  const object = value as Record<string, unknown>;
  if (object["@type"]) {
    nodes.push(object);
  }
  if (Array.isArray(object["@graph"])) {
    collectJsonLdNodes(object["@graph"], nodes);
  }
}

function recipeFromJsonLd(
  value: Record<string, unknown>,
  baseUrl: URL,
): StructuredRecipe {
  return {
    name: textValue(value.name),
    description: textValue(value.description),
    image: imageValue(value.image, baseUrl),
    authorName: textValue(value.author),
    prepTime: textValue(value.prepTime),
    cookTime: textValue(value.cookTime),
    totalTime: textValue(value.totalTime),
    recipeYield: recipeYieldValue(value.recipeYield),
    ingredients: stringArrayValue(value.recipeIngredient),
    instructions: instructionValues(value.recipeInstructions),
    ratingValue: ratingValue(value.aggregateRating),
  };
}

function typeValues(value: unknown): string[] {
  if (typeof value === "string") {
    return [value];
  }
  if (Array.isArray(value)) {
    return value.filter((item): item is string => typeof item === "string");
  }
  return [];
}

function textValue(value: unknown): string | undefined {
  if (typeof value === "string") {
    return cleanText(stripHtml(value));
  }
  if (Array.isArray(value)) {
    return value.map(textValue).find(Boolean);
  }
  if (value && typeof value === "object") {
    const object = value as Record<string, unknown>;
    return textValue(object.name ?? object.text ?? object["@value"]);
  }
  return undefined;
}

function recipeYieldValue(value: unknown): string | undefined {
  if (Array.isArray(value)) {
    return value.map(textValue).filter(Boolean).join(", ") || undefined;
  }
  return textValue(value);
}

function stringArrayValue(value: unknown): string[] {
  if (typeof value === "string") {
    return value.split(/\r?\n/).map((item) => cleanText(stripHtml(item)))
      .filter(
        Boolean,
      );
  }
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map(textValue).filter((item): item is string => Boolean(item));
}

function instructionValues(value: unknown): string[] {
  if (typeof value === "string") {
    return [cleanText(stripHtml(value))].filter(Boolean);
  }
  if (!Array.isArray(value)) {
    return textValue(value) ? [textValue(value)!] : [];
  }

  const steps: string[] = [];
  for (const item of value) {
    if (typeof item === "string") {
      const text = cleanText(stripHtml(item));
      if (text) {
        steps.push(text);
      }
      continue;
    }
    if (!item || typeof item !== "object") {
      continue;
    }
    const object = item as Record<string, unknown>;
    if (Array.isArray(object.itemListElement)) {
      steps.push(...instructionValues(object.itemListElement));
      continue;
    }
    const text = textValue(object.text ?? object.name);
    if (text) {
      steps.push(text);
    }
  }
  return steps;
}

function imageValue(value: unknown, baseUrl: URL): string | undefined {
  const candidate = Array.isArray(value) ? value[0] : value;
  const raw = candidate && typeof candidate === "object"
    ? textValue(
      (candidate as Record<string, unknown>).url ??
        (candidate as Record<string, unknown>).contentUrl,
    )
    : textValue(candidate);
  if (!raw) {
    return undefined;
  }
  try {
    return new URL(raw, baseUrl).toString();
  } catch {
    return undefined;
  }
}

function ratingValue(value: unknown): string | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }
  return textValue((value as Record<string, unknown>).ratingValue);
}

function stripHtml(value: string): string {
  return value.replace(/<[^>]+>/g, " ");
}

function extractJsonLdImageHint(
  html: string,
  baseUrl: URL,
): string | undefined {
  const nodes = extractJsonLdNodes(html);
  for (const node of nodes) {
    const image = imageValue(
      node.image ?? node.logo ?? node.thumbnailUrl,
      baseUrl,
    );
    if (image) {
      return image;
    }
  }
  return undefined;
}

function extractProductImageHint(
  html: string,
  baseUrl: URL,
): string | undefined {
  const oldHires = html.match(/\bdata-old-hires\s*=\s*["'](https?:\/\/[^"']+)/i)
    ?.[1];
  if (oldHires) {
    return resolveImageCandidate(oldHires, baseUrl);
  }
  const hiRes = html.match(/"hiRes"\s*:\s*"(https?:\/\/[^"]+)"/i)?.[1];
  if (hiRes) {
    return resolveImageCandidate(hiRes, baseUrl);
  }
  const landing = html.match(
    /<img[^>]+id\s*=\s*["']landingImage["'][^>]+src\s*=\s*["'](https?:\/\/[^"']+)/i,
  )?.[1];
  if (landing) {
    return resolveImageCandidate(landing, baseUrl);
  }
  return undefined;
}

function extractLinkImageHint(html: string, baseUrl: URL): string | undefined {
  const rels = [
    "image_src",
    "apple-touch-icon",
    "apple-touch-icon-precomposed",
    "icon",
    "mask-icon",
  ];
  for (const rel of rels) {
    const href = linkHref(html, rel);
    const image = href ? resolveImageCandidate(href, baseUrl) : undefined;
    if (image) {
      return image;
    }
  }
  return undefined;
}

function extractFirstMeaningfulImage(
  html: string,
  baseUrl: URL,
): string | undefined {
  for (const match of html.matchAll(/<img\b[^>]*>/gi)) {
    const image = imageFromImgTag(match[0], baseUrl);
    if (image) {
      return image;
    }
  }
  return undefined;
}

function imageFromImgTag(tag: string, baseUrl: URL): string | undefined {
  const directAttributes = [
    "src",
    "data-src",
    "data-lazy-src",
    "data-original",
    "data-image",
  ];
  for (const attribute of directAttributes) {
    const value = attributeValue(tag, attribute);
    const image = value ? resolveImageCandidate(value, baseUrl) : undefined;
    if (image) {
      return image;
    }
  }
  return imageFromSrcSet(
    attributeValue(tag, "srcset") ?? attributeValue(tag, "data-srcset"),
    baseUrl,
  );
}

function imageFromSrcSet(
  srcset: string | null,
  baseUrl: URL,
): string | undefined {
  if (!srcset) {
    return undefined;
  }
  const parts = srcset.split(
    /,\s+(?=(?:https?:)?\/\/|\/|\.\.?\/|[^,\s]+\.(?:avif|gif|jpe?g|png|svg|webp))/i,
  );
  let best: { image: string; score: number } | undefined;
  for (const part of parts) {
    const [rawUrl, descriptor] = part.trim().split(/\s+/, 2);
    const image = resolveImageCandidate(rawUrl, baseUrl);
    if (!image) {
      continue;
    }
    const score = srcSetDescriptorScore(descriptor);
    if (!best || score > best.score) {
      best = { image, score };
    }
  }
  return best?.image;
}

function srcSetDescriptorScore(value: string | undefined): number {
  if (!value) {
    return 1;
  }
  const density = value.match(/^([0-9.]+)x$/i);
  if (density) {
    return Number.parseFloat(density[1]) || 1;
  }
  const width = value.match(/^([0-9]+)w$/i);
  if (width) {
    return Number.parseInt(width[1], 10) || 1;
  }
  return 1;
}

function resolveImageCandidate(
  value: string,
  baseUrl: URL,
): string | undefined {
  const decoded = decodeHtml(value).trim();
  if (!isLikelyUsefulImageUrl(decoded)) {
    return undefined;
  }
  try {
    const url = new URL(decoded, baseUrl);
    if (url.protocol !== "http:" && url.protocol !== "https:") {
      return undefined;
    }
    return url.toString();
  } catch {
    return undefined;
  }
}

function isLikelyUsefulImageUrl(value: string): boolean {
  if (!value) {
    return false;
  }
  const lower = value.toLowerCase();
  if (
    lower.startsWith("data:") ||
    lower.startsWith("blob:") ||
    lower.startsWith("javascript:")
  ) {
    return false;
  }
  return !/(^|[/_.-])(pixel|spacer|blank|transparent|tracking)([/_.-]|$)/i
    .test(lower);
}

function isAmazonHost(hostname: string): boolean {
  const lower = hostname.toLowerCase();
  return lower === "a.co" ||
    lower === "amzn.to" ||
    lower === "amazon.com" ||
    lower.endsWith(".amazon.com") ||
    /(^|\.)amazon\.[a-z.]+$/i.test(lower);
}

function cleanAmazonTitle(value: string): string {
  if (!value) {
    return value;
  }
  let cleaned = value.replace(/^Amazon\.[a-z.]+:\s*/i, "");
  cleaned = cleaned.replace(/\s*:\s*[^:]{1,40}$/, "");
  return cleaned.trim();
}

function stripRedditTitleSuffix(value: string): string {
  return value.replace(/\s*[:|–-]\s*r\/[A-Za-z0-9_]+\s*$/i, "").trim();
}

function isRedditGenericTitle(value: string): boolean {
  if (!value) {
    return true;
  }
  return /^From the .+ community on Reddit$/i.test(value);
}

function isRedditGenericDescription(value: string): boolean {
  if (!value) {
    return true;
  }
  return /^Explore this post and more from the .+ community$/i.test(value);
}

function extractRedditTitleFromOgImageAlt(html: string): string | null {
  const alt = cleanText(metaProperty(html, "og:image:alt"));
  if (!alt) {
    return null;
  }
  const match = alt.match(
    /^From the .+ community on Reddit:\s*["“]?(.+?)["”]?$/i,
  );
  return match ? match[1].trim() : null;
}

function isWeakSocialOpenGraph(
  platform: LinkPlatform,
  finalUrl: URL,
  result: OpenGraphResult,
): boolean {
  if (
    platform === "generic" || platform === "youtube" || platform === "reddit"
  ) {
    return false;
  }

  const title = (result.title ?? "").toLowerCase();
  const description = result.description ?? "";
  const hasUsefulData = Boolean(
    result.title && (description || result.thumbnailUrl),
  );
  const redirectedToLogin = isSocialLoginRedirect(platform, finalUrl);
  const genericTitle = title === "facebook" ||
    title.includes("log in") ||
    title.includes("make your day") ||
    title === "instagram" ||
    title === "x" ||
    title === "twitter";

  return redirectedToLogin || (genericTitle && !hasUsefulData) ||
    !hasUsefulData;
}

export function isSocialLoginRedirect(
  platform: LinkPlatform,
  finalUrl: URL,
): boolean {
  if (
    platform === "generic" || platform === "youtube" || platform === "reddit"
  ) {
    return false;
  }

  return finalUrl.pathname.includes("/login") ||
    finalUrl.pathname.includes("/accounts/login");
}

function minimalFallback(
  url: URL,
  platform: LinkPlatform,
  error?: string,
): LinkResolverResult {
  return {
    url: url.toString(),
    platform,
    resolver: "fallback",
    extractionStatus: error === "invalid_url" ? "failed" : "partial",
    title: platform === "generic" ? url.hostname : platformLabel(platform),
    providerName: url.hostname,
    needsUserContext: platform !== "generic",
    error,
  };
}

async function fetchWithTimeout(
  input: URL,
  init: RequestInit,
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 4500);
  try {
    return await fetch(input, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timeoutId);
  }
}

function linkHref(html: string, rel: string): string | null {
  for (const match of html.matchAll(/<link\b[^>]*>/gi)) {
    const tag = match[0];
    const relValue = attributeValue(tag, "rel");
    if (
      relValue?.toLowerCase().split(/\s+/).includes(rel.toLowerCase()) == true
    ) {
      return attributeValue(tag, "href");
    }
  }
  return null;
}

function metaName(html: string, name: string): string | null {
  for (const match of html.matchAll(/<meta\b[^>]*>/gi)) {
    const tag = match[0];
    if (attributeValue(tag, "name")?.toLowerCase() === name.toLowerCase()) {
      return attributeValue(tag, "content");
    }
  }
  return null;
}

function metaProperty(html: string, property: string): string | null {
  for (const match of html.matchAll(/<meta\b[^>]*>/gi)) {
    const tag = match[0];
    if (
      attributeValue(tag, "property")?.toLowerCase() === property.toLowerCase()
    ) {
      return attributeValue(tag, "content");
    }
  }
  return null;
}

function firstMatch(value: string, pattern: RegExp): string | null {
  return value.match(pattern)?.[1] ?? null;
}

function cleanText(value: string | null): string {
  return decodeHtml(value ?? "").replace(/\s+/g, " ").trim();
}

function decodeHtml(value: string): string {
  return value
    .replace(
      /&#x([0-9a-f]+);/gi,
      (_, hex: string) => String.fromCodePoint(Number.parseInt(hex, 16)),
    )
    .replace(
      /&#([0-9]+);/g,
      (_, decimal: string) =>
        String.fromCodePoint(Number.parseInt(decimal, 10)),
    )
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function attributeValue(tag: string, attribute: string): string | null {
  const pattern = new RegExp(
    `\\b${attribute}\\s*=\\s*(["'])([\\s\\S]*?)\\1`,
    "i",
  );
  return tag.match(pattern)?.[2] ?? null;
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0
    ? value.trim()
    : undefined;
}

function errorName(error: unknown): string {
  return error instanceof Error ? error.name : "unknown_error";
}

function platformLabel(platform: LinkPlatform): string {
  switch (platform) {
    case "tiktok":
      return "TikTok link";
    case "instagram":
      return "Instagram link";
    case "facebook":
      return "Facebook link";
    case "x":
      return "X link";
    case "youtube":
      return "YouTube link";
    case "reddit":
      return "Reddit link";
    case "generic":
      return "Link";
  }
}

type RedditPost = {
  id?: string;
  title?: string;
  selftext?: string;
  author?: string;
  subreddit?: string;
  permalink?: string;
  thumbnail?: string;
  previewImage?: string;
  score?: number;
  numComments?: number;
};

function extractRedditPost(payload: unknown): RedditPost | null {
  const listing = Array.isArray(payload) ? payload[0] : payload;
  if (!listing || typeof listing !== "object") {
    return null;
  }

  const data = (listing as Record<string, unknown>).data;
  if (!data || typeof data !== "object") {
    return null;
  }

  const children = (data as Record<string, unknown>).children;
  if (!Array.isArray(children) || children.length === 0) {
    return null;
  }

  const postData = (children[0] as Record<string, unknown>).data;
  if (!postData || typeof postData !== "object") {
    return null;
  }

  const post = postData as Record<string, unknown>;
  return {
    id: stringValue(post.id),
    title: stringValue(post.title),
    selftext: stringValue(post.selftext),
    author: stringValue(post.author),
    subreddit: stringValue(post.subreddit),
    permalink: stringValue(post.permalink),
    thumbnail: stringValue(post.thumbnail),
    previewImage: extractRedditPreviewImage(post.preview),
    score: numberValue(post.score ?? post.ups),
    numComments: numberValue(post.num_comments),
  };
}

function extractRedditPreviewImage(value: unknown): string | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }
  const images = (value as Record<string, unknown>).images;
  if (!Array.isArray(images) || images.length === 0) {
    return undefined;
  }
  const source = (images[0] as Record<string, unknown>).source;
  if (!source || typeof source !== "object") {
    return undefined;
  }
  return stringValue((source as Record<string, unknown>).url);
}

function usableRedditImage(value: string | undefined): string | undefined {
  if (!value || value === "self" || value === "default" || value === "nsfw") {
    return undefined;
  }
  return decodeHtml(value);
}

function redditThumbnailUrl(post: RedditPost): string | undefined {
  const image = usableRedditImage(post.previewImage ?? post.thumbnail);
  if (image) {
    return image;
  }
  return undefined;
}

function redditDescription(post: RedditPost): string | undefined {
  const parts = [
    post.selftext,
    post.subreddit ? `r/${post.subreddit}` : undefined,
    typeof post.score === "number" ? `${post.score} upvotes` : undefined,
    typeof post.numComments === "number"
      ? `${post.numComments} comments`
      : undefined,
  ].filter(Boolean);
  return parts.join(" - ") || undefined;
}

function numberValue(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}
