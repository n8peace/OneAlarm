-- Schema Validation Script for OneAlarm Database
-- Run this against your Supabase database to validate the schema matches documentation

-- 1. Check all tables exist
SELECT 'Table Check' as check_type, 
       tablename as object_name,
       CASE WHEN tablename IN (
         'users', 'user_preferences', 'alarms', 'logs', 'daily_content', 
         'audio', 'weather_data', 'audio_generation_queue', 'user_events'
       ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Validate audio table columns
SELECT 'Audio Table Columns' as check_type,
       column_name as object_name,
       CASE 
         WHEN column_name = 'audio_type' AND data_type = 'character varying' THEN '✅ CORRECT'
         WHEN column_name = 'alarm_id' AND data_type = 'uuid' THEN '✅ CORRECT'
         WHEN column_name = 'expires_at' AND data_type = 'timestamp with time zone' THEN '✅ CORRECT'
         ELSE '⚠️  CHECK' 
       END as status
FROM information_schema.columns 
WHERE table_name = 'audio' AND table_schema = 'public'
  AND column_name IN ('audio_type', 'alarm_id', 'expires_at');

-- 3. Validate weather_data table columns
SELECT 'Weather Table Columns' as check_type,
       column_name as object_name,
       CASE 
         WHEN column_name = 'current_temp' AND data_type = 'integer' THEN '✅ CORRECT'
         WHEN column_name = 'high_temp' AND data_type = 'integer' THEN '✅ CORRECT'
         WHEN column_name = 'low_temp' AND data_type = 'integer' THEN '✅ CORRECT'
         WHEN column_name = 'sunrise_time' AND data_type = 'time without time zone' THEN '✅ CORRECT'
         WHEN column_name = 'sunset_time' AND data_type = 'time without time zone' THEN '✅ CORRECT'
         ELSE '⚠️  CHECK' 
       END as status
FROM information_schema.columns 
WHERE table_name = 'weather_data' AND table_schema = 'public'
  AND column_name IN ('current_temp', 'high_temp', 'low_temp', 'sunrise_time', 'sunset_time');

-- 4. Validate alarms table timezone columns
SELECT 'Alarms Table Columns' as check_type,
       column_name as object_name,
       CASE 
         WHEN column_name = 'alarm_time_local' AND data_type = 'time without time zone' THEN '✅ CORRECT'
         WHEN column_name = 'alarm_timezone' AND data_type = 'text' THEN '✅ CORRECT'
         WHEN column_name = 'next_trigger_at' AND data_type = 'timestamp with time zone' THEN '✅ CORRECT'
         ELSE '⚠️  CHECK' 
       END as status
FROM information_schema.columns 
WHERE table_name = 'alarms' AND table_schema = 'public'
  AND column_name IN ('alarm_time_local', 'alarm_timezone', 'next_trigger_at');

-- 5. Check audio_type constraint
SELECT 'Audio Type Constraint' as check_type,
       constraint_name as object_name,
       CASE 
         WHEN constraint_name = 'check_audio_type' THEN '✅ EXISTS'
         ELSE '❌ MISSING' 
       END as status
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public' 
  AND constraint_name = 'check_audio_type';

-- 6. Check timezone constraint
SELECT 'Timezone Constraint' as check_type,
       constraint_name as object_name,
       CASE 
         WHEN constraint_name = 'check_valid_alarm_timezone' THEN '✅ CORRECT - Timezone constraint exists'
         ELSE '⚠️  UNKNOWN - Check constraint'
       END as status
FROM information_schema.check_constraints 
WHERE constraint_name = 'check_valid_alarm_timezone';

-- 7. Check important indexes
SELECT 'Indexes' as check_type,
       indexname as object_name,
       CASE 
         WHEN indexname LIKE 'idx_audio_%' THEN '✅ EXISTS'
         WHEN indexname LIKE 'idx_weather_%' THEN '✅ EXISTS'
         WHEN indexname LIKE 'idx_alarms_%' THEN '✅ EXISTS'
         WHEN indexname LIKE 'idx_audio_queue_%' THEN '✅ EXISTS'
         ELSE '⚠️  CHECK' 
       END as status
FROM pg_indexes 
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY indexname;

-- 8. Check triggers
SELECT 'Triggers' as check_type,
       trigger_name as object_name,
       CASE 
         WHEN trigger_name = 'calculate_next_trigger_trigger' THEN '✅ EXISTS'
         WHEN trigger_name = 'alarm_audio_queue_trigger' THEN '✅ EXISTS'
         WHEN trigger_name = 'user_preferences_audio_trigger' THEN '✅ EXISTS'
         ELSE '⚠️  CHECK' 
       END as status
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
  AND trigger_name IN ('calculate_next_trigger_trigger', 'alarm_audio_queue_trigger', 'user_preferences_audio_trigger');

-- 9. Check RLS policies
SELECT 'RLS Policies' as check_type,
       tablename || '.' || policyname as object_name,
       CASE 
         WHEN tablename = 'audio_generation_queue' THEN '✅ EXISTS'
         WHEN tablename = 'weather_data' THEN '✅ EXISTS'
         ELSE '⚠️  CHECK' 
       END as status
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('audio_generation_queue', 'weather_data');

-- 10. Summary
SELECT 'SUMMARY' as check_type,
       'Schema Validation Complete' as object_name,
       'Review results above' as status; 