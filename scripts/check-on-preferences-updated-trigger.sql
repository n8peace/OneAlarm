-- SQL Queries to Check on_preferences_updated Trigger
-- Run these in your Supabase SQL Editor for each environment

-- ============================================================================
-- QUERY 1: Check if on_preferences_updated trigger exists
-- ============================================================================
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    action_orientation
FROM information_schema.triggers 
WHERE trigger_name = 'on_preferences_updated'
AND event_object_table = 'user_preferences';

-- ============================================================================
-- QUERY 2: Get the complete trigger definition
-- ============================================================================
SELECT 
    schemaname,
    tablename,
    triggername,
    proname as function_name,
    tgtype,
    tgenabled,
    tgisinternal,
    tgdeferrable,
    tginitdeferred,
    tgnargs,
    tgattr,
    tgargs,
    tgqual,
    tgrelid,
    tgfoid,
    tgconstrrelid,
    tgconstrindid,
    tgconstraint,
    tgdeferrable,
    tginitdeferred,
    tgnargs,
    tgattr,
    tgargs,
    tgqual
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'user_preferences' 
AND t.tgname = 'on_preferences_updated';

-- ============================================================================
-- QUERY 3: Get the function that the trigger calls
-- ============================================================================
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition,
    p.prosrc as function_source
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'user_preferences' 
AND t.tgname = 'on_preferences_updated';

-- ============================================================================
-- QUERY 4: Check what the trigger function does (HTTP vs Queue)
-- ============================================================================
SELECT 
    p.proname as function_name,
    CASE 
        WHEN p.prosrc LIKE '%net.http_post%' THEN 'USES HTTP CALLS'
        WHEN p.prosrc LIKE '%audio_generation_queue%' THEN 'USES QUEUE'
        WHEN p.prosrc LIKE '%http_post%' THEN 'USES HTTP POST'
        ELSE 'OTHER APPROACH'
    END as approach,
    CASE 
        WHEN p.prosrc LIKE '%joyavvleaxqzksopnmjs%' THEN 'MAIN ENVIRONMENT URL'
        WHEN p.prosrc LIKE '%xqkmpkfqoisqzznnvlox%' THEN 'DEVELOP ENVIRONMENT URL'
        ELSE 'NO URL FOUND'
    END as environment_url
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'user_preferences' 
AND t.tgname = 'on_preferences_updated';

-- ============================================================================
-- QUERY 5: Get the complete CREATE TRIGGER statement
-- ============================================================================
SELECT 
    'CREATE TRIGGER ' || t.tgname || 
    ' AFTER ' || 
    CASE 
        WHEN t.tgtype & 66 = 2 THEN 'INSERT'
        WHEN t.tgtype & 66 = 4 THEN 'DELETE' 
        WHEN t.tgtype & 66 = 8 THEN 'UPDATE'
        WHEN t.tgtype & 66 = 10 THEN 'INSERT OR DELETE'
        WHEN t.tgtype & 66 = 12 THEN 'DELETE OR UPDATE'
        WHEN t.tgtype & 66 = 14 THEN 'INSERT OR UPDATE'
        WHEN t.tgtype & 66 = 16 THEN 'INSERT OR DELETE OR UPDATE'
    END ||
    ' ON ' || c.relname ||
    ' FOR EACH ROW EXECUTE FUNCTION ' || p.proname || '();' as create_trigger_statement
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'user_preferences' 
AND t.tgname = 'on_preferences_updated';

-- ============================================================================
-- QUERY 6: Check trigger conditions and logic
-- ============================================================================
SELECT 
    p.proname as function_name,
    CASE 
        WHEN p.prosrc LIKE '%OLD.tts_voice IS DISTINCT FROM NEW.tts_voice%' THEN 'CHECKS TTS VOICE CHANGES'
        ELSE 'NO TTS VOICE CHECK'
    END as tts_voice_check,
    CASE 
        WHEN p.prosrc LIKE '%OLD.preferred_name IS DISTINCT FROM NEW.preferred_name%' THEN 'CHECKS PREFERRED NAME CHANGES'
        ELSE 'NO PREFERRED NAME CHECK'
    END as preferred_name_check,
    CASE 
        WHEN p.prosrc LIKE '%TG_OP = %INSERT%' THEN 'HANDLES INSERT OPERATIONS'
        ELSE 'NO INSERT HANDLING'
    END as insert_handling
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'user_preferences' 
AND t.tgname = 'on_preferences_updated';

-- ============================================================================
-- QUERY 7: Comprehensive trigger analysis
-- ============================================================================
WITH trigger_analysis AS (
    SELECT 
        t.tgname as trigger_name,
        c.relname as table_name,
        p.proname as function_name,
        p.prosrc as function_source,
        pg_get_functiondef(p.oid) as function_definition
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_proc p ON t.tgfoid = p.oid
    WHERE c.relname = 'user_preferences' 
    AND t.tgname = 'on_preferences_updated'
)
SELECT 
    trigger_name,
    table_name,
    function_name,
    CASE 
        WHEN function_source LIKE '%net.http_post%' THEN 'HTTP CALLS'
        WHEN function_source LIKE '%audio_generation_queue%' THEN 'QUEUE BASED'
        WHEN function_source LIKE '%http_post%' THEN 'HTTP POST'
        ELSE 'OTHER'
    END as approach,
    CASE 
        WHEN function_source LIKE '%joyavvleaxqzksopnmjs%' THEN 'MAIN'
        WHEN function_source LIKE '%xqkmpkfqoisqzznnvlox%' THEN 'DEVELOP'
        ELSE 'UNKNOWN'
    END as environment,
    CASE 
        WHEN function_source LIKE '%OLD.tts_voice IS DISTINCT FROM NEW.tts_voice%' THEN 'YES'
        ELSE 'NO'
    END as checks_tts_voice,
    CASE 
        WHEN function_source LIKE '%OLD.preferred_name IS DISTINCT FROM NEW.preferred_name%' THEN 'YES'
        ELSE 'NO'
    END as checks_preferred_name
FROM trigger_analysis; 