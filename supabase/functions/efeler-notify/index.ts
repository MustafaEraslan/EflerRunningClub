// Supabase Edge Function: efeler-notify
// Sends FCM push notifications to Efeler Running Club members.
//
// Called by the Flutter client after a mutation. The client passes:
//   { type, title, body, ref_id?, target_user_ids? }
//
// When target_user_ids is null/empty, all Efeler device tokens are targeted.
//
// Required Supabase secrets:
//   FCM_SERVER_KEY — Firebase Cloud Messaging server key
//     (Firebase Console → Project Settings → Cloud Messaging → Server key)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, title, body, ref_id, target_user_ids } = await req.json();
    if (!title || !body) {
      return new Response(
        JSON.stringify({ error: "title and body required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");

    if (!fcmServerKey) {
      return new Response(
        JSON.stringify({ error: "FCM_SERVER_KEY not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Look up device tokens.
    let tokenQuery = supabase
      .from("efeler_device_tokens")
      .select("fcm_token")
      .eq("app_id", "efeler");

    if (target_user_ids && target_user_ids.length > 0) {
      tokenQuery = tokenQuery.in_("user_id", target_user_ids);
    }

    const { data: tokens } = await tokenQuery;
    const fcmTokens = (tokens || []).map(
      (t: { fcm_token: string }) => t.fcm_token
    );

    if (fcmTokens.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, reason: "no_tokens" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Send via FCM legacy HTTP API.
    let sentCount = 0;
    const batchSize = 500;

    for (let i = 0; i < fcmTokens.length; i += batchSize) {
      const batch = fcmTokens.slice(i, i + batchSize);
      const res = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          registration_ids: batch,
          notification: {
            title,
            body,
            sound: "default",
          },
          data: {
            type: type || "general",
            ref_id: ref_id || "",
          },
        }),
      });

      if (res.ok) {
        const result = await res.json();
        sentCount += result.success || 0;
      }
    }

    return new Response(
      JSON.stringify({ sent: sentCount, total: fcmTokens.length }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
