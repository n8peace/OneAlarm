#!/bin/bash

# Apply develop migration script
# This script applies the user preferences trigger fix to the develop environment

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

echo -e "${BLUE}🔧 Applying Develop Migration${NC}"
echo "=================================="
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

# Read the migration SQL
MIGRATION_SQL=$(cat supabase/migrations/20250706000006_fix_develop_user_preferences_trigger.sql)

print_status "info" "Applying migration to develop environment..."

# Apply the migration using the Supabase REST API
# We'll execute the SQL in chunks to avoid issues with complex statements

# Step 1: Create/Replace the trigger function
print_status "info" "Step 1: Creating trigger function..."
FUNCTION_SQL=$(echo "$MIGRATION_SQL" | sed -n '/^CREATE OR REPLACE FUNCTION trigger_audio_generation/,/^$$ LANGUAGE plpgsql;/p')

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$FUNCTION_SQL" | jq -R -s .)}")

if echo "$RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to create trigger function"
    echo "Response: $RESPONSE"
    exit 1
else
    print_status "success" "Trigger function created successfully"
fi

# Step 2: Drop and recreate triggers
print_status "info" "Step 2: Recreating triggers..."

TRIGGER_SQL="
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
CREATE TRIGGER on_preferences_updated
  AFTER UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();

DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;
CREATE TRIGGER on_preferences_inserted
  AFTER INSERT ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION trigger_audio_generation();
"

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$TRIGGER_SQL" | jq -R -s .)}")

if echo "$RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to recreate triggers"
    echo "Response: $RESPONSE"
    exit 1
else
    print_status "success" "Triggers recreated successfully"
fi

# Step 3: Log the migration
print_status "info" "Step 3: Logging migration..."

LOG_SQL="
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_update',
  jsonb_build_object(
    'action', 'fix_develop_user_preferences_trigger',
    'trigger_name', 'on_preferences_updated',
    'function_name', 'trigger_audio_generation',
    'purpose', 'Use queue-based approach instead of HTTP calls',
    'environment', 'develop',
    'approach', 'queue_based',
    'timestamp', NOW()
  )
);
"

RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/logs" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d '{
    "event_type": "trigger_update",
    "meta": {
      "action": "fix_develop_user_preferences_trigger",
      "trigger_name": "on_preferences_updated",
      "function_name": "trigger_audio_generation",
      "purpose": "Use queue-based approach instead of HTTP calls",
      "environment": "develop",
      "approach": "queue_based",
      "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"
    }
  }')

if echo "$RESPONSE" | grep -q "error"; then
    print_status "warning" "Failed to log migration (non-critical)"
    echo "Response: $RESPONSE"
else
    print_status "success" "Migration logged successfully"
fi

echo
print_status "success" "Migration applied successfully!"
echo
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Test by updating a user preference (tts_voice or preferred_name)"
echo "2. Check that queue items are created in audio_generation_queue"
echo "3. Verify that audio generation is triggered"
echo
echo -e "${BLUE}🔍 To test:${NC}"
echo "UPDATE user_preferences SET tts_voice = 'nova' WHERE user_id = 'your-test-user-id';"
echo 