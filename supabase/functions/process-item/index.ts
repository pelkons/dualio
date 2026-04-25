type ProcessItemRequest = {
  item_id: string;
  retry?: boolean;
};

type PipelineStage =
  | "fetch_item"
  | "normalize_source"
  | "resolve_link"
  | "enrich_link"
  | "resolve_asset"
  | "analyze_image"
  | "write_search_docs"
  | "extract_fields"
  | "mark_ready";

import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type EmbeddingGenerationStatus,
  embeddingToPgVector,
  generateEmbeddings,
} from "../_shared/embeddings.ts";
import {
  enrichLinkUnofficial,
  mergeResolvedLinkWithEnrichment,
} from "../_shared/link_enrichment.ts";
import {
  type LinkPlatform,
  type LinkResolverResult,
  normalizeLinkUrl,
  resolveLink,
} from "../_shared/link_resolver.ts";
import {
  extractSemanticItem,
  type SemanticContentType,
  type SemanticExtraction,
} from "../_shared/semantic_extraction.ts";
import { callOpenRouterStructuredJson } from "../_shared/openrouter.ts";

type SupabaseClient = any;

type ItemRow = {
  id: string;
  user_id: string;
  source_url: string | null;
  source_type: "link" | "screenshot" | "photo" | "text";
  processing_status:
    | "pending"
    | "processing"
    | "ready"
    | "needs_clarification"
    | "failed";
  raw_content: Record<string, unknown>;
  parsed_content: Record<string, unknown> | null;
  title: string;
  thumbnail_url: string | null;
};

type ItemAssetRow = {
  storage_bucket: string;
  storage_key: string;
  content_type: string | null;
  byte_size: number | null;
  original_filename: string | null;
};

type ImageAnalysis = {
  title: string;
  summary: string;
  contentType:
    | "recipe"
    | "film"
    | "place"
    | "article"
    | "product"
    | "video"
    | "manual"
    | "note"
    | "unknown";
  language: string;
  visibleText: string;
  aliases: string[];
  entities: Array<{
    entity: string;
    entityType: string;
    normalizedValue: string;
    metadata?: Record<string, unknown>;
  }>;
  chunks: Array<{
    chunkType: string;
    content: string;
    metadata?: Record<string, unknown>;
  }>;
  needsClarification: boolean;
  clarificationQuestion?: string;
  analysisStatus: "complete" | "partial" | "vision_disabled" | "failed";
  model?: string;
};

type SearchDocsAnalysis = {
  chunks: Array<{
    chunkType: string;
    content: string;
    metadata?: Record<string, unknown>;
  }>;
  entities: Array<{
    entity: string;
    entityType: string;
    normalizedValue: string;
    metadata?: Record<string, unknown>;
  }>;
};

