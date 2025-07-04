-- Check if required tables exist in production
-- Run this against your production database

-- Check logs table
SELECT 
    'logs' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'logs'
    ) as exists
UNION ALL
-- Check daily_content table
SELECT 
    'daily_content' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'daily_content'
    ) as exists
UNION ALL
-- Check users table
SELECT 
    'users' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
    ) as exists
UNION ALL
-- Check user_preferences table
SELECT 
    'user_preferences' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_preferences'
    ) as exists
UNION ALL
-- Check alarms table
SELECT 
    'alarms' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'alarms'
    ) as exists
UNION ALL
-- Check audio table
SELECT 
    'audio' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'audio'
    ) as exists
UNION ALL
-- Check audio_files table
SELECT 
    'audio_files' as table_name,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'audio_files'
    ) as exists;

-- Also check table columns for daily_content
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'daily_content'
ORDER BY ordinal_position; 