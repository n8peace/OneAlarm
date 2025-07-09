-- Sync Development Environment to Match Production
-- Run this in the Supabase Dashboard SQL Editor on the develop branch

-- ============================================================================
-- STEP 1: Update trigger functions to match production
-- ============================================================================

-- Update queue_audio_generation to match production's manage_alarm_audio_queue
CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
    -- Queue audio generation 58 minutes before alarm
    INSERT INTO audio_generation_queue (
        alarm_id, 
        user_id, 
        scheduled_for, 
        status, 
        priority
    ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        0
    )
    ON CONFLICT (alarm_id) DO UPDATE SET
        scheduled_for = EXCLUDED.scheduled_for,
        status = 'pending',
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update handle_audio_status_change to match production's log_offline_issue
CREATE OR REPLACE FUNCTION log_offline_issue()
RETURNS TRIGGER AS $$
BEGIN
    -- Log audio status changes
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO logs (event_type, user_id, meta) VALUES (
            'audio_status_changed',
            NEW.user_id,
            jsonb_build_object(
                'audio_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'audio_type', NEW.audio_type,
                'action', 'status_change_logged'
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 2: Update triggers to match production naming and functions
-- ============================================================================

-- Update alarm_audio_queue_trigger to use manage_alarm_audio_queue
DROP TRIGGER IF EXISTS alarm_audio_queue_trigger ON alarms;
CREATE TRIGGER alarm_audio_queue_trigger
    AFTER INSERT OR UPDATE OR DELETE ON alarms
    FOR EACH ROW EXECUTE FUNCTION manage_alarm_audio_queue();

-- Update on_audio_status_change to use log_offline_issue
DROP TRIGGER IF EXISTS on_audio_status_change ON audio;
CREATE TRIGGER on_audio_status_change
    AFTER UPDATE ON audio
    FOR EACH ROW EXECUTE FUNCTION log_offline_issue();

-- Update user preferences triggers to match production naming
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;
CREATE TRIGGER trigger_audio_generation_on_preferences_insert
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
CREATE TRIGGER trigger_audio_generation_on_preferences_update
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- Add missing update_audio_updated_at trigger (if it doesn't exist)
DROP TRIGGER IF EXISTS update_audio_updated_at ON audio;
CREATE TRIGGER update_audio_updated_at
    BEFORE UPDATE ON audio
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 3: Verify the sync
-- ============================================================================

-- Check trigger count
SELECT 
    COUNT(*) as total_triggers,
    'Development Environment' as environment
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- List all triggers
SELECT 
    trigger_name,
    event_object_table as table_name,
    event_manipulation as event_type,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name; 