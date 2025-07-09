#!/bin/bash

# Complete Sync: Main to Develop Triggers and Functions
# This script syncs all triggers and functions from main to develop
# Removes net.http_post calls and ensures queue-based approach

set -e

echo "=== Complete Sync: Main to Develop Triggers and Functions ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

print_status "info" "This script will sync all triggers and functions from main to develop"
print_status "info" "Key changes:"
echo "  - Remove net.http_post calls from trigger_audio_generation"
echo "  - Use queue-based approach for audio generation"
echo "  - Sync all missing triggers and functions"
echo "  - Ensure both environments work without net extension"
echo ""

read -p "Continue with sync? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "warning" "Sync cancelled"
    exit 0
fi

print_status "info" "Creating comprehensive sync migration..."

# Create the sync migration file
cat > scripts/sync-main-to-develop-complete.sql << 'EOF'
-- Complete Sync: Main to Develop Triggers and Functions
-- This migration syncs all triggers and functions from main to develop
-- Removes net.http_post calls and ensures queue-based approach

-- ============================================================================
-- STEP 1: DROP EXISTING TRIGGERS AND FUNCTIONS
-- ============================================================================

-- Drop user preferences triggers
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;

-- Drop alarm triggers
DROP TRIGGER IF EXISTS alarm_audio_queue_trigger ON alarms;

-- Drop functions
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;
DROP FUNCTION IF EXISTS manage_alarm_audio_queue() CASCADE;
DROP FUNCTION IF EXISTS queue_audio_generation() CASCADE;

-- ============================================================================
-- STEP 2: CREATE QUEUE-BASED TRIGGER FUNCTIONS
-- ============================================================================

-- Create trigger_audio_generation function (queue-based, no net.http_post)
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS $$
BEGIN
  -- For INSERT operations, always trigger since we're creating new preferences
  -- For UPDATE operations, only trigger if key audio-related preferences changed
  IF TG_OP = 'INSERT' OR 
     (TG_OP = 'UPDATE' AND (
       OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
       OLD.preferred_name IS DISTINCT FROM NEW.preferred_name
     )) THEN

    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'operation', TG_OP,
        'old_tts_voice', CASE WHEN TG_OP = 'UPDATE' THEN OLD.tts_voice ELSE NULL END,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', CASE WHEN TG_OP = 'UPDATE' THEN OLD.preferred_name ELSE NULL END,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered',
        'environment', 'develop',
        'approach', 'queue_based_no_net_extension'
      )
    );

    -- Queue audio generation for all active alarms for this user
    -- This avoids hardcoded URLs and allows the queue system to handle it
    INSERT INTO audio_generation_queue (
        alarm_id,
        user_id,
        scheduled_for,
        status,
        priority
    )
    SELECT 
        a.id,
        a.user_id,
        a.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        1  -- Higher priority for preference changes
    FROM alarms a
    WHERE a.user_id = NEW.user_id AND a.active = true
    ON CONFLICT (alarm_id) DO UPDATE SET
        status = 'pending',
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create manage_alarm_audio_queue function (queue-based)
CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Only queue if alarm is active and has a next trigger time
  IF NEW.active = true AND NEW.next_trigger_at IS NOT NULL THEN
    
    -- Log the alarm creation/update
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'alarm_audio_queue_trigger',
      NEW.user_id,
      jsonb_build_object(
        'alarm_id', NEW.id,
        'alarm_name', NEW.name,
        'next_trigger_at', NEW.next_trigger_at,
        'triggered_at', NOW(),
        'action', 'queue_audio_generation',
        'environment', 'develop',
        'approach', 'queue_based_no_net_extension'
      )
    );

    -- Queue audio generation for this alarm
    INSERT INTO audio_generation_queue (
        alarm_id,
        user_id,
        scheduled_for,
        status,
        priority
    )
    VALUES (
        NEW.id,
        NEW.user_id,
        NEW.next_trigger_at - INTERVAL '58 minutes',
        'pending',
        2  -- Normal priority for alarm creation
    )
    ON CONFLICT (alarm_id) DO UPDATE SET
        scheduled_for = EXCLUDED.scheduled_for,
        status = 'pending',
        updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 3: CREATE TRIGGERS
