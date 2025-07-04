-- Verification script to check that production schema matches development
-- Run this after applying the migration to verify all changes were applied correctly

-- Check alarms table new columns
SELECT 
    'alarms table' as table_name,
    'active column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'alarms' AND column_name = 'active'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'alarms table' as table_name,
    'is_overridden column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'alarms' AND column_name = 'is_overridden'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'alarms table' as table_name,
    'timezone_at_creation column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'alarms' AND column_name = 'timezone_at_creation'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'alarms table' as table_name,
    'user_id is nullable' as check_name,
    CASE WHEN is_nullable = 'YES' THEN 'PASS' ELSE 'FAIL' END as status
FROM information_schema.columns 
WHERE table_name = 'alarms' AND column_name = 'user_id'

UNION ALL

-- Check audio table new columns
SELECT 
    'audio table' as table_name,
    'script_text column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'audio' AND column_name = 'script_text'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'audio table' as table_name,
    'status column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'audio' AND column_name = 'status'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'audio table' as table_name,
    'user_id is nullable' as check_name,
    CASE WHEN is_nullable = 'YES' THEN 'PASS' ELSE 'FAIL' END as status
FROM information_schema.columns 
WHERE table_name = 'audio' AND column_name = 'user_id'

UNION ALL

-- Check user_preferences new columns
SELECT 
    'user_preferences table' as table_name,
    'sports_team column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' AND column_name = 'sports_team'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'user_preferences table' as table_name,
    'stocks column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' AND column_name = 'stocks'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'user_preferences table' as table_name,
    'onboarding_completed column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' AND column_name = 'onboarding_completed'
    ) THEN 'PASS' ELSE 'FAIL' END as status

UNION ALL

-- Check users table new columns
SELECT 
    'users table' as table_name,
    'phone column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'phone'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'users table' as table_name,
    'subscription_status column exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'subscription_status'
    ) THEN 'PASS' ELSE 'FAIL' END as status
UNION ALL
SELECT 
    'users table' as table_name,
    'email is nullable' as check_name,
    CASE WHEN is_nullable = 'YES' THEN 'PASS' ELSE 'FAIL' END as status
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'email'

UNION ALL

-- Check logs table UUID primary key
SELECT 
    'logs table' as table_name,
    'id is UUID type' as check_name,
    CASE WHEN data_type = 'uuid' THEN 'PASS' ELSE 'FAIL' END as status
FROM information_schema.columns 
WHERE table_name = 'logs' AND column_name = 'id'

ORDER BY table_name, check_name; 