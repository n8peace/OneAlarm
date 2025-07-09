-- OneAlarm Trigger Check Queries
-- Run these in the Supabase Dashboard SQL Editor

-- ============================================================================
-- QUERY 1: Check total trigger count
-- ============================================================================
SELECT 
    COUNT(*) as total_triggers,
    'Current Environment' as environment
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- ============================================================================
-- QUERY 2: List all triggers with details
-- ============================================================================
SELECT 
    trigger_name,
    event_object_table as table_name,
    event_manipulation as event_type,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;

-- ============================================================================
-- QUERY 3: Check specific key triggers (FIXED)
-- ============================================================================
SELECT 
    expected_triggers.trigger_name,
    CASE 
        WHEN actual_triggers.trigger_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM (
    SELECT 'update_users_updated_at' as trigger_name
    UNION ALL SELECT 'update_user_preferences_updated_at'
    UNION ALL SELECT 'update_alarms_updated_at'
    UNION ALL SELECT 'update_daily_content_updated_at'
    UNION ALL SELECT 'update_audio_files_updated_at'
    UNION ALL SELECT 'update_audio_updated_at'
    UNION ALL SELECT 'trigger_sync_auth_to_public_user'
    UNION ALL SELECT 'on_auth_user_created'
    UNION ALL SELECT 'calculate_next_trigger_trigger'
    UNION ALL SELECT 'alarm_audio_queue_trigger'
    UNION ALL SELECT 'on_preferences_updated'
    UNION ALL SELECT 'on_preferences_inserted'
    UNION ALL SELECT 'on_audio_status_change'
) expected_triggers
LEFT JOIN information_schema.triggers actual_triggers 
    ON expected_triggers.trigger_name = actual_triggers.trigger_name
    AND actual_triggers.trigger_schema = 'public'
ORDER BY expected_triggers.trigger_name;

-- ============================================================================
-- QUERY 4: Check trigger functions
-- ============================================================================
SELECT 
    routine_name as function_name,
    routine_type,
    '✅ EXISTS' as status
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'update_updated_at_column',
    'sync_auth_to_public_user',
    'handle_new_user',
    'calculate_next_trigger',
    'queue_audio_generation',
    'trigger_audio_generation',
    'handle_audio_status_change'
)
ORDER BY routine_name;

-- ============================================================================
-- QUERY 5: Summary comparison
-- ============================================================================
SELECT 
    'TRIGGER SUMMARY' as summary_type,
    COUNT(*) as count,
    'triggers found' as description
FROM information_schema.triggers 
WHERE trigger_schema = 'public'

UNION ALL

SELECT 
    'FUNCTION SUMMARY',
    COUNT(*) as count,
    'functions found' as description
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'

UNION ALL

SELECT 
    'TABLE SUMMARY',
    COUNT(*) as count,
    'tables found' as description
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'; 