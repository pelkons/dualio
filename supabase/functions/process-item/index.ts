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

Deno.serve(async (request: Request): Promise<Response> => {
  const body = (await request.json()) as ProcessItemRequest;

  if (!body.item_id) {
    return Response.json({ error: "item_id is required" }, { status: 400 });
  }

  for (const stage of stages) {
    console.info(JSON.stringify({ item_id: body.item_id, stage, status: "planned" }));
  }

  return Response.json({
    item_id: body.item_id,
    idempotency_key: `process-item:${body.item_id}`,
    retry_safe: true,
    status: "contract_only",
    stages,
    clarification_rule: "Ask exactly one short question when the item is ambiguous.",
    r2_access_rule: "User images are accessed only through signed URLs produced by an Edge Function.",
  });
});