type SearchDocsWriteResult = {
  chunkCount: number;
  embeddedChunkCount: number;
  itemEmbedded: boolean;
  embeddingStatus: EmbeddingGenerationStatus;
  embeddingModel?: string;
  embeddingError?: string;
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
    .select(
      "id,user_id,source_url,source_type,processing_status,raw_content,parsed_content,title,thumbnail_url",
    )
    .eq("id", body.item_id)
    .single<ItemRow>();

  if (fetchError || !item) {
    logStage(body.item_id, "fetch_item", "failed", fetchError?.code);
    return Response.json({ error: "item_not_found" }, { status: 404 });
  }
  logStage(body.item_id, "fetch_item", "completed");

  if (item.processing_status === "ready" && !body.retry) {
    return Response.json({
      item_id: item.id,
      status: "ready",
      processed: false,
      idempotent: true,
    });
  }

  await supabase.from("items").update({ processing_status: "processing" }).eq(
    "id",
    item.id,
  );

  if ((item.source_type === "photo" || item.source_type === "screenshot")) {
    return await processImageItem(supabase, item);
  }

  if (item.source_type === "text") {
    return await processTextItem(supabase, item);
  }

  if (item.source_type !== "link" || !item.source_url) {
    await markReadyWithoutProcessing(
      supabase,
      item,
      "unsupported_source_passthrough",
    );
    return Response.json({
      item_id: item.id,
      status: "ready",
      processed: false,
    });
  }

  logStage(item.id, "normalize_source", "started");
  const normalizedUrl = normalizeLinkUrl(item.source_url);
  if (!normalizedUrl) {
    await markFailed(supabase, item.id, "Invalid source URL.");
    logStage(item.id, "normalize_source", "failed", "invalid_url");
    return Response.json({ error: "invalid_url" }, { status: 400 });
  }
  logStage(item.id, "normalize_source", "completed");

  try {
    logStage(item.id, "resolve_link", "started");
    const resolvedLink = await resolveLink(normalizedUrl.toString());
    logStage(item.id, "resolve_link", "completed");

    logStage(item.id, "enrich_link", "started");
    const enrichment = await enrichLinkUnofficial(resolvedLink);
    const enrichedLink = mergeResolvedLinkWithEnrichment(
      resolvedLink,
      enrichment,
    );
    logStage(item.id, "enrich_link", "completed", enrichment.status);

    const decision = decideLinkProcessing(enrichedLink);
    const rawContentExpiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24)
      .toISOString();

    logStage(item.id, "extract_fields", "started");
    const fallbackTitle = enrichedLink.title || item.title ||
      normalizedUrl.hostname;
    const fallbackSummary = enrichedLink.description ||
      enrichedLink.providerName || enrichedLink.platform ||
      normalizedUrl.hostname;
    const extraction = await extractSemanticItem({
      sourceType: "link",
      url: enrichedLink.canonicalUrl ?? normalizedUrl.toString(),
      title: fallbackTitle,
      summary: fallbackSummary,
      fallbackContentType: decision.itemType,
      resolvedLink: enrichedLink,
    });
    const isRestrictedSocialLink = decision.uiKind === "restricted_social_link";
    const itemType = isRestrictedSocialLink
      ? "unknown"
      : extraction.contentType === "unknown"
      ? decision.itemType
      : extraction.contentType;
    const title = extraction.title || fallbackTitle;
    const summary = extraction.summary || fallbackSummary;
    const aliases = mergeAliases(
      buildAliases(
        title,
        enrichedLink.providerName,
        enrichedLink.authorName,
        normalizedUrl.hostname,
      ),
      extraction.aliases,
    );
    const parsedContent = buildLinkParsedContent({
      item,
      normalizedUrl,
      link: enrichedLink,
      enrichmentStatus: enrichment.status,
      decision,
      extraction,
      itemType,
      title,
      summary,
    });
    logStage(
      item.id,
      "extract_fields",
      "completed",
      extraction.extractionStatus,
    );

    logStage(item.id, "write_search_docs", "started");
    const searchDocs = await replaceSearchDocs(
      supabase,
      item,
      extraction,
      title,
      summary,
      "link_text_ai",
    );
    logStage(
      item.id,
      "write_search_docs",
      "completed",
      searchDocs.embeddingStatus,
    );

    const update = {
      type: itemType,
      source_url: enrichedLink.canonicalUrl ?? normalizedUrl.toString(),
      raw_content: {
        sourceType: "link",
        url: normalizedUrl.toString(),
        fetchedAt: new Date().toISOString(),
        resolved_link: enrichedLink,
        official_resolved_link: resolvedLink,
        experimental_enrichment: enrichment,
        semanticExtraction: {
          status: extraction.extractionStatus,
          model: extraction.model,
        },
        searchDocs,
      },
      parsed_content: parsedContent,
      title,
      thumbnail_url: enrichedLink.thumbnailUrl,
      searchable_summary: summary,
      searchable_aliases: aliases,
      language: extraction.language,
      processing_status: extraction.needsClarification
        ? "needs_clarification"
        : "ready",
      clarification_question: extraction.needsClarification
        ? (extraction.clarificationQuestion ||
          "What should Dualio remember about this link?")
        : null,
      raw_content_expires_at: rawContentExpiresAt,
      raw_content_retention_reason: "link_metadata_retry_window",
      updated_at: new Date().toISOString(),
    };

    logStage(item.id, "mark_ready", "started");
    const { error: updateError } = await supabase.from("items").update(update)
      .eq("id", item.id);
    if (updateError) {
      throw updateError;
    }
    logStage(item.id, "mark_ready", "completed");

    return Response.json({
      item_id: item.id,
      status: update.processing_status,
      processed: true,
      title,
    });
  } catch (error) {
    await markFailed(supabase, item.id, "Could not process this link.");
    logStage(
      item.id,
      "mark_ready",
      "failed",
      error instanceof Error ? error.name : "unknown",
    );
    return Response.json({ error: "process_failed" }, { status: 500 });
  }
});

