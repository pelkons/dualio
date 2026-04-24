type SearchRequest = {
  query: string;
  locale: "en" | "he" | "ru" | "it" | "fr" | "es" | "de";
  limit?: number;
  debug?: boolean;
};

Deno.serve(async (request: Request): Promise<Response> => {
  const body = (await request.json()) as SearchRequest;

  if (!body.query?.trim()) {
    return Response.json({ error: "query is required" }, { status: 400 });
  }

  return Response.json({
    status: "contract_only",
    query: body.query,
    locale: body.locale,
    limit: body.limit ?? 20,
    strategy: [
      "embed multilingual query",
      "infer item type when useful",
      "match item_chunks embeddings",
      "match item embeddings",
      "full-text match",
      "entity match",
      "alias match",
      "recency/context boost",
      "rerank",
    ],
    debug_match_reason: body.debug === true,
  });
});
