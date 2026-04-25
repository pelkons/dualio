import { AwsClient } from "https://esm.sh/aws4fetch@1.0.20";

type SupabaseClient = any;

export type AssetCleanupReason =
  | "pending_upload"
  | "item_deleted"
  | "account_deleted"
  | "orphaned_asset";

export type AssetRef = {
  user_id: string;
  item_id?: string | null;
  storage_provider?: string | null;
  storage_bucket: string;
  storage_key: string;
};

export type CleanupJobRow = AssetRef & {
  id: string;
  reason: AssetCleanupReason;
  status: "pending" | "succeeded" | "failed" | "cancelled";
  attempts: number;
};

type R2Env = {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
};

export function readR2Env(): R2Env | null {
  const accountId = Deno.env.get("CLOUDFLARE_R2_ACCOUNT_ID");
  const accessKeyId = Deno.env.get("CLOUDFLARE_R2_ACCESS_KEY_ID");
  const secretAccessKey = Deno.env.get("CLOUDFLARE_R2_SECRET_ACCESS_KEY");
  if (!accountId || !accessKeyId || !secretAccessKey) {
    return null;
  }
  return { accountId, accessKeyId, secretAccessKey };
}

export async function enqueueAssetCleanupJobs(
  supabase: SupabaseClient,
  assets: AssetRef[],
  reason: AssetCleanupReason,
  options: { nextAttemptAt?: string } = {},
): Promise<void> {
  const rows = assets
    .filter(isR2Asset)
    .map((asset) => ({
      user_id: asset.user_id,
      item_id: asset.item_id ?? null,
      reason,
      status: "pending",
      storage_provider: "cloudflare_r2",
      storage_bucket: asset.storage_bucket,
      storage_key: asset.storage_key,
      attempts: 0,
      last_error: null,
      next_attempt_at: options.nextAttemptAt ?? new Date().toISOString(),
      cleaned_at: null,
      updated_at: new Date().toISOString(),
    }));

  if (rows.length === 0) {
    return;
  }

  const { error } = await supabase
    .from("asset_cleanup_jobs")
    .upsert(rows, {
      onConflict: "storage_provider,storage_bucket,storage_key",
    });
  if (error) {
    throw error;
  }
}

export async function deleteR2Asset(
  asset: AssetRef,
  env = readR2Env(),
): Promise<{ ok: boolean; error?: string }> {
  if (!isR2Asset(asset)) {
    return { ok: true };
  }
  if (!env) {
    return { ok: false, error: "r2_env_missing" };
  }

  try {
    const aws = new AwsClient({
      accessKeyId: env.accessKeyId,
      secretAccessKey: env.secretAccessKey,
      service: "s3",
      region: "auto",
    });
    const objectUrl = r2ObjectUrl(env.accountId, asset);
    const signedRequest = await aws.sign(
      new Request(objectUrl, { method: "DELETE" }),
    );
    const response = await fetch(signedRequest);
    if (!response.ok && response.status !== 404) {
      return { ok: false, error: `r2_delete_${response.status}` };
    }
    return { ok: true };
  } catch (error) {
    return { ok: false, error: errorName(error) };
  }
}

export async function deleteR2Assets(
  assets: AssetRef[],
  env = readR2Env(),
): Promise<
  { deleted: AssetRef[]; failed: Array<AssetRef & { error: string }> }
> {
  const deleted: AssetRef[] = [];
  const failed: Array<AssetRef & { error: string }> = [];
  for (const asset of assets.filter(isR2Asset)) {
    const result = await deleteR2Asset(asset, env);
    if (result.ok) {
      deleted.push(asset);
    } else {
      failed.push({ ...asset, error: result.error ?? "r2_delete_failed" });
    }
  }
  return { deleted, failed };
}

export async function markCleanupSucceeded(
  supabase: SupabaseClient,
  assets: AssetRef[],
): Promise<void> {
  await updateCleanupJobs(supabase, assets, {
    status: "succeeded",
    last_error: null,
    cleaned_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
}

export async function markCleanupFailed(
  supabase: SupabaseClient,
  failures: Array<AssetRef & { error: string; attempts?: number }>,
): Promise<void> {
  for (const failure of failures) {
    const attempts = Math.max(1, failure.attempts ?? 1);
    const retryDelayMinutes = Math.min(24 * 60, 5 * 2 ** (attempts - 1));
    await updateCleanupJobs(supabase, [failure], {
      status: "failed",
      attempts,
      last_error: failure.error.slice(0, 500),
      next_attempt_at: new Date(Date.now() + retryDelayMinutes * 60_000)
        .toISOString(),
      updated_at: new Date().toISOString(),
    });
  }
}

export async function markCleanupCancelled(
  supabase: SupabaseClient,
  assets: AssetRef[],
  reason: string,
): Promise<void> {
  await updateCleanupJobs(supabase, assets, {
    status: "cancelled",
    last_error: reason,
    cleaned_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });
}

async function updateCleanupJobs(
  supabase: SupabaseClient,
  assets: AssetRef[],
  values: Record<string, unknown>,
): Promise<void> {
  for (const asset of assets.filter(isR2Asset)) {
    await supabase
      .from("asset_cleanup_jobs")
      .update(values)
      .eq("storage_provider", "cloudflare_r2")
      .eq("storage_bucket", asset.storage_bucket)
      .eq("storage_key", asset.storage_key);
  }
}

function isR2Asset(asset: AssetRef): boolean {
  return (asset.storage_provider ?? "cloudflare_r2") === "cloudflare_r2" &&
    Boolean(asset.storage_bucket) &&
    Boolean(asset.storage_key);
}

function r2ObjectUrl(accountId: string, asset: AssetRef): string {
  const bucket = encodeURIComponent(asset.storage_bucket);
  const key = asset.storage_key.split("/").map(encodeURIComponent).join("/");
  return `https://${accountId}.r2.cloudflarestorage.com/${bucket}/${key}`;
}

function errorName(error: unknown): string {
  if (error instanceof Error) {
    return error.name || error.message || "error";
  }
  return "error";
}
