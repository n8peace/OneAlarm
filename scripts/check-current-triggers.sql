-- Check current triggers in both environments
-- Run this in each environment's SQL Editor to see what actually exists

-- ============================================================================
-- QUERY 1: Check all triggers on user_preferences table
-- ============================================================================
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    action_orientation
FROM information_schema.triggers 
WHERE event_object_table = 'user_preferences'
ORDER BY trigger_name;

-- ============================================================================
-- QUERY 2: Check if specific triggers exist
-- ============================================================================
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'on_preferences_inserted' 
            AND event_object_table = 'user_preferences'
        ) THEN 'EXISTS'
        ELSE 'DOES NOT EXIST'
    END as on_preferences_inserted_status,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'on_preferences_updated' 
            AND event_object_table = 'user_preferences'
        ) THEN 'EXISTS'
        ELSE 'DOES NOT EXIST'
    END as on_preferences_updated_status;

-- ============================================================================
-- QUERY 3: Get detailed trigger information
-- ============================================================================
SELECT 
    t.trigger_name,
    t.event_manipulation,
    t.action_statement,
    p.proname as function_name,
    CASE 
        WHEN p.prosrc LIKE '%net.http_post%' THEN 'USES HTTP CALLS'
        WHEN p.prosrc LIKE '%audio_generation_queue%' THEN 'USES QUEUE'
        ELSE 'OTHER APPROACH'
    END as function_approach,
    CASE 
        WHEN p.prosrc LIKE '%joyavvleaxqzksopnmjs%' THEN 'MAIN ENVIRONMENT URL'
        WHEN p.prosrc LIKE '%xqkmpkfqoisqzznnvlox%' THEN 'DEVELOP ENVIRONMENT URL'
        ELSE 'NO URL FOUND'
    END as environment_url
FROM information_schema.triggers t
LEFT JOIN pg_proc p ON p.proname = split_part(t.action_statement, '(', 1)
WHERE t.event_object_table = 'user_preferences'
ORDER BY t.trigger_name; 