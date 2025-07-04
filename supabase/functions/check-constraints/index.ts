import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Query to check constraint order using raw SQL
    const { data, error } = await supabaseClient.rpc('exec_sql', {
      query: `
        SELECT 
          constraint_name,
          constraint_type
        FROM information_schema.table_constraints 
        WHERE table_name = 'user_preferences' 
        AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
        ORDER BY constraint_name;
      `
    })

    if (error) {
      throw error
    }

    return new Response(
      JSON.stringify({
        success: true,
        constraints: data,
        constraintOrder: data?.map(c => c.constraint_type) || []
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        details: error
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
}) 