async function processTextItem(
  supabase: SupabaseClient,
  item: ItemRow,
): Promise<Response> {
  try {
    const rawText = textFromItem(item);
    logStage(item.id, "extract_fields", "started");
    const extraction = await extractSemanticItem({
      sourceType: "text",
      text: rawText,
      title: item.title,
      fallbackContentType: "note",
      userNote: stringField(item.parsed_content ?? {}, "userNote"),
    });
    const title = extraction.title || item.title || "Saved note";
    const summary = extraction.summary || rawText || "Saved note";
    const aliases = mergeAliases(
      buildAliases(title, undefined, undefined, summary),
      extraction.aliases,
    );
    const parsedContent = buildTextParsedContent(
      item,
      extraction,
      title,
      summary,
      rawText,
    );
    logStage(
      item.id,
      "extract_fields",
      "completed",
      extraction.extractionStatus,
    );

    logStage(item.id, "write_search_docs", "started");
    const searchDocs = await replaceSearchDocs(
      supabase,
      item,
      extraction,
      title,
      summary,
      "text_ai",
    );
    logStage(
      item.id,
      "write_search_docs",
      "completed",
      searchDocs.embeddingStatus,
    );

    logStage(item.id, "mark_ready", "started");
    const update = {
      type: extraction.contentType,
      title,
      parsed_content: parsedContent,
      searchable_summary: summary,
      searchable_aliases: aliases,
      language: extraction.language,
      processing_status: extraction.needsClarification
        ? "needs_clarification"
        : "ready",
      clarification_question: extraction.needsClarification
        ? (extraction.clarificationQuestion ||
          "What should Dualio remember about this text?")
        : null,
      raw_content: {
        ...(item.raw_content ?? {}),
        sourceType: "text",
        processedAt: new Date().toISOString(),
        semanticExtraction: {
          status: extraction.extractionStatus,
          model: extraction.model,
        },
        searchDocs,
      },
      raw_content_expires_at: new Date(Date.now() + 1000 * 60 * 60 * 24)
        .toISOString(),
      raw_content_retention_reason: "text_input_retry_window",
      updated_at: new Date().toISOString(),
    };
    const { error: updateError } = await supabase.from("items").update(update)
      .eq("id", item.id);
    if (updateError) {
      throw updateError;
    }
    logStage(item.id, "mark_ready", "completed");

    return Response.json({
      item_id: item.id,
      status: update.processing_status,
      processed: true,
      title,
      extraction_status: extraction.extractionStatus,
    });
  } catch (error) {
    await markFailed(supabase, item.id, "Could not process this text.");
    logStage(
      item.id,
      "mark_ready",
      "failed",
      error instanceof Error ? error.message : "unknown",
    );
    return Response.json({ error: "text_process_failed" }, { status: 500 });
  }
}

async function processImageItem(
  supabase: SupabaseClient,
  item: ItemRow,
): Promise<Response> {
  try {
    logStage(item.id, "resolve_asset", "started");
    const asset = await findImageAsset(supabase, item);
    if (!asset) {
      await markFailed(supabase, item.id, "Image upload is not available yet.");
      logStage(item.id, "resolve_asset", "failed", "missing_asset");
      return Response.json({ error: "missing_asset" }, { status: 422 });
    }

    const imageUrl = await createR2ReadUrl(
      asset.storage_bucket,
      asset.storage_key,
      60 * 20,
    );
    logStage(item.id, "resolve_asset", "completed");

    logStage(item.id, "analyze_image", "started");
    const analysis = await analyzeImageWithVision({
      imageUrl,
      sourceType: item.source_type === "photo" ? "photo" : "screenshot",
      fallbackTitle: titleFromFilename(asset.original_filename || item.title),
    });
    logStage(item.id, "analyze_image", "completed", analysis.analysisStatus);

    const title = analysis.title ||
      titleFromFilename(asset.original_filename || item.title);
    const summary = analysis.summary || analysis.visibleText || "Saved image";
    const aliases = [
      ...buildAliases(
        title,
        undefined,
        undefined,
        asset.original_filename || item.title,
      ),
      ...analysis.aliases,
    ].filter((value, index, values) => value && values.indexOf(value) === index)
      .slice(0, 24);
    const parsedContent = {
      ...(item.parsed_content ?? {}),
      kind: "image_analysis",
      sourceType: item.source_type,
      title,
      summary,
      visibleText: analysis.visibleText,
      contentType: analysis.contentType,
      analysisStatus: analysis.analysisStatus,
      asset: {
        provider: "cloudflare_r2",
        bucket: asset.storage_bucket,
        key: asset.storage_key,
        contentType: asset.content_type,
        byteSize: asset.byte_size,
        originalFilename: asset.original_filename,
      },
    };

    logStage(item.id, "write_search_docs", "started");
    const searchDocs = await replaceSearchDocs(
      supabase,
      item,
      analysis,
      title,
      summary,
    );
    logStage(
      item.id,
      "write_search_docs",
      "completed",
      searchDocs.embeddingStatus,
    );

    logStage(item.id, "mark_ready", "started");
    const update = {
      type: analysis.contentType,
      title,
      parsed_content: parsedContent,
      searchable_summary: summary,
      searchable_aliases: aliases,
      processing_status: analysis.needsClarification
        ? "needs_clarification"
        : "ready",
      clarification_question: analysis.needsClarification
        ? (analysis.clarificationQuestion ||
          "What should Dualio remember about this image?")
        : null,
      raw_content: {
        sourceType: item.source_type,
        processedAt: new Date().toISOString(),
        asset: {
          provider: "cloudflare_r2",
          bucket: asset.storage_bucket,
          key: asset.storage_key,
          contentType: asset.content_type,
          byteSize: asset.byte_size,
          originalFilename: asset.original_filename,
        },
        imageAnalysis: {
          status: analysis.analysisStatus,
          model: analysis.model,
        },
        searchDocs,
      },
      raw_content_expires_at: new Date(Date.now() + 1000 * 60 * 60)
        .toISOString(),
      raw_content_retention_reason: "image_asset_metadata_only",
      updated_at: new Date().toISOString(),
    };
    const { error: updateError } = await supabase.from("items").update(update)
      .eq("id", item.id);
    if (updateError) {
      throw updateError;
    }
    logStage(item.id, "mark_ready", "completed");

    return Response.json({
      item_id: item.id,
      status: update.processing_status,
      processed: true,
      title,
      analysis_status: analysis.analysisStatus,
    });
  } catch (error) {
    await markFailed(supabase, item.id, "Could not process this image.");
    logStage(
      item.id,
      "mark_ready",
      "failed",
      error instanceof Error ? error.message : "unknown",
    );
    return Response.json({ error: "image_process_failed" }, { status: 500 });
  }
}

