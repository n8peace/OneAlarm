-- Check trigger and function status for audio generation
-- This script verifies if the user_preferences_audio_trigger exists and is working

-- 1. Check if the trigger function exists
SELECT 
    'trigger_audio_generation function' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'trigger_audio_generation'
        ) THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- 2. Check if the triggers exist
SELECT 
    'on_preferences_updated trigger' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'on_preferences_updated' 
            AND tgrelid = 'user_preferences'::regclass
        ) THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

SELECT 
    'on_preferences_inserted trigger' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'on_preferences_inserted' 
            AND tgrelid = 'user_preferences'::regclass
        ) THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- 3. Check if net extension is installed
SELECT 
    'net.http extension' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_extension 
            WHERE extname = 'http' 
            AND extnamespace = 'net'::regnamespace
        ) THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- 4. Check recent logs for trigger activity
SELECT 
    'Recent trigger logs' as check_item,
    COUNT(*) as log_count
FROM logs 
WHERE event_type = 'preferences_updated_audio_trigger' 
    AND created_at > NOW() - INTERVAL '24 hours';

-- 5. Show recent trigger logs
SELECT 
    event_type,
    user_id,
    created_at,
    meta
FROM logs 
WHERE event_type = 'preferences_updated_audio_trigger' 
    AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 5; 