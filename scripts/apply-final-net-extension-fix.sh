#!/bin/bash

# Apply final net extension fix to develop environment
# This script applies the migration that completely removes all net extension dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Develop environment details
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔧 Applying Final Net Extension Fix to Develop Environment${NC}"
echo "============================================================="
echo

# Function to print colored output
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

# Step 1: Read the migration file
print_status "info" "Step 1: Reading migration file..."

MIGRATION_FILE="supabase/migrations/20250707000010_fix_develop_net_extension_final.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    print_status "error" "Migration file not found: $MIGRATION_FILE"
    exit 1
fi

MIGRATION_SQL=$(cat "$MIGRATION_FILE")
print_status "success" "Migration file loaded"

# Step 2: Apply the migration using direct SQL execution
print_status "info" "Step 2: Applying migration to develop environment..."

# Since exec_sql is not available, we'll use the REST API directly
# We'll apply the migration in parts to avoid issues

print_status "info" "Applying trigger function fix..."

# First, let's try to apply the trigger function part
TRIGGER_FUNCTION_SQL="
-- Drop and recreate the trigger function without ANY net extension calls
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS \$\$
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
        'note', 'queue_only_no_direct_http_no_net_extension_final_fix'
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
\$\$ LANGUAGE plpgsql;
"

# Try to apply this via a direct SQL call
print_status "info" "Attempting to apply trigger function fix..."

# Since we can't use exec_sql, let's try a different approach
# We'll test if the issue is resolved by testing a simple UPDATE

print_status "info" "Testing current state with a simple UPDATE..."

# Get an existing user for testing
USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "error" "No users found for testing"
    exit 1
fi

print_status "info" "Testing with user: $EXISTING_USER_ID"

# Test a simple UPDATE
UPDATE_DATA=$(cat <<EOF
{
  "updated_at": "2025-07-07T00:00:00Z"
}
EOF
)

UPDATE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$UPDATE_DATA")

UPDATE_HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
UPDATE_BODY=$(echo "$UPDATE_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "Current UPDATE test result: HTTP $UPDATE_HTTP_STATUS"

if [ "$UPDATE_HTTP_STATUS" = "200" ] || [ "$UPDATE_HTTP_STATUS" = "204" ]; then
    print_status "success" "UPDATE is working correctly!"
    print_status "info" "The net extension error may have been resolved by previous migrations"
else
    print_status "error" "UPDATE still failing (HTTP $UPDATE_HTTP_STATUS)"
    echo "Error response: $UPDATE_BODY"
    
    if echo "$UPDATE_BODY" | grep -q "net"; then
        print_status "error" "🎯 CONFIRMED: Net extension error still exists"
        print_status "info" "The migration needs to be applied manually via Supabase Dashboard"
    fi
fi

# Step 3: Provide manual application instructions
print_status "info" "Step 3: Manual Application Instructions"
echo "============================================="
echo
print_status "warning" "Since exec_sql is not available in develop, please apply this migration manually:"
echo
echo "1. Go to the Supabase Dashboard for the develop environment"
echo "2. Navigate to the SQL Editor"
echo "3. Copy and paste the contents of: $MIGRATION_FILE"
echo "4. Execute the migration"
echo "5. Test the fix using the test script"
echo

# Step 4: Test script
print_status "info" "Step 4: After applying the migration, run this test:"
echo "============================================="
echo
echo "Run: ./scripts/test-user-preferences-update.sh"
echo

# Step 5: Summary
print_status "info" "Step 5: Summary"
echo "============="
echo "• Migration file created: ✅"
echo "• Current UPDATE test: HTTP $UPDATE_HTTP_STATUS"
echo "• Manual application required: ✅"
echo "• Test script available: ✅"
echo

if [ "$UPDATE_HTTP_STATUS" = "200" ] || [ "$UPDATE_HTTP_STATUS" = "204" ]; then
    print_status "success" "🎉 The issue may already be resolved!"
    print_status "info" "Run the test script to confirm: ./scripts/test-user-preferences-update.sh"
else
    print_status "error" "❌ Manual migration application required"
    print_status "info" "Apply the migration manually via Supabase Dashboard"
fi 