type LinkProcessingDecision = {
  itemType: SemanticContentType;
  uiKind: "link_preview" | "restricted_social_link";
  extractionQuality: "complete" | "partial_needs_context";
};

function decideLinkProcessing(
  link: LinkResolverResult,
): LinkProcessingDecision {
  if (link.structuredData?.recipe) {
    return {
      itemType: "recipe",
      uiKind: "link_preview",
      extractionQuality: "complete",
    };
  }

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
      extractionQuality: link.needsUserContext
        ? "partial_needs_context"
        : "complete",
    };
  }

  return {
    itemType: "article",
    uiKind: "link_preview",
    extractionQuality: link.needsUserContext
      ? "partial_needs_context"
      : "complete",
  };
}

function shouldShowRestrictedLink(link: LinkResolverResult): boolean {
  const hasUsefulPreview = Boolean(
    link.title &&
      (link.description || link.thumbnailUrl || link.authorName ||
        link.htmlEmbed),
  );
  return link.needsUserContext && !hasUsefulPreview;
}

function buildLinkParsedContent(input: {
  item: ItemRow;
  normalizedUrl: URL;
  link: LinkResolverResult;
  enrichmentStatus: string;
  decision: LinkProcessingDecision;
  extraction: SemanticExtraction;
  itemType: SemanticContentType;
  title: string;
  summary: string;
}): Record<string, unknown> {
  const readMinutes =
    numberField(input.extraction.structuredFields, "readMinutes") ??
      estimateReadMinutes(input.summary);
  const base = {
    ...(input.item.parsed_content ?? {}),
    kind: input.decision.uiKind === "restricted_social_link"
      ? "restricted_social_link"
      : input.itemType,
    sourcePlatform: input.link.platform,
    platform: input.link.platform,
    url: input.link.canonicalUrl ?? input.normalizedUrl.toString(),
    title: input.title,
    summary: input.summary,
    description: input.link.description,
    authorName: input.link.authorName ??
      stringField(input.extraction.structuredFields, "authorName"),
    authorUrl: input.link.authorUrl,
    siteName: input.link.providerName ??
      stringField(input.extraction.structuredFields, "siteName"),
    image: input.link.thumbnailUrl,
    htmlEmbed: input.link.htmlEmbed,
    resolver: input.link.resolver,
    extractionQuality: input.decision.extractionQuality,
    extractionStatus: input.extraction.extractionStatus,
    enrichmentStatus: input.enrichmentStatus,
    canonicalDataPath: "raw_content.resolved_link",
    readMinutes,
    structuredFields: input.extraction.structuredFields,
  };

  if (input.decision.uiKind === "restricted_social_link") {
    return base;
  }

  return withTypeSpecificFields(
    base,
    input.itemType,
    input.extraction,
    input.summary,
    input.link,
  );
}

function buildTextParsedContent(
  item: ItemRow,
  extraction: SemanticExtraction,
  title: string,
  summary: string,
  rawText: string,
): Record<string, unknown> {
  const base = {
    ...(item.parsed_content ?? {}),
    kind: extraction.contentType,
    title,
    summary,
    rawText,
    extractionStatus: extraction.extractionStatus,
    structuredFields: extraction.structuredFields,
  };
  return withTypeSpecificFields(
    base,
    extraction.contentType,
    extraction,
    summary,
  );
}

