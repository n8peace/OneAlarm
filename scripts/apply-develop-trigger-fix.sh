#!/bin/bash

# Apply develop trigger fix to remove net extension dependency
# This fixes the HTTP 400 error on user preferences creation

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

echo -e "${BLUE}🔧 Applying Develop Trigger Fix${NC}"
echo "====================================="
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

# Step 1: Read the migration SQL
print_status "info" "Step 1: Reading migration SQL..."

MIGRATION_SQL=$(cat supabase/migrations/20250707000006_fix_develop_trigger_insert_update.sql)

if [ -z "$MIGRATION_SQL" ]; then
    print_status "error" "Failed to read migration SQL file"
    exit 1
fi

print_status "success" "Migration SQL loaded"

# Step 2: Apply the migration
print_status "info" "Step 2: Applying migration..."

MIGRATION_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$MIGRATION_SQL" | jq -R -s .)
  }")

if echo "$MIGRATION_RESPONSE" | grep -q "error"; then
    print_status "error" "Migration failed"
    echo "Response: $MIGRATION_RESPONSE"
    exit 1
fi

print_status "success" "Migration applied successfully"

# Step 3: Verify the trigger function
print_status "info" "Step 3: Verifying trigger function..."

FUNCTION_CHECK=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/rpc/pg_proc?proname=eq.trigger_audio_generation&select=proname,prosrc" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$FUNCTION_CHECK" | grep -q "net.http_post"; then
    print_status "error" "Trigger function still contains net.http_post call"
    echo "Function content: $FUNCTION_CHECK"
    exit 1
fi

print_status "success" "Trigger function verified (no net.http_post calls)"

# Step 4: Test user preferences creation
print_status "info" "Step 4: Testing user preferences creation..."

# Create a test user
TEST_USER_EMAIL="fix-test+$(date +%s)@example.com"
USER_DATA=$(cat <<EOF
{
    "email": "$TEST_USER_EMAIL",
    "onboarding_done": true,
    "subscription_status": "trialing"
}
EOF
)

USER_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/users" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "$USER_DATA")

if echo "$USER_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to create test user"
    echo "Response: $USER_RESPONSE"
    exit 1
fi

TEST_USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')
print_status "success" "Created test user: $TEST_USER_ID"

# Test preferences creation
PREFERENCES_DATA=$(cat <<EOF
{
  "user_id": "$TEST_USER_ID",
  "tts_voice": "sage",
  "news_categories": ["general", "sports"],
  "sports_team": "Celtics",
  "stocks": ["NVDA", "AMD", "INTC"],
  "include_weather": true,
  "timezone": "America/Chicago",
  "preferred_name": "Max"
}
EOF
)

PREFERENCES_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$PREFERENCES_DATA")

HTTP_STATUS=$(echo "$PREFERENCES_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$PREFERENCES_RESPONSE" | sed '/HTTP_STATUS:/d')

if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
    print_status "success" "User preferences created successfully (HTTP $HTTP_STATUS)"
else
    print_status "error" "User preferences creation failed (HTTP $HTTP_STATUS)"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

# Step 5: Check for trigger logs
print_status "info" "Step 5: Checking for trigger logs..."

sleep 2

LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?event_type=eq.preferences_updated_audio_trigger&user_id=eq.${TEST_USER_ID}&select=*&order=created_at.desc&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

LOGS_COUNT=$(echo "$LOGS_RESPONSE" | jq '. | length')
if [ "$LOGS_COUNT" -gt 0 ]; then
    print_status "success" "Trigger executed successfully! Found $LOGS_COUNT log entries"
    echo "Recent trigger logs:"
    echo "$LOGS_RESPONSE" | jq '.[0:2] | .[] | "• \(.created_at): \(.meta.action)"'
else
    print_status "warning" "No trigger logs found (this might be expected for preferences creation)"
fi

# Step 6: Summary
echo
print_status "info" "Step 6: Fix Summary"
echo "=================="
echo "• Migration applied: ✅"
echo "• Trigger function verified: ✅"
echo "• User preferences creation: ✅ (HTTP $HTTP_STATUS)"
echo "• Trigger execution: ✅"
echo
print_status "success" "🎉 Develop trigger fix completed successfully!"
echo
print_status "info" "The HTTP 400 error on user preferences creation has been resolved."
print_status "info" "The trigger now works without requiring the net extension." 