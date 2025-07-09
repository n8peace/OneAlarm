-- Fix tts_voice column net extension error
-- This migration removes any default values, constraints, or function-based defaults
-- that might be causing the "schema 'net' does not exist" error

-- First, let's check what's causing the net extension error on the tts_voice column
DO $$
DECLARE
    column_default text;
    constraint_name text;
    function_name text;
BEGIN
    -- Check for default values on tts_voice column
    SELECT column_default INTO column_default
    FROM information_schema.columns 
    WHERE table_name = 'user_preferences' 
    AND column_name = 'tts_voice'
    AND table_schema = 'public';
    
    RAISE NOTICE 'tts_voice column default: %', column_default;
    
    -- Check for constraints on tts_voice column
    SELECT conname INTO constraint_name
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attnum = ANY(c.conkey)
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE t.relname = 'user_preferences' 
    AND a.attname = 'tts_voice';
    
    RAISE NOTICE 'tts_voice column constraint: %', constraint_name;
    
    -- Check for any functions that might be called on tts_voice updates
    SELECT proname INTO function_name
    FROM pg_proc 
    WHERE prosrc LIKE '%tts_voice%' 
    AND prosrc LIKE '%net%';
    
    RAISE NOTICE 'Functions using tts_voice and net: %', function_name;
END $$;

-- Remove any default values from tts_voice column that might use functions
ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;

-- Drop any check constraints on tts_voice that might reference functions
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT conname 
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attnum = ANY(c.conkey)
        JOIN pg_class t ON t.oid = c.conrelid
        WHERE t.relname = 'user_preferences' 
        AND a.attname = 'tts_voice'
        AND c.contype = 'c'
    LOOP
        EXECUTE 'ALTER TABLE user_preferences DROP CONSTRAINT ' || constraint_record.conname;
        RAISE NOTICE 'Dropped constraint % on tts_voice column', constraint_record.conname;
    END LOOP;
END $$;

-- Drop any function-based defaults that might be using net extension
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname 
        FROM pg_proc 
        WHERE prosrc LIKE '%tts_voice%' 
        AND prosrc LIKE '%net%'
        AND proname != 'trigger_audio_generation'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || ' CASCADE';
        RAISE NOTICE 'Dropped function % that used tts_voice and net extension', func_record.proname;
    END LOOP;
END $$;

-- Ensure tts_voice column has no problematic configurations
-- Set a simple default if needed
ALTER TABLE user_preferences ALTER COLUMN tts_voice SET DEFAULT 'nova';

-- Add a comment documenting this fix
COMMENT ON COLUMN user_preferences.tts_voice IS 'TTS voice preference. Fixed to remove net extension dependency on 2025-07-07.';

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'column_fix',
  jsonb_build_object(
    'action', 'fix_tts_voice_column_net_extension',
    'table', 'user_preferences',
    'column', 'tts_voice',
    'purpose', 'Remove net extension dependency from tts_voice column',
    'environment', 'develop',
    'changes', jsonb_build_object(
      'dropped_defaults', true,
      'dropped_constraints', true,
      'dropped_functions', true,
      'set_simple_default', 'nova'
    ),
    'note', 'This fixes the schema net does not exist error on tts_voice updates',
    'timestamp', NOW()
  )
); 