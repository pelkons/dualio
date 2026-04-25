import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type AssetRef,
  type CleanupJobRow,
  deleteR2Asset,
  markCleanupCancelled,
  markCleanupFailed,
  markCleanupSucceeded,
} from "../_shared/r2_cleanup.ts";

type CleanupAssetsRequest = {
  limit?: number;
};

type SupabaseClient = any;

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  if (!isAuthorizedCleanupRequest(request)) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return Response.json({ error: "supabase_service_env_missing" }, {
      status: 500,
    });
  }

  const body = (await request.json().catch(() => ({}))) as CleanupAssetsRequest;
  const limit = clampLimit(body.limit);
  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const jobs = await dueCleanupJobs(supabase, limit);

  let deletedCount = 0;
  let failedCount = 0;
  let cancelledCount = 0;

  for (const job of jobs) {
    const activeAsset = await hasActiveAsset(supabase, job);
    if (activeAsset) {
      await markCleanupCancelled(supabase, [job], "active_asset_exists");
      cancelledCount += 1;
      continue;
    }

    const result = await deleteR2Asset(job);
    if (result.ok) {
      await markCleanupSucceeded(supabase, [job]);
      deletedCount += 1;
    } else {
      await markCleanupFailed(supabase, [{
        ...job,
        attempts: job.attempts + 1,
        error: result.error ?? "r2_delete_failed",
      }]);
      failedCount += 1;
    }
  }

  return Response.json({
    checked_count: jobs.length,
    deleted_count: deletedCount,
    failed_count: failedCount,
    cancelled_count: cancelledCount,
  });
});

async function dueCleanupJobs(
  supabase: SupabaseClient,
  limit: number,
): Promise<CleanupJobRow[]> {
  const { data, error } = await supabase
    .from("asset_cleanup_jobs")
    .select(
      "id,user_id,item_id,reason,status,storage_provider,storage_bucket,storage_key,attempts",
    )
    .in("status", ["pending", "failed"])
    .lte("next_attempt_at", new Date().toISOString())
    .order("created_at", { ascending: true })
    .limit(limit);
  if (error || !data) {
    return [];
  }
  return (data as Array<Record<string, unknown>>).map((job) => ({
    id: job.id as string,
    user_id: job.user_id as string,
    item_id: job.item_id as string | null,
    reason: job.reason as CleanupJobRow["reason"],
    status: job.status as CleanupJobRow["status"],
    storage_provider: job.storage_provider as string | null,
    storage_bucket: job.storage_bucket as string,
    storage_key: job.storage_key as string,
    attempts: Number(job.attempts ?? 0),
  }));
}

async function hasActiveAsset(
  supabase: SupabaseClient,
  asset: AssetRef,
): Promise<boolean> {
  const { data, error } = await supabase
    .from("item_assets")
    .select("id")
    .eq("storage_provider", asset.storage_provider ?? "cloudflare_r2")
    .eq("storage_bucket", asset.storage_bucket)
    .eq("storage_key", asset.storage_key)
    .maybeSingle();
  return !error && Boolean(data);
}

function isAuthorizedCleanupRequest(request: Request): boolean {
  const expected = Deno.env.get("CLEANUP_ASSETS_SECRET");
  if (!expected) {
    return false;
  }
  const provided = request.headers.get("x-cleanup-secret") ??
    bearerToken(request.headers.get("Authorization"));
  return provided === expected;
}

function bearerToken(value: string | null): string | null {
  const match = value?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

function clampLimit(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return 50;
  }
  return Math.min(200, Math.max(1, Math.trunc(value)));
}
