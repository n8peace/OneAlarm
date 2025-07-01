import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { logFunctionStart, logFunctionEnd, logFunctionError, createHealthCheckResponse, createCorsResponse } from '../_shared/utils/logging.ts';
import { logEvent } from '../_shared/utils/database.ts';
import { GenerateAlarmAudioService } from './services.ts';
import type { GenerateAlarmAudioRequest, GenerateAlarmAudioResponse } from './types.ts';

const FUNCTION_NAME = 'generate-alarm-audio';

// Initialize the service
const alarmAudioService = new GenerateAlarmAudioService();

serve(async (req) => {
  const requestId = crypto.randomUUID();
  let requestBody: GenerateAlarmAudioRequest | undefined;
  
  try {
    logFunctionStart(FUNCTION_NAME, { requestId });

    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
      return createCorsResponse();
    }

    // Handle health check (GET request)
    if (req.method === 'GET') {
      return createHealthCheckResponse(FUNCTION_NAME);
    }

    // Validate request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Method not allowed. Use POST to generate alarm audio or GET for health check.'
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

    // Check if this is a queue processing request (no alarmId provided)
    if (!requestBody.alarmId) {
      console.log('Processing audio generation queue...');
      
      // Process queue items asynchronously (returns immediately, continues in background)
      const queueResult = await alarmAudioService.processQueueItemsAsync(50, 10);
      
      // Log queue processing start (not completion since it's async)
      await logEvent(
        'queue_processing_started',
        undefined,
        {
          queued_count: queueResult.queuedCount,
          estimated_time: queueResult.estimatedTime,
          function_name: FUNCTION_NAME,
          request_id: requestId
        }
      );

      console.log('Queue processing started:', {
        queued: queueResult.queuedCount,
        estimatedTime: queueResult.estimatedTime
      });

      logFunctionEnd(FUNCTION_NAME, { 
        requestId, 
        queueStarted: queueResult.queuedCount > 0,
        queuedCount: queueResult.queuedCount,
        estimatedTime: queueResult.estimatedTime
      });

      return new Response(
        JSON.stringify({
          success: true,
          message: queueResult.queuedCount > 0 
            ? `Started processing ${queueResult.queuedCount} alarms (estimated ${queueResult.estimatedTime} minutes)`
            : 'No pending items in queue',
          queuedCount: queueResult.queuedCount,
          estimatedTime: queueResult.estimatedTime,
          queueEmpty: queueResult.queuedCount === 0,
          processingMode: 'async'
        }),
        { 
          status: 200, 
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      );
    }

    // Validate alarmId is provided for specific alarm processing
    if (!requestBody.alarmId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'alarmId is required for specific alarm processing'
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

    console.log(`Starting alarm audio generation for alarm: ${requestBody.alarmId}`);

    // Log function invocation
    await logEvent(
      'alarm_audio_generation_started',
      undefined,
      {
        alarm_id: requestBody.alarmId,
        force_regenerate: requestBody.forceRegenerate || false,
        function_name: FUNCTION_NAME,
        request_id: requestId
      }
    );

    // Generate alarm audio
    const result = await alarmAudioService.generateAlarmAudio(
      requestBody.alarmId, 
      requestBody.forceRegenerate || false
    );

    // Log successful completion
    await logEvent(
      'alarm_audio_generation_completed',
      undefined,
      {
        alarm_id: requestBody.alarmId,
        generated_clips: result.generatedClips.length,
        failed_clips: result.failedClips.length,
        function_name: FUNCTION_NAME,
        request_id: requestId
      }
    );

    console.log(`Alarm audio generation completed for alarm: ${requestBody.alarmId}`, {
      success: result.success,
      generatedCount: result.generatedClips.length,
      failedCount: result.failedClips.length
    });

    logFunctionEnd(FUNCTION_NAME, { 
      requestId, 
      alarmId: requestBody.alarmId,
      generatedCount: result.generatedClips.length,
      failedCount: result.failedClips.length
    });

    return new Response(
      JSON.stringify(result),
      {
        status: result.success ? 200 : 207, // 207 for partial success
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
        error: `Internal server error: ${(error as Error).message}`,
        generatedClips: [],
        failedClips: [],
        alarmId: requestBody?.alarmId,
        userId: undefined
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