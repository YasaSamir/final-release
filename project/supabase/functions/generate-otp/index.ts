import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import "https://deno.land/std@0.168.0/dotenv/load.ts"; // استيراد مكتبة dotenv

console.log("Generate OTP Edge Function initialized");

serve(async (req) => {
  // Define CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Log the raw body to debug the incoming request
    const rawBody = await req.text();
    console.log("Raw body received:", rawBody);

    // Parse the JSON body
    let body;
    try {
      body = JSON.parse(rawBody);
    } catch (parseError) {
      throw new Error(`Failed to parse JSON: ${parseError.message}`);
    }

    const { email, action } = body;

    // Validate email
    if (!email) {
      return new Response(JSON.stringify({ error: "Email is required" }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        },
      });
    }

    // Retrieve environment variables from .env
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in the .env file");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Delete action to remove an email and OTP record
    if (action === "delete") {
      const { error } = await supabase
        .from("temp_otps")
        .delete()
        .eq("email", email);

      if (error) {
        console.error("Database error:", error.message);
        throw new Error(`Database error: ${error.message}`);
      }

      return new Response(
        JSON.stringify({ message: `Email ${email} and associated OTP removed successfully` }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            ...corsHeaders,
          },
        }
      );
    }

    // Original OTP generation logic
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: dbError } = await supabase
      .from("temp_otps")
      .upsert({ email, otp, expires_at: expiresAt }, { onConflict: "email" });

    if (dbError) {
      console.error("Database error:", dbError.message);
      throw new Error(`Database error: ${dbError.message}`);
    }

    const sendGridApiKey = Deno.env.get("SENDGRID_API_KEY");
    if (!sendGridApiKey) {
      throw new Error("SENDGRID_API_KEY must be set in the .env file");
    }

    const emailResponse = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${sendGridApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email }] }],
        from: { email: "yagasamir36@gmail.com" },
        subject: "Your OTP Code",
        content: [{ type: "text/plain", value: `Your OTP is ${otp}` }],
      }),
    });

    if (!emailResponse.ok) {
      const errorDetails = await emailResponse.text();
      console.error("SendGrid error:", errorDetails);
      throw new Error(`Failed to send OTP email: ${errorDetails}`);
    }

    return new Response(JSON.stringify({ message: "OTP sent successfully" }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  } catch (error) {
    console.error("Unexpected error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  }
});