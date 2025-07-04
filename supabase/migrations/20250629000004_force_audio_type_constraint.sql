-- Force update audio type constraint by completely recreating it
-- This migration uses a more aggressive approach to ensure the constraint is updated

-- Drop ALL constraints on the audio table that might be related to audio_type
DO $$
BEGIN
    -- Drop the specific constraint if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'audio_type_check' 
        AND table_name = 'audio'
    ) THEN
        ALTER TABLE audio DROP CONSTRAINT audio_type_check;
    END IF;
    
    -- Also drop any other check constraints that might be interfering
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'check_audio_type' 
        AND table_name = 'audio'
    ) THEN
        ALTER TABLE audio DROP CONSTRAINT check_audio_type;
    END IF;
END $$;

-- Wait a moment for the constraint to be fully dropped
SELECT pg_sleep(1);

-- Now recreate the constraint with the new allowed types
ALTER TABLE audio ADD CONSTRAINT audio_type_check 
    CHECK (audio_type IN (
        'weather', 'content', 'general', 'combined', 
        'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3',
        'test_clip'
    ));

-- Verify the constraint was created
DO $$
DECLARE
    constraint_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'audio_type_check' 
        AND table_name = 'audio'
    ) INTO constraint_exists;
    
    IF NOT constraint_exists THEN
        RAISE EXCEPTION 'Constraint was not created successfully';
    END IF;
END $$;

-- Log the change
INSERT INTO logs (event_type, meta)
VALUES (
    'audio_type_constraint_forced_update',
    jsonb_build_object(
        'action', 'force_audio_type_constraint_update',
        'added_type', 'test_clip',
        'reason', 'Force constraint update with aggressive approach',
        'allowed_types', ARRAY['weather', 'content', 'general', 'combined', 'wake_up_message_1', 'wake_up_message_2', 'wake_up_message_3', 'test_clip'],
        'migration_id', '20250629000004_force_audio_type_constraint',
        'constraint_verified', true,
        'updated_at', NOW()
    )
); 