// Supabase Edge Function to send push notifications via FCM
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

interface NotificationPayload {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

serve(async (req) => {
  try {
    // Get FCM server key from secrets
    if (!FCM_SERVER_KEY) {
      throw new Error("FCM_SERVER_KEY not set in Supabase secrets");
    }

    // Parse request body
    const payload: NotificationPayload = await req.json();
    const { user_id, title, body, data = {} } = payload;

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: user_id, title, body" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get FCM tokens for the user
    const { data: devices, error: devicesError } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("user_id", user_id);

    if (devicesError) {
      throw new Error(`Error fetching devices: ${devicesError.message}`);
    }

    if (!devices || devices.length === 0) {
      return new Response(
        JSON.stringify({ message: "No devices found for user", sent: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Send notification to all devices
    const tokens = devices.map((d) => d.fcm_token).filter(Boolean);
    let successCount = 0;
    let failureCount = 0;

    for (const token of tokens) {
      try {
        const fcmPayload = {
          to: token,
          notification: {
            title,
            body,
          },
          data: {
            ...data,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          priority: "high",
        };

        const response = await fetch(FCM_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify(fcmPayload),
        });

        if (response.ok) {
          successCount++;
        } else {
          const errorText = await response.text();
          console.error(`FCM error for token ${token}: ${errorText}`);
          failureCount++;
        }
      } catch (error) {
        console.error(`Error sending to token ${token}:`, error);
        failureCount++;
      }
    }

    return new Response(
      JSON.stringify({
        message: "Notifications sent",
        sent: successCount,
        failed: failureCount,
        total: tokens.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in send_push function:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

