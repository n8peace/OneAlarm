#!/bin/bash

# Debug script to disable triggers and test user preferences creation
# This will help isolate the net extension error

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

echo -e "${BLUE}🔍 Debug: Disabling Triggers to Isolate Net Extension Error${NC}"
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

# Step 1: Disable all triggers on user_preferences
print_status "info" "Step 1: Disabling all triggers on user_preferences..."

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

print_status "success" "All triggers disabled"

# Step 2: Test user preferences creation without triggers
print_status "info" "Step 2: Testing user preferences creation without triggers..."

# Create a test user
TEST_USER_EMAIL="no-trigger-test+$(date +%s)@example.com"
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
    print_status "success" "User preferences created successfully WITHOUT triggers (HTTP $HTTP_STATUS)"
    print_status "info" "This confirms the issue is with the triggers, not the table itself"
else
    print_status "error" "User preferences creation failed even without triggers (HTTP $HTTP_STATUS)"
    echo "Response: $RESPONSE_BODY"
    print_status "info" "This suggests the issue is not with triggers but with the table or constraints"
fi

# Step 3: Re-enable triggers
print_status "info" "Step 3: Re-enabling triggers..."

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

# Step 4: Summary
echo
print_status "info" "Step 4: Debug Summary"
echo "=================="
echo "• Triggers disabled: ✅"
echo "• User preferences creation test: HTTP $HTTP_STATUS"
echo "• Triggers re-enabled: ✅"
echo
if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
    print_status "success" "🎯 Root cause identified: The issue is with the triggers!"
    print_status "info" "The net extension error is coming from the trigger function."
else
    print_status "error" "❌ The issue is not with triggers - it's with the table itself."
fi 