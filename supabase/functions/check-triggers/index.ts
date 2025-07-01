import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logFunctionStart, logFunctionEnd, logFunctionError, createHealthCheckResponse, createCorsResponse } from '../_shared/utils/logging.ts'

const FUNCTION_NAME = 'check-triggers';

serve(async (req) => {
  const requestId = crypto.randomUUID();
  
  try {
    logFunctionStart(FUNCTION_NAME, { requestId });

    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      return createCorsResponse();
    }

    // Handle health check
    if (req.method === 'GET') {
      return createHealthCheckResponse(FUNCTION_NAME);
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Query triggers on user_preferences table
    const { data: triggers, error } = await supabase
      .from('information_schema.triggers')
      .select('trigger_name, event_manipulation, action_statement')
      .eq('event_object_table', 'user_preferences')

    if (error) {
      logFunctionError(FUNCTION_NAME, new Error(`Failed to query triggers: ${error.message}`), { requestId });
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Failed to query triggers', 
          details: error.message 
        }),
        { 
          status: 500, 
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          } 
        }
      )
    }

    logFunctionEnd(FUNCTION_NAME, { 
      requestId,
      triggerCount: triggers?.length || 0
    });

    return new Response(
      JSON.stringify({ 
        success: true, 
        triggers: triggers || [],
        count: triggers?.length || 0
      }),
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    )

  } catch (error) {
    logFunctionError(FUNCTION_NAME, error as Error, { requestId });
    return new Response(
      JSON.stringify({ 
        success: false,
        error: 'Internal server error', 
        details: (error as Error).message 
      }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    )
  }
}) 