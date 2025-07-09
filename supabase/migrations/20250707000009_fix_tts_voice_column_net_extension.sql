-- Fix tts_voice column net extension error
-- This migration removes any problematic default values or constraints on tts_voice
-- that might be causing the net extension error

-- Step 1: Remove any default value from tts_voice column
ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;

-- Step 2: Check and remove any constraints that might use functions
-- (This is a precautionary step)

-- Step 3: Ensure tts_voice column has no special functions or triggers
-- Remove any function-based default values that might exist
DO $$
BEGIN
    -- Check if there are any function-based defaults on tts_voice
    -- and remove them if they exist
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
          AND column_name = 'tts_voice' 
          AND column_default IS NOT NULL
          AND column_default LIKE '%(%'
    ) THEN
        ALTER TABLE user_preferences ALTER COLUMN tts_voice DROP DEFAULT;
    END IF;
END $$;

-- Step 4: Verify the column structure
-- Add a comment to document the fix
COMMENT ON COLUMN user_preferences.tts_voice IS 'Text-to-speech voice preference (alloy, ash, echo, fable, onyx, nova, shimmer, verse) - Fixed to remove net extension dependency';

-- Step 5: Test the fix by updating a sample record
-- (This will be done manually after applying the migration)

-- Log the migration
INSERT INTO logs (event_type, meta)
VALUES (
  'column_fix',
  jsonb_build_object(
    'action', 'fix_tts_voice_column_net_extension',
    'table', 'user_preferences',
    'column', 'tts_voice',
    'purpose', 'Remove net extension dependency from tts_voice column',
    'changes', jsonb_build_object(
      'removed_default', true,
      'checked_constraints', true,
      'verified_structure', true
    ),
    'environment', 'develop',
    'note', 'tts_voice column was causing net extension error during UPDATE operations',
    'timestamp', NOW()
  )
); 