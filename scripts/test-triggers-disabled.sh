#!/bin/bash

# Test script to disable triggers and verify net extension error source
# This will confirm if the trigger is causing the net extension error

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

echo -e "${BLUE}🔍 Testing Triggers Disabled - Net Extension Error Source${NC}"
echo "========================================================="
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

# Step 1: Get an existing user for testing
print_status "info" "Step 1: Getting test user..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "error" "No users found for testing"
    exit 1
fi

print_status "success" "Using test user: $EXISTING_USER_ID"

# Step 2: Test TTS voice UPDATE with triggers enabled (baseline)
print_status "info" "Step 2: Testing TTS voice UPDATE with triggers enabled (baseline)..."

TTS_UPDATE_DATA=$(cat <<EOF
{
  "tts_voice": "echo"
}
EOF
)

TTS_UPDATE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$TTS_UPDATE_DATA")

TTS_UPDATE_HTTP_STATUS=$(echo "$TTS_UPDATE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
TTS_UPDATE_BODY=$(echo "$TTS_UPDATE_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "Baseline TTS UPDATE test: HTTP $TTS_UPDATE_HTTP_STATUS"

if [ "$TTS_UPDATE_HTTP_STATUS" = "200" ] || [ "$TTS_UPDATE_HTTP_STATUS" = "204" ]; then
    print_status "success" "Baseline TTS UPDATE working correctly!"
    print_status "info" "The net extension error may have been resolved"
else
    print_status "error" "Baseline TTS UPDATE failed (HTTP $TTS_UPDATE_HTTP_STATUS)"
    echo "Error response: $TTS_UPDATE_BODY"
    
    if echo "$TTS_UPDATE_BODY" | grep -q "net"; then
        print_status "error" "🎯 CONFIRMED: Net extension error with triggers enabled"
    fi
fi

# Step 3: Disable triggers temporarily
print_status "info" "Step 3: Disabling triggers temporarily..."

DISABLE_TRIGGERS_SQL="
-- Disable all triggers on user_preferences table
ALTER TABLE user_preferences DISABLE TRIGGER ALL;
"

DISABLE_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$DISABLE_TRIGGERS_SQL" | jq -R -s .)
  }")

if echo "$DISABLE_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to disable triggers"
    echo "Response: $DISABLE_RESPONSE"
    exit 1
fi

print_status "success" "Triggers disabled"

# Step 4: Test TTS voice UPDATE with triggers disabled
print_status "info" "Step 4: Testing TTS voice UPDATE with triggers disabled..."

TTS_UPDATE_DISABLED_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$TTS_UPDATE_DATA")

TTS_UPDATE_DISABLED_HTTP_STATUS=$(echo "$TTS_UPDATE_DISABLED_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
TTS_UPDATE_DISABLED_BODY=$(echo "$TTS_UPDATE_DISABLED_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "TTS UPDATE with triggers disabled: HTTP $TTS_UPDATE_DISABLED_HTTP_STATUS"

if [ "$TTS_UPDATE_DISABLED_HTTP_STATUS" = "200" ] || [ "$TTS_UPDATE_DISABLED_HTTP_STATUS" = "204" ]; then
    print_status "success" "TTS UPDATE working with triggers disabled!"
    print_status "info" "🎯 CONFIRMED: The trigger is causing the net extension error"
else
    print_status "error" "TTS UPDATE still failed with triggers disabled (HTTP $TTS_UPDATE_DISABLED_HTTP_STATUS)"
    echo "Error response: $TTS_UPDATE_DISABLED_BODY"
    
    if echo "$TTS_UPDATE_DISABLED_BODY" | grep -q "net"; then
        print_status "error" "🎯 The net extension error is NOT from triggers"
        print_status "info" "The issue is elsewhere in the system"
    fi
fi

# Step 5: Re-enable triggers
print_status "info" "Step 5: Re-enabling triggers..."

ENABLE_TRIGGERS_SQL="
-- Re-enable all triggers on user_preferences table
ALTER TABLE user_preferences ENABLE TRIGGER ALL;
"

ENABLE_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$ENABLE_TRIGGERS_SQL" | jq -R -s .)
  }")

if echo "$ENABLE_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to re-enable triggers"
    echo "Response: $ENABLE_RESPONSE"
else
    print_status "success" "Triggers re-enabled"
fi

# Step 6: Summary
print_status "info" "Step 6: Test Summary"
echo "=================="
echo "• Baseline TTS UPDATE: HTTP $TTS_UPDATE_HTTP_STATUS"
echo "• TTS UPDATE with triggers disabled: HTTP $TTS_UPDATE_DISABLED_HTTP_STATUS"
echo "• Triggers re-enabled: ✅"
echo

if [ "$TTS_UPDATE_HTTP_STATUS" != "200" ] && [ "$TTS_UPDATE_HTTP_STATUS" != "204" ] && \
   [ "$TTS_UPDATE_DISABLED_HTTP_STATUS" = "200" ] || [ "$TTS_UPDATE_DISABLED_HTTP_STATUS" = "204" ]; then
    print_status "success" "🎯 CONFIRMED: The trigger is causing the net extension error"
    print_status "info" "The trigger function still contains net extension calls"
    print_status "info" "Next steps:"
    echo "  1. Check the current trigger_audio_generation() function"
    echo "  2. Verify all net extension calls have been removed"
    echo "  3. Re-apply the trigger fix migration"
elif [ "$TTS_UPDATE_HTTP_STATUS" = "200" ] || [ "$TTS_UPDATE_HTTP_STATUS" = "204" ]; then
    print_status "success" "🎉 The net extension error appears to be resolved!"
    print_status "info" "The trigger fix may have been applied successfully"
else
    print_status "error" "❌ The net extension error persists even with triggers disabled"
    print_status "info" "The issue is not with triggers but with something else"
    print_status "info" "Next steps:"
    echo "  1. Check for system-level functions or constraints"
    echo "  2. Check for default values that use functions"
    echo "  3. Check for RLS policies that use complex subqueries"
fi 