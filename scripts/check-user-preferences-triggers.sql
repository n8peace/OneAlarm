-- Check user_preferences table triggers
-- This will show us what triggers exist and if they use net extension

-- Check all triggers on user_preferences table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'user_preferences'
ORDER BY trigger_name;

-- Check trigger function definitions
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN (
    SELECT DISTINCT action_statement 
    FROM information_schema.triggers 
    WHERE event_object_table = 'user_preferences'
    AND action_statement LIKE '%()'
);

-- Check if any triggers reference net extension
SELECT 
    trigger_name,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%net.%' THEN 'USES NET EXTENSION'
        ELSE 'NO NET EXTENSION'
    END as net_usage
FROM information_schema.triggers 
WHERE event_object_table = 'user_preferences'; 