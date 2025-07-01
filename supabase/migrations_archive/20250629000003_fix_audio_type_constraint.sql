-- Fix audio type constraint to include 'test_clip'
-- This migration ensures the constraint is properly dropped and recreated

-- First, let's check if the constraint exists and drop it
DO $$
BEGIN
    -- Drop the constraint if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'audio_type_check' 
        AND table_name = 'audio'
    ) THEN
        ALTER TABLE audio DROP CONSTRAINT audio_type_check;
    END IF;
END $$;

-- Now recreate the constraint with 'test_clip' included
ALTER TABLE audio ADD CONSTRAINT audio_type_check 
    CHECK (audio_type IN (
        'weather', 'content', 'general', 'combined', 
        'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3',
        'test_clip'
    ));

-- Log the change
INSERT INTO logs (event_type, meta)
VALUES (
    'audio_type_constraint_fixed',
    jsonb_build_object(
        'action', 'fix_audio_type_constraint',
        'added_type', 'test_clip',
        'reason', 'Ensure test_clip is allowed for testing purposes',
        'allowed_types', ARRAY['weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', 'test_clip'],
        'migration_id', '20250629000003_fix_audio_type_constraint',
        'updated_at', NOW()
    )
); 