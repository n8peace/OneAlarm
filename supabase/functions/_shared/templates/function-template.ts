// Template for new Supabase Edge Functions
// Copy this template and modify for new functions

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { logFunctionStart, logFunctionEnd, logFunctionError } from '../utils/logging.ts';
import { CONFIG, EVENT_TYPES } from '../constants/config.ts';
import type { BaseResponse } from '../types/common.ts';

const FUNCTION_NAME = 'function-name'; // Change this to your function name

interface RequestBody {
  // Define your request body interface here
  userId?: string;
  // Add other fields as needed
}

interface ResponseBody extends BaseResponse {
  // Define your response body interface here
  data?: any;
}

serve(async (req: Request) => {
  const requestId = crypto.randomUUID();
  
  try {
    logFunctionStart(FUNCTION_NAME, { requestId });

    // Handle CORS
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    // Validate request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Method not allowed'
        } as BaseResponse),
        {
          status: 405,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // Parse request body
    let body: RequestBody;
    try {
      body = await req.json();
    } catch (error) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Invalid JSON in request body'
        } as BaseResponse),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }
    
    // Validate required fields
    if (!body.userId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: CONFIG.ERRORS.INVALID_USER
        } as BaseResponse),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // Your function logic here
    // TODO: Implement your function logic

    const response: ResponseBody = {
      success: true,
      message: 'Function executed successfully',
      data: {} // Add your response data here
    };

    logFunctionEnd(FUNCTION_NAME, { requestId, userId: body.userId });

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    logFunctionError(FUNCTION_NAME, error as Error, { requestId });
    
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Internal server error'
      } as BaseResponse),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  }
}); 