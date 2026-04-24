import type { LinkPlatform, LinkResolverResult } from "./link_resolver.ts";

export type LinkEnrichmentResult = {
  enabled: boolean;
  attempted: boolean;
  status: "skipped" | "complete" | "partial" | "failed";
  method: "disabled" | "public_html";
  title?: string;
  description?: string;
  authorName?: string;
  authorUrl?: string;
  thumbnailUrl?: string;
  canonicalUrl?: string;
  extractedText?: string;
  error?: string;
};

const htmlFetchHeaders = {
  "accept": "text/html,application/xhtml+xml",
  "user-agent": "DualioBot/0.1 experimental link enrichment",
};

export async function enrichLinkUnofficial(resolved: LinkResolverResult): Promise<LinkEnrichmentResult> {
  if (!isUnofficialEnrichmentEnabled()) {
    return { enabled: false, attempted: false, status: "skipped", method: "disabled" };
  }

  if (!shouldAttemptEnrichment(resolved)) {
    return { enabled: true, attempted: false, status: "skipped", method: "public_html" };
  }

  try {
    const response = await fetchWithTimeout(new URL(resolved.canonicalUrl ?? resolved.url), {
      redirect: "follow",
      headers: htmlFetchHeaders,
    });

    if (!response.ok) {
      return {
        enabled: true,
        attempted: true,
        status: "failed",
        method: "public_html",
        error: `http_${response.status}`,
      };
    }

    const contentType = response.headers.get("content-type") ?? "";
    if (!contentType.includes("text/html") && !contentType.includes("application/xhtml+xml")) {
      return {
        enabled: true,
        attempted: true,
        status: "partial",
        method: "public_html",
        error: "non_html_response",
      };
    }

    const html = await response.text();
    const finalUrl = new URL(response.url);
    const enrichment = extractPublicHtmlContext(html, finalUrl, resolved.platform);
    const hasAnyValue = Boolean(
      enrichment.title ||
        enrichment.description ||
        enrichment.authorName ||
        enrichment.authorUrl ||
        enrichment.thumbnailUrl ||
        enrichment.extractedText,
    );

    return {
      enabled: true,
      attempted: true,
      status: hasAnyValue ? "partial" : "failed",
      method: "public_html",
      ...enrichment,
      error: hasAnyValue ? undefined : "no_extra_context",
    };
  } catch (error) {
    return {
      enabled: true,
      attempted: true,
      status: "failed",
      method: "public_html",
      error: error instanceof Error ? error.name : "unknown_error",
    };
  }
}

export function mergeResolvedLinkWithEnrichment(
  resolved: LinkResolverResult,
  enrichment: LinkEnrichmentResult,
): LinkResolverResult {
  if (enrichment.status === "failed" || enrichment.status === "skipped") {
    return resolved;
  }

  return {
    ...resolved,
    canonicalUrl: enrichment.canonicalUrl ?? resolved.canonicalUrl,
    title: resolved.title ?? enrichment.title,
    description: resolved.description ?? enrichment.description ?? enrichment.extractedText,
    authorName: resolved.authorName ?? enrichment.authorName,
    authorUrl: resolved.authorUrl ?? enrichment.authorUrl,
    thumbnailUrl: resolved.thumbnailUrl ?? enrichment.thumbnailUrl,
  };
}

function isUnofficialEnrichmentEnabled(): boolean {
  return Deno.env.get("ENABLE_UNOFFICIAL_LINK_ENRICHMENT") === "true";
}

function shouldAttemptEnrichment(resolved: LinkResolverResult): boolean {
  if (isSocialPlatform(resolved.platform)) {
    return true;
  }

  if (resolved.needsUserContext) {
    return true;
  }

  if (resolved.extractionStatus !== "complete") {
    return true;
  }

  return !resolved.description || !resolved.authorName;
}

function isSocialPlatform(platform: LinkPlatform): boolean {
  return platform === "tiktok" || platform === "instagram" || platform === "facebook" || platform === "x" || platform === "youtube" || platform === "reddit";
}

function extractPublicHtmlContext(html: string, baseUrl: URL, platform: LinkPlatform): Omit<LinkEnrichmentResult, "enabled" | "attempted" | "status" | "method"> {
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
  const canonical = linkHref(html, "canonical");
  const authorUrl = linkHref(html, "author");
  const authorName = cleanText(
    metaName(html, "author") ??
      metaProperty(html, "article:author") ??
      metaName(html, "twitter:creator"),
  );
  const extractedText = extractJsonLdText(html) ?? extractPlatformTextHint(html, platform);

  return {
    canonicalUrl: canonical ? new URL(decodeHtml(canonical), baseUrl).toString() : undefined,
    title: title || undefined,
    description: description || undefined,
    authorName: authorName || undefined,
    authorUrl: authorUrl ? new URL(decodeHtml(authorUrl), baseUrl).toString() : undefined,
    thumbnailUrl: image ? new URL(decodeHtml(image), baseUrl).toString() : undefined,
    extractedText: extractedText || undefined,
  };
}

function extractJsonLdText(html: string): string | undefined {
  const matches = html.matchAll(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi);
  for (const match of matches) {
    try {
      const parsed = JSON.parse(decodeHtml(match[1]));
      const text = findFirstStringValue(parsed, ["articleBody", "description", "caption", "text"]);
      if (text) {
        return cleanText(text).slice(0, 2000);
      }
    } catch {
      // Some platforms emit invalid or escaped JSON-LD; skip it.
    }
  }
  return undefined;
}

function extractPlatformTextHint(html: string, platform: LinkPlatform): string | undefined {
  if (platform === "generic") {
    return undefined;
  }

  const text = cleanText(stripTags(html))
    .replace(/\s+/g, " ")
    .slice(0, 2000);
  return text.length > 80 ? text : undefined;
}

function findFirstStringValue(value: unknown, keys: string[]): string | undefined {
  if (typeof value === "string") {
    return undefined;
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findFirstStringValue(item, keys);
      if (found) {
        return found;
      }
    }
    return undefined;
  }

  if (!value || typeof value !== "object") {
    return undefined;
  }

  const objectValue = value as Record<string, unknown>;
  for (const key of keys) {
    const candidate = objectValue[key];
    if (typeof candidate === "string" && candidate.trim().length > 0) {
      return candidate;
    }
  }

  for (const candidate of Object.values(objectValue)) {
    const found = findFirstStringValue(candidate, keys);
    if (found) {
      return found;
    }
  }

  return undefined;
}

async function fetchWithTimeout(input: URL, init: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);
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

function stripTags(value: string): string {
  return value.replace(/<script[\s\S]*?<\/script>/gi, " ").replace(/<style[\s\S]*?<\/style>/gi, " ").replace(/<[^>]+>/g, " ");
}

function cleanText(value: string | null | undefined): string {
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