function withTypeSpecificFields(
  base: Record<string, unknown>,
  itemType: SemanticContentType,
  extraction: SemanticExtraction,
  summary: string,
  link?: LinkResolverResult,
): Record<string, unknown> {
  const fields = extraction.structuredFields;
  switch (itemType) {
    case "recipe":
      return {
        ...base,
        prepTime: stringField(fields, "prepTime") || "Time unknown",
        cookTime: stringField(fields, "cookTime") || undefined,
        totalTime: stringField(fields, "totalTime") || undefined,
        recipeYield: stringField(fields, "recipeYield") || undefined,
        difficulty: stringField(fields, "difficulty") || "Difficulty unknown",
        ingredients: stringArrayField(fields, "ingredients"),
        steps: stringArrayField(fields, "steps"),
      };
    case "film":
      return {
        ...base,
        year: stringField(fields, "year") || "Year unknown",
        director: stringField(fields, "director") || "Unknown director",
        rating: stringField(fields, "rating") || "Unrated",
        synopsis: stringField(fields, "synopsis") || summary,
        cast: stringArrayField(fields, "cast"),
      };
    case "place":
      return {
        ...base,
        address: stringField(fields, "address") || "Address unavailable",
        venueType: stringField(fields, "venueType") || "Place",
        hours: stringField(fields, "hours") || "Hours unavailable",
        notes: stringField(fields, "notes") || summary,
      };
    case "product":
      return {
        ...base,
        price: stringField(fields, "price") || "Price unavailable",
        store: stringField(fields, "store") || link?.providerName ||
          "Store unavailable",
        specs: stringArrayField(fields, "specs"),
      };
    case "video":
      return {
        ...base,
        authorName: (link?.authorName ?? stringField(fields, "authorName")) ||
          base.authorName,
        siteName: (link?.providerName ?? stringField(fields, "siteName")) ||
          base.siteName,
        duration: stringField(fields, "duration") || undefined,
      };
    case "manual":
      return {
        ...base,
        authorName: (link?.authorName ?? stringField(fields, "authorName")) ||
          base.authorName,
        siteName: (link?.providerName ?? stringField(fields, "siteName")) ||
          base.siteName,
        materials: stringArrayField(fields, "materials").length
          ? stringArrayField(fields, "materials")
          : [
            ...stringArrayField(fields, "tools"),
            ...stringArrayField(fields, "requirements"),
          ],
        steps: stringArrayField(fields, "steps"),
        body: stringField(fields, "body") || summary,
      };
    case "article":
      return {
        ...base,
        author: stringField(fields, "author") || link?.authorName,
        authorName: (link?.authorName ?? stringField(fields, "authorName")) ||
          base.authorName,
        siteName: (link?.providerName ?? stringField(fields, "siteName")) ||
          base.siteName,
        readMinutes: numberField(fields, "readMinutes") ?? base.readMinutes ??
          estimateReadMinutes(summary),
        body: stringField(fields, "body") || summary,
      };
    case "note":
      return {
        ...base,
        author: stringField(fields, "author") || undefined,
        body: stringField(fields, "body") || summary,
      };
    case "unknown":
      return base;
  }
}

function mergeAliases(primary: string[], secondary: string[]): string[] {
  return [
    ...new Set(
      [...primary, ...secondary].map((alias) => alias.toLowerCase()).filter(
        Boolean,
      ),
    ),
  ].slice(0, 32);
}

function textFromItem(item: ItemRow): string {
  return stringField(item.raw_content ?? {}, "input") ||
    stringField(item.parsed_content ?? {}, "rawText") ||
    item.title;
}

function stringField(source: Record<string, unknown>, key: string): string {
  return cleanText(source[key]);
}

