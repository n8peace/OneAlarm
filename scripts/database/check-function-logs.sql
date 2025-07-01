-- Check Function Execution Logs
-- Run this in your Supabase SQL Editor to see function runs

-- Check recent function executions
SELECT 
  id,
  event_type,
  meta->>'function_name' as function_name,
  meta->>'status' as status,
  meta->>'execution_time_ms' as execution_time_ms,
  meta->>'start_time' as start_time,
  meta->>'end_time' as end_time,
  meta->>'error_message' as error_message,
  created_at
FROM logs 
WHERE event_type IN (
  'daily_content_function_started',
  'daily_content_health_alert'
)
ORDER BY created_at DESC
LIMIT 20;

-- Check API results from recent runs
SELECT 
  id,
  event_type,
  meta->>'api_results' as api_results,
  meta->>'execution_time_ms' as execution_time_ms,
  created_at
FROM logs 
WHERE event_type = 'daily_content_function_started'
  AND meta->>'status' = 'success'
ORDER BY created_at DESC
LIMIT 5;

-- Check for any errors
SELECT 
  id,
  event_type,
  meta->>'error_message' as error_message,
  meta->>'execution_time_ms' as execution_time_ms,
  created_at
FROM logs 
WHERE event_type = 'daily_content_function_started'
  AND meta->>'status' = 'error'
ORDER BY created_at DESC
LIMIT 10; 