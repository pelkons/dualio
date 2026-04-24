type ProcessItemRequest = {
  item_id: string;
  retry?: boolean;
};

type PipelineStage =
  | "fetch_item"
  | "normalize_source"
  | "extract_text"
  | "detect_type"
  | "extract_fields"
  | "summarize"
  | "extract_entities"
  | "generate_aliases"
  | "chunk"
  | "embed_item"
  | "embed_chunks"
  | "store_assets"
  | "mark_ready";

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stages: PipelineStage[] = [
  "fetch_item",
  "normalize_source",
  "extract_text",
  "detect_type",
  "extract_fields",
  "summarize",
  "extract_entities",
  "generate_aliases",
  "chunk",
  "embed_item",
  "embed_chunks",
  "store_assets",
  "mark_ready",
];

type ItemRow = {
  id: string;
  user_id: string;
  source_url: string | null;
  source_type: "link" | "screenshot" | "photo" | "text";
  raw_content: Record<string, unknown>;
  title: string;
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  const body = (await request.json()) as ProcessItemRequest;

  if (!body.item_id) {
    return Response.json({ error: "item_id is required" }, { status: 400 });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseAnonKey) {
    return Response.json({ error: "supabase_env_missing" }, { status: 500 });
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });

  logStage(body.item_id, "fetch_item", "started");
  const { data: item, error: fetchError } = await supabase
    .from("items")
    .select("id,user_id,source_url,source_type,raw_content,title")
    .eq("id", body.item_id)
    .single<ItemRow>();

  if (fetchError || !item) {
    logStage(body.item_id, "fetch_item", "failed", fetchError?.code);
    return Response.json({ error: "item_not_found" }, { status: 404 });
  }
  logStage(body.item_id, "fetch_item", "completed");

  if (item.source_type !== "link" || !item.source_url) {
    await markReadyWithoutProcessing(supabase, item);
    return Response.json({ item_id: item.id, status: "ready", processed: false });
  }

  logStage(item.id, "normalize_source", "started");
  const normalizedUrl = normalizeUrl(item.source_url);
  if (!normalizedUrl) {
    await markFailed(supabase, item.id, "Invalid source URL.");
    logStage(item.id, "normalize_source", "failed", "invalid_url");
    return Response.json({ error: "invalid_url" }, { status: 400 });
  }
  logStage(item.id, "normalize_source", "completed");

  await supabase.from("items").update({ processing_status: "processing" }).eq("id", item.id);

  try {
    logStage(item.id, "extract_text", "started");
    const metadata = await fetchLinkMetadata(normalizedUrl);
    logStage(item.id, "extract_text", "completed");

    const title = metadata.title || item.title || normalizedUrl.hostname;
    const summary = metadata.description || metadata.siteName || normalizedUrl.hostname;
    const aliases = buildAliases(title, metadata.siteName, normalizedUrl.hostname);
    const rawContentExpiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString();

    logStage(item.id, "extract_fields", "started");
    const update = {
      type: "article",
      source_url: normalizedUrl.toString(),
      raw_content: {
        sourceType: "link",
        url: normalizedUrl.toString(),
        fetchedAt: new Date().toISOString(),
        metadata,
      },
      parsed_content: {
        kind: "link_preview",
        url: normalizedUrl.toString(),
        title,
        description: metadata.description,
        siteName: metadata.siteName,
        image: metadata.image,
      },
      title,
      thumbnail_url: metadata.image,
      searchable_summary: summary,
      searchable_aliases: aliases,
      processing_status: "ready",
      raw_content_expires_at: rawContentExpiresAt,
      raw_content_retention_reason: "link_metadata_retry_window",
      updated_at: new Date().toISOString(),
    };
    logStage(item.id, "extract_fields", "completed");

    logStage(item.id, "mark_ready", "started");
    const { error: updateError } = await supabase.from("items").update(update).eq("id", item.id);
    if (updateError) {
      throw updateError;
    }
    logStage(item.id, "mark_ready", "completed");

    return Response.json({
      item_id: item.id,
      status: "ready",
      processed: true,
      title,
    });
  } catch (error) {
    await markFailed(supabase, item.id, "Could not process this link.");
    logStage(item.id, "mark_ready", "failed", error instanceof Error ? error.name : "unknown");
    return Response.json({ error: "process_failed" }, { status: 500 });
  }
});

