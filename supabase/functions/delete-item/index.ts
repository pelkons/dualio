import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type AssetRef,
  deleteR2Assets,
  enqueueAssetCleanupJobs,
  markCleanupFailed,
  markCleanupSucceeded,
} from "../_shared/r2_cleanup.ts";

type DeleteItemRequest = {
  item_id: string;
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

  const body = (await request.json()) as DeleteItemRequest;
  if (!body.item_id) {
    return Response.json({ error: "item_id_required" }, { status: 400 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data: userData, error: userError } = await supabase.auth.getUser(jwt);
  const user = userData?.user;
  if (userError || !user) {
    return Response.json({ error: "authorization_required" }, { status: 401 });
  }

  const { data: item, error: itemError } = await supabase
    .from("items")
    .select("id,user_id")
    .eq("id", body.item_id)
    .eq("user_id", user.id)
    .maybeSingle<{ id: string; user_id: string }>();

  if (itemError) {
    return Response.json({ error: "item_lookup_failed" }, { status: 500 });
  }
  if (!item) {
    return Response.json({ error: "item_not_found" }, { status: 404 });
  }

  const assets = await itemAssets(supabase, user.id, item.id);
  await enqueueAssetCleanupJobs(supabase, assets, "item_deleted");
  const cleanup = await deleteR2Assets(assets);
  await markCleanupSucceeded(supabase, cleanup.deleted);
  await markCleanupFailed(supabase, cleanup.failed);

  const { error: deleteError } = await supabase
    .from("items")
    .delete()
    .eq("id", item.id)
    .eq("user_id", user.id);

  if (deleteError) {
    return Response.json({ error: "item_delete_failed" }, { status: 500 });
  }

  return Response.json({
    deleted: true,
    item_id: item.id,
    r2_deleted_count: cleanup.deleted.length,
    r2_queued_count: cleanup.failed.length,
  });
});

async function itemAssets(
  supabase: SupabaseClient,
  userId: string,
  itemId: string,
): Promise<AssetRef[]> {
  const { data, error } = await supabase
    .from("item_assets")
    .select("user_id,item_id,storage_provider,storage_bucket,storage_key")
    .eq("user_id", userId)
    .eq("item_id", itemId);
  if (error || !data) {
    return [];
  }
  return (data as Array<Record<string, unknown>>).map((asset) => ({
    user_id: asset.user_id as string,
    item_id: asset.item_id as string,
    storage_provider: asset.storage_provider as string | null,
    storage_bucket: asset.storage_bucket as string,
    storage_key: asset.storage_key as string,
  }));
}

function bearerToken(value: string | null): string | null {
  const match = value?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}
