// Supabase Edge Function: send-push
// Sends FCM push notifications via Firebase Cloud Messaging HTTP v1 API.
//
// This function is invoked via HTTP POST (or database webhook/trigger)
// when an exchange happens and the recipient should be notified.
//
// Prerequisites before deploying:
//   1. Set the FIREBASE_SERVICE_ACCOUNT_KEY secret in your Supabase project:
//      supabase secrets set FIREBASE_SERVICE_ACCOUNT_KEY='<json-key>'
//   2. Deploy with: supabase functions deploy send-push
//
// Expected request body:
// {
//   "user_id": "<recipient-user-id>",
//   "title": "New Bump!",
//   "body": "Someone just bumped with you",
//   "data": { "type": "exchange", "exchange_id": "..." }
// }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    const { user_id, title, body, data } = await req.json();

    if (!user_id || !title) {
      return new Response(
        JSON.stringify({ error: "user_id and title are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Create Supabase admin client to look up device tokens
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Fetch active FCM tokens for the target user
    const { data: devices, error: dbError } = await supabase
      .from("devices")
      .select("fcm_token")
      .eq("user_id", user_id)
      .eq("is_active", true);

    if (dbError) {
      return new Response(
        JSON.stringify({ error: dbError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!devices || devices.length === 0) {
      return new Response(
        JSON.stringify({ message: "No active devices for user" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // TODO: Implement Firebase Cloud Messaging HTTP v1 API call
    // This requires:
    //   1. Parsing the FIREBASE_SERVICE_ACCOUNT_KEY secret
    //   2. Generating a short-lived OAuth2 access token
    //   3. Sending POST to https://fcm.googleapis.com/v1/projects/{project}/messages:send
    //
    // For now, log and return the tokens that would be notified.

    const tokens = devices.map((d: { fcm_token: string }) => d.fcm_token);
    console.log(`Would send push to ${tokens.length} device(s) for user ${user_id}`);
    console.log(`Title: ${title}, Body: ${body ?? ""}`);

    return new Response(
      JSON.stringify({
        message: `Push placeholder: ${tokens.length} device(s) found`,
        tokens_count: tokens.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
