export type LinkPlatform = "tiktok" | "instagram" | "facebook" | "x" | "youtube" | "reddit" | "generic";

export type LinkResolverName = "tiktok_oembed" | "meta_oembed" | "x_oembed" | "youtube_oembed" | "reddit_json" | "reddit_oembed" | "opengraph" | "fallback";

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
  needsUserContext: boolean;
  error?: string;
};

type OpenGraphResult = {
  canonicalUrl?: string;
  title?: string;
  description?: string;
  thumbnailUrl?: string;
  providerName?: string;
};

const htmlFetchHeaders = {
  "accept": "text/html,application/xhtml+xml",
  "user-agent": "DualioBot/0.1 link metadata fetcher",
};

const redditFetchHeaders = {
  "accept": "application/json",
  "user-agent": "Mozilla/5.0 (compatible; Dualio/0.1; +https://github.com/pelkons/dualio)",
};

const redditRedirectHeaders = {
  "accept": "text/html,application/xhtml+xml",
  "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36",
};

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
    const redditResult = await resolveRedditJson(normalizedUrl);
    if (redditResult.extractionStatus !== "failed") {
      return redditResult;
    }
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

  if (hostname === "tiktok.com" || hostname.endsWith(".tiktok.com") || hostname === "vt.tiktok.com") {
    return "tiktok";
  }

  if (hostname === "instagram.com" || hostname.endsWith(".instagram.com")) {
    return "instagram";
  }

  if (hostname === "facebook.com" || hostname.endsWith(".facebook.com") || hostname === "fb.watch") {
    return "facebook";
  }

  if (hostname === "x.com" || hostname.endsWith(".x.com") || hostname === "twitter.com" || hostname.endsWith(".twitter.com")) {
    return "x";
  }

  if (hostname === "youtu.be" || hostname === "youtube.com" || hostname.endsWith(".youtube.com")) {
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
      return minimalFallback(url, "youtube", `youtube_oembed_${response.status}`);
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
      return await resolveRedditOEmbed(canonicalPostUrl, `reddit_json_${response.status}`);
    }

    const payload = await response.json();
    const post = extractRedditPost(payload);
    if (!post) {
      return await resolveRedditOEmbed(canonicalPostUrl, "reddit_json_no_post");
    }

    return {
      url: url.toString(),
      canonicalUrl: post.permalink ? new URL(post.permalink, "https://www.reddit.com").toString() : canonicalPostUrl.toString(),
      platform: "reddit",
      resolver: "reddit_json",
      extractionStatus: "complete",
      title: post.title,
      description: redditDescription(post),
      authorName: post.author,
      authorUrl: post.author ? `https://www.reddit.com/user/${post.author}` : undefined,
      thumbnailUrl: redditThumbnailUrl(post),
      providerName: post.subreddit ? `r/${post.subreddit}` : "Reddit",
      needsUserContext: false,
    };
  } catch (error) {
    return await resolveRedditOEmbed(canonicalPostUrl, errorName(error));
  }
}

