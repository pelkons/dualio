import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { enqueueAssetCleanupJobs } from "../_shared/r2_cleanup.ts";

type CreateAssetUploadRequest = {
  item_id: string;
  filename: string;
  content_type?: string;
  byte_size?: number;
};

const defaultMaxImageUploadBytes = 4 * 1024 * 1024;

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
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const accountId = Deno.env.get("CLOUDFLARE_R2_ACCOUNT_ID");
  const accessKeyId = Deno.env.get("CLOUDFLARE_R2_ACCESS_KEY_ID");
  const secretAccessKey = Deno.env.get("CLOUDFLARE_R2_SECRET_ACCESS_KEY");
  const bucket = Deno.env.get("CLOUDFLARE_R2_BUCKET");

  if (
    !supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !accountId ||
    !accessKeyId ||
    !secretAccessKey || !bucket
  ) {
    return Response.json({ error: "asset_upload_env_missing" }, {
      status: 500,
    });
  }

  const body = (await request.json()) as CreateAssetUploadRequest;
  if (!body.item_id || !body.filename) {
    return Response.json({ error: "item_id_and_filename_required" }, {
      status: 400,
    });
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
  if (!contentType.toLowerCase().startsWith("image/")) {
    return Response.json({ error: "unsupported_asset_content_type" }, {
      status: 400,
    });
  }

  const byteSize = numberValue(body.byte_size);
  if (byteSize == null || byteSize <= 0) {
    return Response.json({ error: "byte_size_required" }, { status: 400 });
  }

  const maxUploadBytes = maxImageUploadBytes();
  if (byteSize > maxUploadBytes) {
    return Response.json({
      error: "asset_too_large",
      max_upload_bytes: maxUploadBytes,
    }, { status: 413 });
  }

  const filename = sanitizeFilename(body.filename);
  const key = `${item.user_id}/${item.id}/${crypto.randomUUID()}-${filename}`;
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);
  await enqueueAssetCleanupJobs(
    serviceClient,
    [{
      user_id: item.user_id,
      item_id: item.id,
      storage_provider: "cloudflare_r2",
      storage_bucket: bucket,
      storage_key: key,
    }],
    "pending_upload",
    {
      nextAttemptAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
        .toISOString(),
    },
  );

  const endpoint = `https://${accountId}.r2.cloudflarestorage.com`;
  const objectUrl = `${endpoint}/${bucket}/${key}`;
  const aws = new AwsClient({
    accessKeyId,
    secretAccessKey,
    service: "s3",
    region: "auto",
  });

  const signedHeaders = {
    "content-type": contentType,
    "content-length": String(byteSize),
  };
  const uploadObjectUrl = new URL(objectUrl);
  uploadObjectUrl.searchParams.set("X-Amz-Expires", "600");
  const uploadRequest = await aws.sign(
    new Request(uploadObjectUrl, {
      method: "PUT",
      headers: signedHeaders,
    }),
    { aws: { signQuery: true } },
  );
  const readObjectUrl = new URL(objectUrl);
  readObjectUrl.searchParams.set("X-Amz-Expires", String(60 * 60 * 24 * 7));
  const readRequest = await aws.sign(
    new Request(readObjectUrl, { method: "GET" }),
    { aws: { signQuery: true } },
  );

  return Response.json({
    bucket,
    key,
    upload_url: uploadRequest.url,
    read_url: readRequest.url,
    content_type: contentType,
    byte_size: byteSize,
    max_upload_bytes: maxUploadBytes,
    expires_in_seconds: 600,
  });
});

function numberValue(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }
  return Math.trunc(value);
}

function maxImageUploadBytes(): number {
  const configured = Number(Deno.env.get("MAX_IMAGE_UPLOAD_BYTES"));
  if (Number.isFinite(configured) && configured > 0) {
    return Math.trunc(configured);
  }
  return defaultMaxImageUploadBytes;
}

function sanitizeFilename(value: string): string {
  const lastSegment = value.split(/[\\/]/).pop() || "image";
  return lastSegment.replace(/[^a-zA-Z0-9._-]/g, "_").slice(0, 120) || "image";
}
