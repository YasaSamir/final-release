// supabase/functions/verify-otp.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { email, otp } = body;

    if (!email || !otp) {
      return new Response(
        JSON.stringify({ error: "Email and OTP are required" }),
        { status: 400, headers: corsHeaders }
      );
    }

    const supabase = createClient(
      "https://kbpdkigziqolzkllqkzo.supabase.co",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImticGRraWd6aXFvbHprbGxxa3pvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MTkwMzE2MiwiZXhwIjoyMDU3NDc5MTYyfQ.fIQPnl94bplEQzNHDHmvP-iXtZDwebTiBGi01sh5GaM"
    );

    const { data, error } = await supabase
      .from("temp_otps")
      .select("*")
      .eq("email", email)
      .single();

    if (error) {
      console.error("Database error:", error.message);
      return new Response(
        JSON.stringify({ error: `Database error: ${error.message}` }),
        { status: 500, headers: corsHeaders }
      );
    }

    if (!data) {
      return new Response(
        JSON.stringify({ error: "No OTP found for this email" }),
        { status: 404, headers: corsHeaders }
      );
    }

    const now = new Date();
    const expiresAt = new Date(data.expires_at);

    if (now > expiresAt) {
      return new Response(
        JSON.stringify({ error: "OTP has expired" }),
        { status: 400, headers: corsHeaders }
      );
    }

    if (data.otp !== otp) {
      return new Response(
        JSON.stringify({ error: "Invalid OTP" }),
        { status: 400, headers: corsHeaders }
      );
    }

    // إذا الـ OTP صح، تمسحيه من الجدول
    await supabase.from("temp_otps").delete().eq("email", email);

    return new Response(
      JSON.stringify({ message: "OTP verified successfully" }),
      { headers: corsHeaders }
    );
  } catch (error) {
    console.error("Unexpected error:", error.message);
    return new Response(
      JSON.stringify({ error: `Unexpected error: ${error.message}` }),
      { status: 500, headers: corsHeaders }
    );
  }
});