async function resolveRedditOEmbed(url: URL, previousError?: string): Promise<LinkResolverResult> {
  try {
    const endpoint = new URL("https://www.reddit.com/oembed");
    endpoint.searchParams.set("url", url.toString());
    const response = await fetchWithTimeout(endpoint, {
      redirect: "follow",
      headers: redditFetchHeaders,
    });
    if (!response.ok) {
      return minimalFallback(url, "reddit", previousError ? `${previousError};reddit_oembed_${response.status}` : `reddit_oembed_${response.status}`);
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
    return minimalFallback(url, "reddit", previousError ? `${previousError};${errorName(error)}` : errorName(error));
  }
}

async function expandRedditShareUrl(url: URL): Promise<URL> {
  if (!/\/r\/[^/]+\/s\/[^/]+\/?$/i.test(url.pathname)) {
    return url;
  }

  const response = await fetchWithTimeout(url, {
    redirect: "manual",
    headers: redditRedirectHeaders,
  });
  const location = response.headers.get("location");
  if (!location) {
    return url;
  }

  const expanded = new URL(location, url);
  expanded.hash = "";
  return expanded;
}

export function redditJsonEndpoint(url: URL): URL {
  const endpoint = new URL(url.toString());
  endpoint.search = "";
  endpoint.hash = "";
  endpoint.pathname = endpoint.pathname.replace(/\/$/, "") + "/.json";
  endpoint.searchParams.set("raw_json", "1");
  return endpoint;
}

async function resolveMetaOEmbed(url: URL, platform: "instagram" | "facebook"): Promise<LinkResolverResult> {
  const accessToken = Deno.env.get("META_OEMBED_ACCESS_TOKEN");
  if (!accessToken) {
    return minimalFallback(url, platform, "meta_oembed_access_token_missing");
  }

  try {
    const endpointName = platform === "instagram" ? "instagram_oembed" : "oembed_post";
    const endpoint = new URL(`https://graph.facebook.com/v19.0/${endpointName}`);
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

async function resolveOpenGraph(url: URL, platform: LinkPlatform): Promise<LinkResolverResult> {
  try {
    const response = await fetchWithTimeout(url, {
      redirect: "follow",
      headers: htmlFetchHeaders,
    });

    if (!response.ok) {
      return minimalFallback(url, platform, `opengraph_${response.status}`);
    }

    const contentType = response.headers.get("content-type") ?? "";
    if (!contentType.includes("text/html") && !contentType.includes("application/xhtml+xml")) {
      return {
        ...minimalFallback(url, platform, "non_html_response"),
        extractionStatus: "partial",
        providerName: url.hostname,
      };
    }

    const html = await response.text();
    const finalUrl = new URL(response.url);
    const extracted = extractOpenGraph(html, finalUrl);
    const weakSocialData = isWeakSocialOpenGraph(platform, finalUrl, extracted);
    const hasUsefulData = Boolean(extracted.title || extracted.description || extracted.thumbnailUrl);
    const canonicalUrl = weakSocialData && isSocialLoginRedirect(platform, finalUrl)
      ? url.toString()
      : extracted.canonicalUrl ?? finalUrl.toString();

    return {
      url: url.toString(),
      canonicalUrl,
      platform,
      resolver: hasUsefulData ? "opengraph" : "fallback",
      extractionStatus: weakSocialData ? "partial" : hasUsefulData ? "complete" : "partial",
      title: extracted.title,
      description: extracted.description,
      thumbnailUrl: extracted.thumbnailUrl,
      providerName: extracted.providerName ?? finalUrl.hostname,
      needsUserContext: weakSocialData || !hasUsefulData,
      error: weakSocialData ? "weak_social_metadata" : undefined,
    };
  } catch (error) {
    return minimalFallback(url, platform, errorName(error));
  }
}

function extractOpenGraph(html: string, baseUrl: URL): OpenGraphResult {
  const canonicalUrl = linkHref(html, "canonical");
  const title = cleanText(
    metaProperty(html, "og:title") ??
      metaName(html, "twitter:title") ??
      firstMatch(html, /<title[^>]*>([\s\S]*?)<\/title>/i),
  );
  const description = cleanText(
    metaProperty(html, "og:description") ??
      metaName(html, "twitter:description") ??
      metaName(html, "description"),
  );
  const image = metaProperty(html, "og:image") ?? metaName(html, "twitter:image");
  const providerName = cleanText(metaProperty(html, "og:site_name"));

  return {
    canonicalUrl: canonicalUrl ? new URL(decodeHtml(canonicalUrl), baseUrl).toString() : undefined,
    title: title || undefined,
    description: description || undefined,
    thumbnailUrl: image ? new URL(decodeHtml(image), baseUrl).toString() : undefined,
    providerName: providerName || undefined,
  };
}

function isWeakSocialOpenGraph(platform: LinkPlatform, finalUrl: URL, result: OpenGraphResult): boolean {
  if (platform === "generic" || platform === "youtube" || platform === "reddit") {
    return false;
  }

  const title = (result.title ?? "").toLowerCase();
  const description = result.description ?? "";
  const hasUsefulData = Boolean(result.title && (description || result.thumbnailUrl));
  const redirectedToLogin = isSocialLoginRedirect(platform, finalUrl);
  const genericTitle =
    title === "facebook" ||
    title.includes("log in") ||
    title.includes("make your day") ||
    title === "instagram" ||
    title === "x" ||
    title === "twitter";

  return redirectedToLogin || (genericTitle && !hasUsefulData) || !hasUsefulData;
}

export function isSocialLoginRedirect(platform: LinkPlatform, finalUrl: URL): boolean {
  if (platform === "generic" || platform === "youtube" || platform === "reddit") {
    return false;
  }

  return finalUrl.pathname.includes("/login") || finalUrl.pathname.includes("/accounts/login");
}

function minimalFallback(url: URL, platform: LinkPlatform, error?: string): LinkResolverResult {
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

async function fetchWithTimeout(input: URL, init: RequestInit): Promise<Response> {
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
    if (relValue?.toLowerCase().split(/\s+/).includes(rel.toLowerCase()) == true) {
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
    if (attributeValue(tag, "property")?.toLowerCase() === property.toLowerCase()) {
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
    .replace(/&#x([0-9a-f]+);/gi, (_, hex: string) => String.fromCodePoint(Number.parseInt(hex, 16)))
    .replace(/&#([0-9]+);/g, (_, decimal: string) => String.fromCodePoint(Number.parseInt(decimal, 10)))
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", "\"")
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function attributeValue(tag: string, attribute: string): string | null {
  const pattern = new RegExp(`\\b${attribute}\\s*=\\s*(["'])(.*?)\\1`, "i");
  return tag.match(pattern)?.[2] ?? null;
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
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
  if (post.id) {
    return `https://share.redd.it/preview/post/${post.id}`;
  }
  return undefined;
}

function redditDescription(post: RedditPost): string | undefined {
  const parts = [
    post.selftext,
    post.subreddit ? `r/${post.subreddit}` : undefined,
    typeof post.score === "number" ? `${post.score} upvotes` : undefined,
    typeof post.numComments === "number" ? `${post.numComments} comments` : undefined,
  ].filter(Boolean);
  return parts.join(" - ") || undefined;
}

function numberValue(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}
