import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { AudioGenerationService } from './services.ts';
import { AudioGenerationRequest, AudioGenerationResponse } from './types.ts';
import { CONFIG } from './config.ts';
import { logFunctionStart, logFunctionEnd, logFunctionError, createHealthCheckResponse, createCorsResponse } from '../_shared/utils/logging.ts';

const FUNCTION_NAME = 'generate-audio';

// Initialize the audio generation service
const audioService = new AudioGenerationService();

serve(async (req) => {
  const requestId = crypto.randomUUID();
  let requestBody: AudioGenerationRequest;
  
  try {
    logFunctionStart(FUNCTION_NAME, { requestId });

    // Handle CORS
    if (req.method === 'OPTIONS') {
      return createCorsResponse();
    }

    // Handle health check
    if (req.method === 'GET') {
      return createHealthCheckResponse(FUNCTION_NAME, {
        config: {
          maxClips: Object.keys(CONFIG.clips).length,
          supportedVoices: Object.keys(CONFIG.openai.voices),
          batchSize: CONFIG.generation.batchSize
        }
      });
    }

    // Validate request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Method not allowed. Use POST to generate audio clips.'
        }),
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
    try {
      requestBody = await req.json();
    } catch (error) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Invalid JSON in request body'
        }),
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
    if (!requestBody.userId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'userId is required'
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // Generate audio clips
    const result = await audioService.generateUserAudioClips(
      requestBody.userId,
      requestBody.forceRegenerate || false
    );

    // Prepare response
    const response: AudioGenerationResponse = {
      success: result.success,
      message: result.message,
      generatedClips: result.generatedClips,
      failedClips: result.failedClips,
      userId: requestBody.userId,
      storageBaseUrl: CONFIG.storage.bucket
    };

    // Log the result at function level
    await audioService.db.logEvent('function_completed', requestBody.userId, {
      success: result.success,
      generatedCount: result.generatedClips.length,
      failedCount: result.failedClips.length,
      forceRegenerate: requestBody.forceRegenerate || false,
      message: result.message
    });

    return new Response(
      JSON.stringify(response),
      {
        status: result.success ? 200 : 207, // 207 for partial success
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    console.error(`Function error:`, error);
    logFunctionError(FUNCTION_NAME, error as Error, { requestId });
    // Log failure
    const userId = (typeof requestBody === 'object' && requestBody && requestBody.userId) ? requestBody.userId : 'unknown';
    await audioService.db.logEvent('audio_generation_function_failed', userId, {
      requestId,
      error: (error as Error).message
    });
    return new Response(
      JSON.stringify({
        success: false,
        error: `Internal server error: ${(error as Error).message}`,
        generatedClips: [],
        failedClips: [],
        userId: undefined,
        storageBaseUrl: CONFIG.storage.bucket
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