function numberField(
  source: Record<string, unknown>,
  key: string,
): number | undefined {
  const value = source[key];
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function stringArrayField(
  source: Record<string, unknown>,
  key: string,
): string[] {
  const value = source[key];
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map((item) => cleanText(item)).filter(Boolean).slice(0, 24);
}

function logStage(
  itemId: string,
  stage: PipelineStage,
  status: "started" | "completed" | "failed",
  reason?: string,
) {
  console.info(JSON.stringify({ item_id: itemId, stage, status, reason }));
}

function buildAliases(
  title: string,
  siteName: string | undefined,
  authorName: string | undefined,
  hostname: string,
): string[] {
  return [
    ...new Set(
      [title, siteName, authorName, hostname].filter(Boolean).flatMap((value) =>
        value!.toLowerCase().split(/[\s,.;:!?/|-]+/)
      ).filter((word) => word.length > 3).slice(0, 12),
    ),
  ];
}

function estimateReadMinutes(text: string): number {
  const wordCount = text.split(/\s+/).filter((word) => word.length > 0).length;
  return Math.max(1, Math.ceil(wordCount / 220));
}

async function findImageAsset(
  supabase: SupabaseClient,
  item: ItemRow,
): Promise<ItemAssetRow | null> {
  const rawAsset = item.raw_content?.asset as
    | Record<string, unknown>
    | undefined;
  if (rawAsset?.bucket && rawAsset?.key) {
    return {
      storage_bucket: String(rawAsset.bucket),
      storage_key: String(rawAsset.key),
      content_type: typeof rawAsset.contentType === "string"
        ? rawAsset.contentType
        : null,
      byte_size: typeof rawAsset.byteSize === "number"
        ? rawAsset.byteSize
        : null,
      original_filename: typeof rawAsset.originalFilename === "string"
        ? rawAsset.originalFilename
        : item.title,
    };
  }

  const { data } = await supabase
    .from("item_assets")
    .select(
      "storage_bucket,storage_key,content_type,byte_size,original_filename",
    )
    .eq("item_id", item.id)
    .eq("asset_type", "image")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  return (data as ItemAssetRow | null) ?? null;
}

async function createR2ReadUrl(
  bucket: string,
  key: string,
  expires: number,
): Promise<string> {
  const accountId = Deno.env.get("CLOUDFLARE_R2_ACCOUNT_ID");
  const accessKeyId = Deno.env.get("CLOUDFLARE_R2_ACCESS_KEY_ID");
  const secretAccessKey = Deno.env.get("CLOUDFLARE_R2_SECRET_ACCESS_KEY");
  if (!accountId || !accessKeyId || !secretAccessKey) {
    throw new Error("r2_env_missing");
  }

  const endpoint = `https://${accountId}.r2.cloudflarestorage.com`;
  const objectUrl = `${endpoint}/${bucket}/${key}`;
  const aws = new AwsClient({
    accessKeyId,
    secretAccessKey,
    service: "s3",
    region: "auto",
  });
  const readRequest = await (aws as any).sign(objectUrl, {
    method: "GET",
    aws: { signQuery: true, expires },
  });
  return readRequest.url;
}

async function analyzeImageWithVision(input: {
  imageUrl: string;
  sourceType: "screenshot" | "photo";
  fallbackTitle: string;
}): Promise<ImageAnalysis> {
  const prompt = buildImageAnalysisPrompt();
  const openRouterResult = await callOpenRouterStructuredJson({
    models: imageAnalysisModels(),
    messages: [{
      role: "user",
      content: [
        { type: "text", text: prompt },
        {
          type: "image_url",
          image_url: { url: input.imageUrl, detail: "high" },
        },
      ],
    }],
    schemaName: "image_semantic_analysis",
    schema: imageAnalysisSchema,
  });
  if (openRouterResult.status === "complete" && openRouterResult.json) {
    return normalizeImageAnalysis(
      openRouterResult.json,
      input.fallbackTitle,
      input.sourceType,
      openRouterResult.model,
    );
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return fallbackImageAnalysis(
      input.fallbackTitle,
      input.sourceType,
      openRouterResult.status === "failed" ? "failed" : "vision_disabled",
      openRouterResult.model,
    );
  }

  const model = Deno.env.get("OPENAI_MODEL_IMAGE") || "gpt-4.1-mini";
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "authorization": `Bearer ${apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.1,
      input: [{
        role: "user",
        content: [
          {
            type: "input_text",
            text: prompt,
          },
          {
            type: "input_image",
            image_url: input.imageUrl,
            detail: "high",
          },
        ],
      }],
    }),
  });

  if (!response.ok) {
    return fallbackImageAnalysis(
      input.fallbackTitle,
      input.sourceType,
      "failed",
      model,
    );
  }

  const payload = await response.json();
  const text = extractResponseText(payload);
  return normalizeImageAnalysis(
    parseJsonObject(text),
    input.fallbackTitle,
    input.sourceType,
    model,
  );
}

const imageAnalysisSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "title",
    "summary",
    "contentType",
    "language",
    "visibleText",
    "aliases",
    "entities",
    "chunks",
    "needsClarification",
    "clarificationQuestion",
  ],
  properties: {
    title: { type: "string" },
    summary: { type: "string" },
    contentType: {
      type: "string",
      enum: [
        "recipe",
        "film",
        "place",
        "article",
        "product",
        "video",
        "manual",
        "note",
        "unknown",
      ],
    },
    language: { type: "string" },
    visibleText: { type: "string" },
    aliases: { type: "array", items: { type: "string" } },
    entities: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["entity", "entityType", "normalizedValue", "metadata"],
        properties: {
          entity: { type: "string" },
          entityType: { type: "string" },
          normalizedValue: { type: "string" },
          metadata: { type: "object", additionalProperties: true },
        },
      },
    },
    chunks: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["chunkType", "content", "metadata"],
        properties: {
          chunkType: { type: "string" },
          content: { type: "string" },
          metadata: { type: "object", additionalProperties: true },
        },
      },
    },
    needsClarification: { type: "boolean" },
    clarificationQuestion: { type: "string" },
  },
} as const;

function buildImageAnalysisPrompt(): string {
  return [
    "Analyze this saved image for a personal semantic memory app.",
    "Extract visible text, identify what kind of saved item this should become, and return JSON only.",
    "Use contentType: recipe, film, place, article, product, video, manual, note, or unknown.",
    "Use manual for how-to screenshots, setup instructions, repair guides, checklists, tutorials, workflows, and other step-by-step instructions that are not recipes.",
    "Keep title user-facing and short. Summary should explain what the user likely wanted to remember.",
    "If the image is ambiguous, ask exactly one short clarification question.",
    'Schema: {"title":"","summary":"","contentType":"unknown","language":"en","visibleText":"","aliases":[],"entities":[{"entity":"","entityType":"","normalizedValue":"","metadata":{}}],"chunks":[{"chunkType":"visual|ocr|summary","content":"","metadata":{}}],"needsClarification":false,"clarificationQuestion":""}',
  ].join(" ");
}

function imageAnalysisModels(): string[] {
  return [
    Deno.env.get("AI_VISION_EXTRACT_PRIMARY") || "qwen/qwen3.5-flash-02-23",
    Deno.env.get("AI_VISION_EXTRACT_FALLBACK") ||
    "google/gemini-3.1-flash-lite-preview",
    Deno.env.get("AI_TEXT_EXTRACT_FALLBACK") || "openai/gpt-5.4-nano",
  ];
}

function fallbackImageAnalysis(
  fallbackTitle: string,
  sourceType: "screenshot" | "photo",
  status: "vision_disabled" | "failed",
  model?: string,
): ImageAnalysis {
  const title = titleFromFilename(fallbackTitle) ||
    (sourceType === "photo" ? "Saved photo" : "Saved screenshot");
  const summary = status === "vision_disabled"
    ? "Image saved. Vision analysis will run after OpenAI credentials are configured."
    : "Image saved. Vision analysis could not complete yet.";
  return {
    title,
    summary,
    contentType: "unknown",
    language: "en",
    visibleText: "",
    aliases: buildAliases(title, undefined, undefined, summary),
    entities: [],
    chunks: [{ chunkType: "summary", content: summary }],
    needsClarification: false,
    analysisStatus: status,
    model,
  };
}

function extractResponseText(payload: Record<string, unknown>): string {
  if (typeof payload.output_text === "string") {
    return payload.output_text;
  }
  const output = payload.output;
  if (!Array.isArray(output)) {
    return "";
  }
  const parts: string[] = [];
  for (const item of output) {
    if (!item || typeof item !== "object") {
      continue;
    }
    const content = (item as Record<string, unknown>).content;
    if (!Array.isArray(content)) {
      continue;
    }
    for (const contentItem of content) {
      if (!contentItem || typeof contentItem !== "object") {
        continue;
      }
      const text = (contentItem as Record<string, unknown>).text;
      if (typeof text === "string") {
        parts.push(text);
      }
    }
  }
  return parts.join("\n");
}

function parseJsonObject(value: string): Record<string, unknown> {
  const trimmed = value.trim().replace(/^```json\s*/i, "").replace(
    /^```\s*/i,
    "",
  ).replace(/```$/i, "").trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    return {};
  }
  try {
    return JSON.parse(trimmed.slice(start, end + 1)) as Record<string, unknown>;
  } catch {
    return {};
  }
}

