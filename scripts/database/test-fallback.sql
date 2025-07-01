-- Test Fallback Logic
-- Run this in your Supabase SQL Editor to verify fallback functionality

-- Check if fallback data was used in recent executions
SELECT 
  id,
  event_type,
  meta->>'fallback_used' as fallback_used,
  meta->>'api_results' as api_results,
  meta->>'execution_time_ms' as execution_time_ms,
  created_at
FROM logs 
WHERE event_type = 'daily_content_function_started'
  AND meta->>'fallback_used' IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- Check recent daily_content entries to see if fallback data was used
SELECT 
  id,
  date,
  headline,
  sports_summary,
  stocks_summary,
  created_at
FROM daily_content 
ORDER BY created_at DESC 
LIMIT 5;

-- Check for any recent API failures that might trigger fallback
SELECT 
  id,
  event_type,
  meta->>'api_results' as api_results,
  meta->>'status' as status,
  created_at
FROM logs 
WHERE event_type = 'daily_content_function_started'
  AND meta->>'status' = 'success'
  AND (
    meta->>'api_results'->>'news'->>'success' = 'false' OR
    meta->>'api_results'->>'sports'->>'success' = 'false' OR
    meta->>'api_results'->>'stocks'->>'success' = 'false'
  )
ORDER BY created_at DESC
LIMIT 10; 