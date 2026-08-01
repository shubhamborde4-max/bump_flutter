// Supabase Edge Function: delete-account
// GDPR-compliant account deletion. Deletes all user data and the auth account.
//
// This function requires the user's JWT token in the Authorization header.
// It deletes: prospects, events, nudges, templates, devices, profile, avatar,
// and finally the auth user record.
//
// Deploy with: supabase functions deploy delete-account
//
// Expected: POST with Authorization: Bearer <user-jwt>
// No request body needed — the user is identified from the JWT.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Create a client with the user's JWT to verify identity
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // User client — verifies the JWT is valid
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const userId = user.id;

    // Admin client — has permission to delete across all tables
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    // Delete all user data in dependency order
    const deletions = [
      adminClient.from("nudges").delete().eq("user_id", userId),
      adminClient.from("devices").delete().eq("user_id", userId),
    ];
    await Promise.all(deletions);

    // Prospects and events may have foreign key dependencies
    await adminClient.from("prospects").delete().eq("user_id", userId);
    await adminClient.from("events").delete().eq("user_id", userId);
    await adminClient.from("templates").delete().eq("user_id", userId);

    // Delete avatar from storage
    try {
      const { data: files } = await adminClient.storage
        .from("avatars")
        .list(userId);
      if (files && files.length > 0) {
        const filePaths = files.map((f) => `${userId}/${f.name}`);
        await adminClient.storage.from("avatars").remove(filePaths);
      }
    } catch {
      // Avatar deletion is best-effort — don't fail the whole operation
      console.warn("Avatar cleanup failed, continuing with account deletion");
    }

    // Delete profile
    await adminClient.from("profiles").delete().eq("id", userId);

    // Delete the auth user (this is irreversible)
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
    if (deleteError) {
      return new Response(
        JSON.stringify({ error: `Failed to delete auth user: ${deleteError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ message: "Account and all data deleted successfully" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
