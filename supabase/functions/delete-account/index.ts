import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type AssetRef,
  deleteR2Assets,
  enqueueAssetCleanupJobs,
  markCleanupFailed,
  markCleanupSucceeded,
} from "../_shared/r2_cleanup.ts";

type DeleteAccountRequest = {
  confirm?: boolean;
};

type SupabaseClient = any;

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }

  const authorization = request.headers.get("Authorization");
  const jwt = bearerToken(authorization);
  if (!jwt) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return Response.json({ error: "supabase_service_env_missing" }, {
      status: 500,
    });
  }

  const body = (await request.json()) as DeleteAccountRequest;
  if (body.confirm !== true) {
    return Response.json({ error: "delete_account_confirmation_required" }, {
      status: 400,
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data: userData, error: userError } = await supabase.auth.getUser(jwt);
  const user = userData?.user;
  if (userError || !user) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const assets = await userAssets(supabase, user.id);
  await enqueueAssetCleanupJobs(supabase, assets, "account_deleted");
  const cleanup = await deleteR2Assets(assets);
  await markCleanupSucceeded(supabase, cleanup.deleted);
  await markCleanupFailed(supabase, cleanup.failed);

  const { error: deleteUserError } = await supabase.auth.admin.deleteUser(
    user.id,
  );
  if (deleteUserError) {
    return Response.json({ error: "account_delete_failed" }, { status: 500 });
  }

  return Response.json({
    deleted: true,
    user_id: user.id,
    r2_deleted_count: cleanup.deleted.length,
    r2_queued_count: cleanup.failed.length,
  });
});

async function userAssets(
  supabase: SupabaseClient,
  userId: string,
): Promise<AssetRef[]> {
  const { data, error } = await supabase
    .from("item_assets")
    .select("user_id,item_id,storage_provider,storage_bucket,storage_key")
    .eq("user_id", userId);
  if (error || !data) {
    return [];
  }
  return (data as Array<Record<string, unknown>>).map((asset) => ({
    user_id: asset.user_id as string,
    item_id: asset.item_id as string | null,
    storage_provider: asset.storage_provider as string | null,
    storage_bucket: asset.storage_bucket as string,
    storage_key: asset.storage_key as string,
  }));
}

function bearerToken(value: string | null): string | null {
  const match = value?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}
