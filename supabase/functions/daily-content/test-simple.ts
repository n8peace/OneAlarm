import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createHealthCheckResponse, createCorsResponse } from '../_shared/utils/logging.ts';

// Simple test version that bypasses environment validation
serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return createCorsResponse();
    }

    // Handle health check
    if (req.method === 'GET') {
      return createHealthCheckResponse('daily-content-test', {
        message: 'Simple test version - no API calls'
      });
    }

    // Handle content generation (POST request)
    if (req.method === 'POST') {
      console.log('Test daily content function called');
      
      // Simulate some work
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Test daily content collection completed successfully',
          timestamp: new Date().toISOString(),
          test: true
        }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // Method not allowed
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Method not allowed. Use POST to generate daily content or GET for health check.'
      }),
      {
        status: 405,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    console.error('Test daily content function failed:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: `Internal server error: ${(error as Error).message}`,
        timestamp: new Date().toISOString()
      }),
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