function normalizeImageAnalysis(
  value: Record<string, unknown>,
  fallbackTitle: string,
  sourceType: "screenshot" | "photo",
  model?: string,
): ImageAnalysis {
  const contentType = normalizeItemType(value.contentType);
  const title = cleanText(value.title) || titleFromFilename(fallbackTitle) ||
    (sourceType === "photo" ? "Saved photo" : "Saved screenshot");
  const visibleText = cleanText(value.visibleText);
  const summary = cleanText(value.summary) || visibleText || "Saved image";
  const aliases = toStringArray(value.aliases).concat(
    buildAliases(title, undefined, undefined, summary),
  );
  const chunks = toChunkArray(value.chunks);
  if (visibleText) {
    chunks.push({ chunkType: "ocr", content: visibleText });
  }
  chunks.push({ chunkType: "summary", content: summary });
  return {
    title,
    summary,
    contentType,
    language: cleanText(value.language) || "en",
    visibleText,
    aliases: [
      ...new Set(aliases.map((alias) => alias.toLowerCase()).filter(Boolean)),
    ].slice(0, 24),
    entities: toEntityArray(value.entities),
    chunks: dedupeChunks(chunks),
    needsClarification: value.needsClarification === true,
    clarificationQuestion: cleanText(value.clarificationQuestion),
    analysisStatus: "complete",
    model,
  };
}

function normalizeItemType(value: unknown): ImageAnalysis["contentType"] {
  if (typeof value !== "string") {
    return "unknown";
  }
  if (
    [
      "recipe",
      "film",
      "place",
      "article",
      "product",
      "video",
      "manual",
      "note",
      "unknown",
    ].includes(value)
  ) {
    return value as ImageAnalysis["contentType"];
  }
  return "unknown";
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.map((item) => cleanText(item)).filter(Boolean);
}

function toChunkArray(value: unknown): ImageAnalysis["chunks"] {
  if (!Array.isArray(value)) {
    return [];
  }
  const chunks: ImageAnalysis["chunks"] = [];
  for (const item of value) {
    if (!item || typeof item !== "object") {
      continue;
    }
    const row = item as Record<string, unknown>;
    const content = cleanText(row.content);
    if (!content) {
      continue;
    }
    chunks.push({
      chunkType: cleanText(row.chunkType) || "visual",
      content,
      metadata: typeof row.metadata === "object" && row.metadata !== null
        ? row.metadata as Record<string, unknown>
        : undefined,
    });
  }
  return chunks;
}

