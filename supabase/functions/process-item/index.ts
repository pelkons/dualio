type ProcessItemRequest = {
  item_id: string;
  retry?: boolean;
};

type PipelineStage =
  | "fetch_item"
  | "normalize_source"
  | "resolve_link"
  | "enrich_link"
  | "extract_fields"
  | "mark_ready";

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { enrichLinkUnofficial, mergeResolvedLinkWithEnrichment } from "../_shared/link_enrichment.ts";
import { type LinkPlatform, type LinkResolverResult, normalizeLinkUrl, resolveLink } from "../_shared/link_resolver.ts";

type ItemRow = {
  id: string;
  user_id: string;
  source_url: string | null;
  source_type: "link" | "screenshot" | "photo" | "text";
  processing_status: "pending" | "processing" | "ready" | "needs_clarification" | "failed";
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
    .select("id,user_id,source_url,source_type,processing_status,raw_content,title")
    .eq("id", body.item_id)
    .single<ItemRow>();

  if (fetchError || !item) {
    logStage(body.item_id, "fetch_item", "failed", fetchError?.code);
    return Response.json({ error: "item_not_found" }, { status: 404 });
  }
  logStage(body.item_id, "fetch_item", "completed");

  if (item.processing_status === "ready" && !body.retry) {
    return Response.json({ item_id: item.id, status: "ready", processed: false, idempotent: true });
  }

  if (item.source_type !== "link" || !item.source_url) {
    await markReadyWithoutProcessing(supabase, item);
    return Response.json({ item_id: item.id, status: "ready", processed: false });
  }

  logStage(item.id, "normalize_source", "started");
  const normalizedUrl = normalizeLinkUrl(item.source_url);
  if (!normalizedUrl) {
    await markFailed(supabase, item.id, "Invalid source URL.");
    logStage(item.id, "normalize_source", "failed", "invalid_url");
    return Response.json({ error: "invalid_url" }, { status: 400 });
  }
  logStage(item.id, "normalize_source", "completed");

  await supabase.from("items").update({ processing_status: "processing" }).eq("id", item.id);

  try {
    logStage(item.id, "resolve_link", "started");
    const resolvedLink = await resolveLink(normalizedUrl.toString());
    logStage(item.id, "resolve_link", "completed");

    logStage(item.id, "enrich_link", "started");
    const enrichment = await enrichLinkUnofficial(resolvedLink);
    const enrichedLink = mergeResolvedLinkWithEnrichment(resolvedLink, enrichment);
    logStage(item.id, "enrich_link", "completed", enrichment.status);

    const decision = decideLinkProcessing(enrichedLink);
    const title = enrichedLink.title || item.title || normalizedUrl.hostname;
    const summary = enrichedLink.description || enrichedLink.providerName || enrichedLink.platform || normalizedUrl.hostname;
    const aliases = buildAliases(title, enrichedLink.providerName, enrichedLink.authorName, normalizedUrl.hostname);
    const readMinutes = estimateReadMinutes(summary);
    const rawContentExpiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString();

    logStage(item.id, "extract_fields", "started");
    const parsedContent = decision.uiKind === "restricted_social_link"
      ? {
        kind: "restricted_social_link",
        platform: enrichedLink.platform,
        url: normalizedUrl.toString(),
        title,
        siteName: enrichedLink.providerName,
        canonicalUrl: enrichedLink.canonicalUrl,
        resolver: enrichedLink.resolver,
        sourcePlatform: enrichedLink.platform,
        extractionQuality: decision.extractionQuality,
        enrichmentStatus: enrichment.status,
        canonicalDataPath: "raw_content.resolved_link",
      }
      : {
        kind: "link_preview",
        sourcePlatform: enrichedLink.platform,
        url: enrichedLink.canonicalUrl ?? normalizedUrl.toString(),
        title,
        description: enrichedLink.description,
        authorName: enrichedLink.authorName,
        authorUrl: enrichedLink.authorUrl,
        siteName: enrichedLink.providerName,
        image: enrichedLink.thumbnailUrl,
        htmlEmbed: enrichedLink.htmlEmbed,
        resolver: enrichedLink.resolver,
        extractionQuality: decision.extractionQuality,
        enrichmentStatus: enrichment.status,
        canonicalDataPath: "raw_content.resolved_link",
        readMinutes,
      };

    const update = {
      type: decision.itemType,
      source_url: enrichedLink.canonicalUrl ?? normalizedUrl.toString(),
      raw_content: {
        sourceType: "link",
        url: normalizedUrl.toString(),
        fetchedAt: new Date().toISOString(),
        resolved_link: enrichedLink,
        official_resolved_link: resolvedLink,
        experimental_enrichment: enrichment,
      },
      parsed_content: parsedContent,
      title,
      thumbnail_url: enrichedLink.thumbnailUrl,
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

type LinkProcessingDecision = {
  itemType: "article" | "video" | "unknown";
  uiKind: "link_preview" | "restricted_social_link";
  extractionQuality: "complete" | "partial_needs_context";
};

function decideLinkProcessing(link: LinkResolverResult): LinkProcessingDecision {
  if (shouldShowRestrictedLink(link)) {
    return {
      itemType: "unknown",
      uiKind: "restricted_social_link",
      extractionQuality: "partial_needs_context",
    };
  }

  if (link.platform === "tiktok" || link.platform === "youtube") {
    return {
      itemType: "video",
      uiKind: "link_preview",
      extractionQuality: link.needsUserContext ? "partial_needs_context" : "complete",
    };
  }

  return {
    itemType: "article",
    uiKind: "link_preview",
    extractionQuality: link.needsUserContext ? "partial_needs_context" : "complete",
  };
}

function shouldShowRestrictedLink(link: LinkResolverResult): boolean {
  const hasUsefulPreview = Boolean(link.title && (link.description || link.thumbnailUrl || link.authorName || link.htmlEmbed));
  return link.needsUserContext && !hasUsefulPreview;
}

function logStage(itemId: string, stage: PipelineStage, status: "started" | "completed" | "failed", reason?: string) {
  console.info(JSON.stringify({ item_id: itemId, stage, status, reason }));
}

function buildAliases(title: string, siteName: string | undefined, authorName: string | undefined, hostname: string): string[] {
  return [...new Set([title, siteName, authorName, hostname].filter(Boolean).flatMap((value) => value!.toLowerCase().split(/[\s,.;:!?/|-]+/)).filter((word) => word.length > 3).slice(0, 12))];
}

function estimateReadMinutes(text: string): number {
  const wordCount = text.split(/\s+/).filter((word) => word.length > 0).length;
  return Math.max(1, Math.ceil(wordCount / 220));
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