-- ============================================================================

-- User preferences triggers
CREATE TRIGGER on_preferences_updated
  AFTER UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

CREATE TRIGGER on_preferences_inserted
  AFTER INSERT ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

-- Alarm triggers
CREATE TRIGGER alarm_audio_queue_trigger
  AFTER INSERT OR UPDATE ON alarms
  FOR EACH ROW
  EXECUTE FUNCTION manage_alarm_audio_queue();

-- ============================================================================
-- STEP 4: ENSURE REQUIRED TABLES EXIST
-- ============================================================================

-- Create audio_generation_queue table if it doesn't exist
CREATE TABLE IF NOT EXISTS audio_generation_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alarm_id UUID REFERENCES alarms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    priority INTEGER DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(alarm_id)
);

-- Create logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type TEXT NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    meta JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- STEP 5: CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Indexes for audio_generation_queue
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_status ON audio_generation_queue(status);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_scheduled_for ON audio_generation_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_audio_generation_queue_user_id ON audio_generation_queue(user_id);

-- Indexes for logs
CREATE INDEX IF NOT EXISTS idx_logs_event_type ON logs(event_type);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at);

-- ============================================================================
-- STEP 6: LOG THE SYNCHRONIZATION
-- ============================================================================

INSERT INTO logs (event_type, meta)
VALUES (
  'complete_sync_main_to_develop',
  jsonb_build_object(
    'action', 'sync_main_to_develop_triggers',
    'changes', jsonb_build_object(
      'functions_updated', ARRAY['trigger_audio_generation', 'manage_alarm_audio_queue'],
      'triggers_updated', ARRAY['on_preferences_updated', 'on_preferences_inserted', 'alarm_audio_queue_trigger'],
      'tables_ensured', ARRAY['audio_generation_queue', 'logs'],
      'approach', 'queue_based_no_net_extension',
      'removed_net_http_calls', true
    ),
    'environment', 'develop',
    'purpose', 'Sync with main environment and remove net extension dependency',
    'timestamp', NOW()
  )
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Show the updated triggers
SELECT 
    tgrelid::regclass as table_name,
    tgname as trigger_name,
    tgfoid::regproc as function_name
FROM pg_trigger 
WHERE tgrelid::regclass::text LIKE 'public.%'
  AND tgname IN ('on_preferences_updated', 'on_preferences_inserted', 'alarm_audio_queue_trigger')
ORDER BY tgrelid::regclass, tgname;

-- Show the function definitions (without net.http_post)
SELECT 
    proname,
    CASE 
        WHEN prosrc LIKE '%net.http_post%' THEN 'CONTAINS_NET_HTTP_POST'
        ELSE 'QUEUE_BASED_ONLY'
    END as status
FROM pg_proc 
WHERE proname IN ('trigger_audio_generation', 'manage_alarm_audio_queue');
EOF

print_status "success" "Created comprehensive sync migration: scripts/sync-main-to-develop-complete.sql"

print_status "info" "Instructions to apply the sync:"
echo ""
echo "1. Go to your DEVELOP Supabase project SQL editor"
echo "2. Copy and paste the contents of: scripts/sync-main-to-develop-complete.sql"
echo "3. Run the migration"
echo "4. Verify the results"
echo ""

print_status "info" "Key changes in this sync:"
echo "  ✅ Removed all net.http_post calls"
echo "  ✅ Updated trigger_audio_generation to use queue-based approach"
echo "  ✅ Updated manage_alarm_audio_queue to use queue-based approach"
echo "  ✅ Ensured audio_generation_queue and logs tables exist"
echo "  ✅ Added performance indexes"
echo "  ✅ Comprehensive logging of changes"
echo ""

print_status "success" "Sync script ready! Apply it to your develop environment." 