-- Check Alert Logs
-- Run this in your Supabase SQL Editor to see all alerts

-- View all alert-related log entries
SELECT 
  id,
  event_type,
  meta->>'message' as alert_message,
  meta->>'error' as error_details,
  meta->>'execution_time_ms' as execution_time,
  meta->>'timestamp' as alert_timestamp,
  created_at
FROM logs 
WHERE event_type IN (
  'daily_content_health_alert',
  'daily_content_function_started'
)
  AND (
    meta->>'status' = 'error' 
    OR event_type = 'daily_content_health_alert'
    OR (meta->>'execution_time_ms' IS NOT NULL AND (meta->>'execution_time_ms')::int > 30000)
  )
ORDER BY created_at DESC
LIMIT 20;

-- Check for timeout alerts specifically
SELECT 
  id,
  event_type,
  meta->>'message' as alert_message,
  meta->>'execution_time_ms' as execution_time_ms,
  created_at
FROM logs 
WHERE event_type = 'daily_content_function_started'
  AND meta->>'execution_time_ms' IS NOT NULL
  AND (meta->>'execution_time_ms')::int > 30000
ORDER BY created_at DESC
LIMIT 10;

-- Check for health alerts (missed executions)
SELECT 
  id,
  event_type,
  meta->>'message' as alert_message,
  meta->>'last_execution' as last_execution,
  meta->>'current_time' as alert_time,
  created_at
FROM logs 
WHERE event_type = 'daily_content_health_alert'
ORDER BY created_at DESC
LIMIT 10;

-- Check for function failures
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