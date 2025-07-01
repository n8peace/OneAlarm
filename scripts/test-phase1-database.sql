-- Phase 1 Database Test Script
-- This script verifies that all database changes from Phase 1 are working correctly

-- Test 1: Verify weather_data table structure and data
SELECT 'Test 1: Weather Data Table' as test_name;
SELECT 
    user_id,
    location,
    current_temp,
    high_temp,
    low_temp,
    condition,
    sunrise_time,
    sunset_time,
    updated_at
FROM weather_data 
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
ORDER BY user_id;

-- Test 2: Verify alarms table has correct data type and data
SELECT 'Test 2: Alarms Table' as test_name;
SELECT 
    id,
    user_id,
    alarm_time,
    pg_typeof(alarm_time) as alarm_time_type
FROM alarms 
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
ORDER BY user_id, alarm_time;

-- Test 3: Verify audio_generation_queue was populated by trigger
SELECT 'Test 3: Audio Generation Queue' as test_name;
SELECT 
    id,
    alarm_id,
    user_id,
    scheduled_for,
    status,
    retry_count,
    created_at,
    -- Verify scheduled_for is 25 minutes before alarm_time
    (scheduled_for + INTERVAL '25 minutes') as expected_alarm_time
FROM audio_generation_queue 
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
ORDER BY user_id, created_at;

-- Test 4: Verify audio table extensions
SELECT 'Test 4: Audio Table Extensions' as test_name;
SELECT 
    id,
    user_id,
    alarm_id,
    audio_type,
    expires_at,
    generated_at
FROM audio 
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
ORDER BY user_id, generated_at DESC;

-- Test 5: Verify user_preferences structure
SELECT 'Test 5: User Preferences Structure' as test_name;
SELECT 
    user_id,
    tts_voice,
    preferred_name
FROM user_preferences 
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
ORDER BY user_id;

-- Test 6: Verify trigger function exists
SELECT 'Test 6: Trigger Function' as test_name;
SELECT 
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname = 'manage_alarm_audio_queue';

-- Test 7: Verify trigger exists
SELECT 'Test 7: Trigger' as test_name;
SELECT 
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgfoid::regproc as function_name
FROM pg_trigger 
WHERE tgname = 'alarm_audio_queue_trigger';

-- Test 8: Test trigger functionality with a new alarm
SELECT 'Test 8: Trigger Functionality Test' as test_name;
-- Insert a test alarm and verify queue entry is created
INSERT INTO alarms (id, user_id, alarm_time)
VALUES (gen_random_uuid(), '85967fcc-c2f9-4919-8e67-55124d29ef80', NOW() + INTERVAL '30 minutes')
RETURNING id, user_id, alarm_time;

-- Check if queue entry was created
SELECT 
    'Queue entry created for test alarm' as test_result,
    COUNT(*) as queue_entries
FROM audio_generation_queue 
WHERE user_id = '85967fcc-c2f9-4919-8e67-55124d29ef80' 
AND created_at > NOW() - INTERVAL '5 minutes';

-- Test 9: Verify indexes exist
SELECT 'Test 9: Indexes' as test_name;
SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('weather_data', 'audio_generation_queue', 'audio')
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Test 10: Summary report
SELECT 'Test 10: Phase 1 Summary' as test_name;
SELECT 
    'weather_data' as table_name,
    COUNT(*) as record_count
FROM weather_data
UNION ALL
SELECT 
    'alarms' as table_name,
    COUNT(*) as record_count
FROM alarms
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
UNION ALL
SELECT 
    'audio_generation_queue' as table_name,
    COUNT(*) as record_count
FROM audio_generation_queue
WHERE user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
)
UNION ALL
SELECT 
    'audio (with alarm_id)' as table_name,
    COUNT(*) as record_count
FROM audio
WHERE alarm_id IS NOT NULL
AND user_id IN (
    '85967fcc-c2f9-4919-8e67-55124d29ef80',
    '5a363c6c-3316-42d3-8f25-ac067434a013',
    '5f069196-36d3-4ff7-a3c0-f7da307d2a64'
); 