function toEntityArray(value: unknown): ImageAnalysis["entities"] {
  if (!Array.isArray(value)) {
    return [];
  }
  const entities: ImageAnalysis["entities"] = [];
  for (const item of value) {
    if (!item || typeof item !== "object") {
      continue;
    }
    const row = item as Record<string, unknown>;
    const entity = cleanText(row.entity);
    if (!entity) {
      continue;
    }
    entities.push({
      entity,
      entityType: cleanText(row.entityType) || "unknown",
      normalizedValue: cleanText(row.normalizedValue) || entity.toLowerCase(),
      metadata: typeof row.metadata === "object" && row.metadata !== null
        ? row.metadata as Record<string, unknown>
        : undefined,
    });
  }
  return entities.slice(0, 32);
}

function dedupeChunks(
  chunks: ImageAnalysis["chunks"],
): ImageAnalysis["chunks"] {
  const seen = new Set<string>();
  return chunks.filter((chunk) => {
    const key = `${chunk.chunkType}:${chunk.content}`;
    if (seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  }).slice(0, 12);
}

async function replaceSearchDocs(
  supabase: SupabaseClient,
  item: ItemRow,
  analysis: SearchDocsAnalysis,
  title: string,
  summary: string,
  extractionKind = "image_vision",
): Promise<SearchDocsWriteResult> {
  await supabase.from("item_chunks").delete().eq("item_id", item.id);
  await supabase.from("item_entities").delete().eq("item_id", item.id);

  const chunks = analysis.chunks.length > 0
    ? analysis.chunks
    : [{ chunkType: "summary", content: summary }];

  const embeddingInput = [
    buildItemEmbeddingText(title, summary, analysis),
    ...chunks.map((chunk) => chunk.content),
  ];
  const embeddings = await generateEmbeddings(embeddingInput);
  const itemEmbedding = embeddings.status === "complete"
    ? embeddings.vectors[0]
    : undefined;
  const chunkEmbeddings = embeddings.status === "complete"
    ? embeddings.vectors.slice(1)
    : [];

  if (itemEmbedding) {
    await supabase
      .from("items")
      .update({ embedding: embeddingToPgVector(itemEmbedding) })
      .eq("id", item.id);
  }

  await supabase.from("item_chunks").insert(chunks.map((chunk, index) => ({
    item_id: item.id,
    user_id: item.user_id,
    chunk_type: chunk.chunkType,
    content: chunk.content,
    ...(chunkEmbeddings[index]
      ? { embedding: embeddingToPgVector(chunkEmbeddings[index]) }
      : {}),
    metadata: {
      ...(chunk.metadata ?? {}),
      title,
      sourceType: item.source_type,
      extraction: extractionKind,
    },
  })));

  if (analysis.entities.length > 0) {
    await supabase.from("item_entities").insert(
      analysis.entities.map((entity) => ({
        item_id: item.id,
        user_id: item.user_id,
        entity: entity.entity,
        entity_type: entity.entityType,
        normalized_value: entity.normalizedValue,
        metadata: entity.metadata ?? {},
      })),
    );
  }

  return {
    chunkCount: chunks.length,
    embeddedChunkCount: chunkEmbeddings.length,
    itemEmbedded: Boolean(itemEmbedding),
    embeddingStatus: embeddings.status,
    embeddingModel: embeddings.model,
    embeddingError: embeddings.error,
  };
}

function buildItemEmbeddingText(
  title: string,
  summary: string,
  analysis: SearchDocsAnalysis,
): string {
  const entityText = analysis.entities
    .map((entity) =>
      `${entity.entityType}: ${entity.normalizedValue || entity.entity}`
    )
    .join("\n");
  const chunkText = analysis.chunks
    .slice(0, 6)
    .map((chunk) => chunk.content)
    .join("\n");
  return [title, summary, entityText, chunkText].filter((value) =>
    value.trim().length > 0
  ).join("\n\n");
}

function titleFromFilename(value: string): string {
  const filename = value.split(/[\\/]/).pop() || value;
  return filename.replace(/\.[a-z0-9]+$/i, "").replace(/[_-]+/g, " ").trim();
}

function cleanText(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }
  return value.replace(/\s+/g, " ").trim();
}

async function markReadyWithoutProcessing(
  supabase: SupabaseClient,
  item: ItemRow,
  reason: string,
) {
  await supabase
    .from("items")
    .update({
      processing_status: "ready",
      raw_content_expires_at: new Date(Date.now() + 1000 * 60 * 60 * 24)
        .toISOString(),
      raw_content_retention_reason: reason,
      updated_at: new Date().toISOString(),
    })
    .eq("id", item.id);
}

async function markFailed(
  supabase: SupabaseClient,
  itemId: string,
  message: string,
) {
  await supabase
    .from("items")
    .update({
      processing_status: "failed",
      clarification_question: message,
      raw_content_expires_at: new Date(Date.now() + 1000 * 60 * 60)
        .toISOString(),
      raw_content_retention_reason: "failed_processing_retry_window",
      updated_at: new Date().toISOString(),
    })
    .eq("id", itemId);
}