function logStage(itemId: string, stage: PipelineStage, status: "started" | "completed" | "failed", reason?: string) {
  console.info(JSON.stringify({ item_id: itemId, stage, status, reason }));
}

function normalizeUrl(value: string): URL | null {
  try {
    const url = new URL(value.trim());
    if (url.protocol !== "http:" && url.protocol !== "https:") {
      return null;
    }
    return url;
  } catch {
    return null;
  }
}

async function fetchLinkMetadata(url: URL) {
  const response = await fetch(url, {
    redirect: "follow",
    headers: {
      "accept": "text/html,application/xhtml+xml",
      "user-agent": "DualioBot/0.1 link metadata fetcher",
    },
  });

  if (!response.ok) {
    throw new Error(`fetch_failed_${response.status}`);
  }

  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("text/html") && !contentType.includes("application/xhtml+xml")) {
    return {
      finalUrl: response.url,
      title: url.hostname,
      description: "",
      siteName: url.hostname,
      image: null,
      contentType,
    };
  }

  const html = await response.text();
  const baseUrl = new URL(response.url);
  const title = cleanText(firstMatch(html, /<title[^>]*>([\s\S]*?)<\/title>/i));
  const description = metaContent(html, "description") ?? metaProperty(html, "og:description") ?? metaName(html, "twitter:description");
  const image = metaProperty(html, "og:image") ?? metaName(html, "twitter:image");
  const siteName = metaProperty(html, "og:site_name") ?? baseUrl.hostname;

  return {
    finalUrl: baseUrl.toString(),
    title: title || cleanText(metaProperty(html, "og:title") ?? metaName(html, "twitter:title") ?? ""),
    description: cleanText(description ?? ""),
    siteName: cleanText(siteName),
    image: image ? new URL(decodeHtml(image), baseUrl).toString() : null,
    contentType,
  };
}

function metaContent(html: string, name: string): string | null {
  return metaName(html, name) ?? metaProperty(html, name);
}

function metaName(html: string, name: string): string | null {
  const pattern = new RegExp(`<meta[^>]+name=["']${escapeRegExp(name)}["'][^>]+content=["']([^"']*)["'][^>]*>`, "i");
  return firstMatch(html, pattern);
}

function metaProperty(html: string, property: string): string | null {
  const pattern = new RegExp(`<meta[^>]+property=["']${escapeRegExp(property)}["'][^>]+content=["']([^"']*)["'][^>]*>`, "i");
  return firstMatch(html, pattern);
}

function firstMatch(value: string, pattern: RegExp): string | null {
  return value.match(pattern)?.[1] ?? null;
}

function cleanText(value: string | null): string {
  return decodeHtml(value ?? "").replace(/\s+/g, " ").trim();
}

function decodeHtml(value: string): string {
  return value
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", "\"")
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function buildAliases(title: string, siteName: string | null, hostname: string): string[] {
  return [...new Set([title, siteName, hostname].filter(Boolean).flatMap((value) => value!.toLowerCase().split(/[\s,.;:!?/|-]+/)).filter((word) => word.length > 3).slice(0, 12))];
}

async function markReadyWithoutProcessing(supabase: ReturnType<typeof createClient>, item: ItemRow) {
  await supabase
    .from("items")
    .update({
      processing_status: "ready",
      raw_content_expires_at: new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString(),
      raw_content_retention_reason: "non_link_passthrough",
      updated_at: new Date().toISOString(),
    })
    .eq("id", item.id);
}

async function markFailed(supabase: ReturnType<typeof createClient>, itemId: string, message: string) {
  await supabase
    .from("items")
    .update({
      processing_status: "failed",
      clarification_question: message,
      raw_content_expires_at: new Date(Date.now() + 1000 * 60 * 60).toISOString(),
      raw_content_retention_reason: "failed_processing_retry_window",
      updated_at: new Date().toISOString(),
    })
    .eq("id", itemId);
}
