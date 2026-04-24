import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type CreateAssetUploadRequest = {
  item_id: string;
  filename: string;
  content_type?: string;
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const accountId = Deno.env.get("CLOUDFLARE_R2_ACCOUNT_ID");
  const accessKeyId = Deno.env.get("CLOUDFLARE_R2_ACCESS_KEY_ID");
  const secretAccessKey = Deno.env.get("CLOUDFLARE_R2_SECRET_ACCESS_KEY");
  const bucket = Deno.env.get("CLOUDFLARE_R2_BUCKET");

  if (!supabaseUrl || !supabaseAnonKey || !accountId || !accessKeyId || !secretAccessKey || !bucket) {
    return Response.json({ error: "asset_upload_env_missing" }, { status: 500 });
  }

  const body = (await request.json()) as CreateAssetUploadRequest;
  if (!body.item_id || !body.filename) {
    return Response.json({ error: "item_id_and_filename_required" }, { status: 400 });
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: item, error } = await supabase
    .from("items")
    .select("id,user_id")
    .eq("id", body.item_id)
    .single<{ id: string; user_id: string }>();

  if (error || !item) {
    return Response.json({ error: "item_not_found" }, { status: 404 });
  }

  const contentType = body.content_type || "application/octet-stream";
  const filename = sanitizeFilename(body.filename);
  const key = `${item.user_id}/${item.id}/${crypto.randomUUID()}-${filename}`;
  const endpoint = `https://${accountId}.r2.cloudflarestorage.com`;
  const objectUrl = `${endpoint}/${bucket}/${key}`;
  const aws = new AwsClient({
    accessKeyId,
    secretAccessKey,
    service: "s3",
    region: "auto",
  });

  const uploadRequest = await aws.sign(objectUrl, {
    method: "PUT",
    headers: { "content-type": contentType },
    aws: { signQuery: true, expires: 600 },
  });
  const readRequest = await aws.sign(objectUrl, {
    method: "GET",
    aws: { signQuery: true, expires: 60 * 60 * 24 * 7 },
  });

  return Response.json({
    bucket,
    key,
    upload_url: uploadRequest.url,
    read_url: readRequest.url,
    content_type: contentType,
    expires_in_seconds: 600,
  });
});

function sanitizeFilename(value: string): string {
  const lastSegment = value.split(/[\\/]/).pop() || "image";
  return lastSegment.replace(/[^a-zA-Z0-9._-]/g, "_").slice(0, 120) || "image";
}
