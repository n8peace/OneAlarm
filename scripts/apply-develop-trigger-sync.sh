#!/bin/bash

# Apply Develop Trigger Sync Migration
# This script syncs develop triggers to match main environment exactly

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo "🔄 Syncing Develop Triggers to Match Main Environment"
echo "=================================================="

# Step 1: Drop existing triggers and function
echo "📋 Step 1: Dropping existing triggers and function..."

DROP_SQL="
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;
"

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$DROP_SQL" | jq -R -s .)}")

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Failed to drop existing triggers and function"
    echo "Response: $RESPONSE"
    exit 1
else
    echo "✅ Existing triggers and function dropped successfully"
fi

# Step 2: Create the exact main environment function with DEVELOP URL
echo "📋 Step 2: Creating trigger function to match main..."

FUNCTION_SQL="
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS \$\$
BEGIN
  -- Only trigger if key audio-related preferences changed (UPDATE only, no INSERT)
  -- This matches main environment behavior exactly
  IF OLD.tts_voice IS DISTINCT FROM NEW.tts_voice OR
     OLD.preferred_name IS DISTINCT FROM NEW.preferred_name THEN
    
    -- Log the change for debugging
    INSERT INTO logs (event_type, user_id, meta)
    VALUES (
      'preferences_updated_audio_trigger',
      NEW.user_id,
      jsonb_build_object(
        'old_tts_voice', OLD.tts_voice,
        'new_tts_voice', NEW.tts_voice,
        'old_preferred_name', OLD.preferred_name,
        'new_preferred_name', NEW.preferred_name,
        'triggered_at', NOW(),
        'action', 'audio_generation_triggered',
        'environment', 'develop',
        'approach', 'direct_http_match_main'
      )
    );
    
    -- Call generate-audio function for the user (general audio)
    -- DEVELOP URL: xqkmpkfqoisqzznnvlox
    PERFORM net.http_post(
      url := 'https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw'
      ),
      body := jsonb_build_object(
        'userId', NEW.user_id,
        'audio_type', 'general',
        'forceRegenerate', true
      )
    );
  END IF;
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;
"

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$FUNCTION_SQL" | jq -R -s .)}")

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Failed to create trigger function"
    echo "Response: $RESPONSE"
    exit 1
else
    echo "✅ Trigger function created successfully"
fi

# Step 3: Create UPDATE trigger only (matching main)
echo "📋 Step 3: Creating UPDATE trigger (matching main behavior)..."

TRIGGER_SQL="
CREATE TRIGGER on_preferences_updated
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();
"

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$TRIGGER_SQL" | jq -R -s .)}")

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Failed to create UPDATE trigger"
    echo "Response: $RESPONSE"
    exit 1
else
    echo "✅ UPDATE trigger created successfully"
fi

# Step 4: Log the migration
echo "📋 Step 4: Logging migration..."

LOG_SQL="
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_sync',
  jsonb_build_object(
    'action', 'sync_develop_triggers_to_match_main',
    'source', 'main_environment',
    'target', 'develop_environment',
    'key_changes', jsonb_build_object(
      'removed_insert_trigger', true,
      'removed_insert_behavior', true,
      'added_direct_http_calls', true,
      'matched_main_logic_exactly', true
    ),
    'main_behavior', jsonb_build_object(
      'triggers_on_update_only', true,
      'triggers_on_insert', false,
      'uses_direct_http', true,
      'uses_net_extension', true
    ),
    'develop_url', 'https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio',
    'timestamp', NOW(),
    'note', 'Made develop triggers match main exactly - UPDATE only, direct HTTP calls, no INSERT trigger'
  )
);
"

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$LOG_SQL" | jq -R -s .)}")

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Failed to log migration"
    echo "Response: $RESPONSE"
    exit 1
else
    echo "✅ Migration logged successfully"
fi

echo ""
echo "🎉 Develop Triggers Successfully Synced to Match Main!"
echo "=================================================="
echo "✅ Removed INSERT trigger behavior"
echo "✅ Added direct HTTP calls using net.http_post"
echo "✅ Matched main environment logic exactly"
echo "✅ Only triggers on UPDATE operations (no INSERT)"
echo "✅ Uses develop URL: https://xqkmpkfqoisqzznnvlox.supabase.co/functions/v1/generate-audio"
echo ""
echo "📊 Summary of Changes:"
echo "• Removed: INSERT trigger behavior"
echo "• Added: Direct HTTP calls to generate-audio function"
echo "• Changed: Queue-based approach → Direct HTTP approach"
echo "• Matched: Main environment behavior exactly" 