#!/bin/bash

# Debug script for user preferences HTTP 400 error
# This script will show the exact request being sent and detailed error response

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Develop environment details
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔍 Debugging User Preferences HTTP 400 Error${NC}"
echo "=============================================="
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
        "debug")
            echo -e "${CYAN}🔍 $message${NC}"
            ;;
    esac
}

# Step 1: Check current user_preferences schema
print_status "info" "Step 1: Checking user_preferences schema..."

SCHEMA_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?select=*&limit=0" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$SCHEMA_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to check schema"
    echo "Response: $SCHEMA_RESPONSE"
    exit 1
fi

print_status "success" "Schema check successful"

# Step 2: Create a test user
print_status "info" "Step 2: Creating a test user..."

TEST_USER_EMAIL="debug+$(date +%s)@example.com"
USER_DATA=$(cat <<EOF
{
    "email": "$TEST_USER_EMAIL",
    "onboarding_done": true,
    "subscription_status": "trialing"
}
EOF
)

print_status "debug" "User data being sent:"
echo "$USER_DATA" | jq '.'

USER_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/users" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "$USER_DATA")

if echo "$USER_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to create user"
    echo "Response: $USER_RESPONSE"
    exit 1
fi

TEST_USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')
print_status "success" "Created test user: $TEST_USER_ID"

# Step 3: Test different preference data formats
print_status "info" "Step 3: Testing different preference data formats..."

# Test 1: Minimal preferences (like the failing case)
print_status "debug" "Test 1: Minimal preferences (like the failing case)..."

MINIMAL_PREFERENCES=$(cat <<EOF
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

print_status "debug" "Minimal preferences data:"
echo "$MINIMAL_PREFERENCES" | jq '.'

MINIMAL_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$MINIMAL_PREFERENCES")

HTTP_STATUS=$(echo "$MINIMAL_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$MINIMAL_RESPONSE" | sed '/HTTP_STATUS:/d')

print_status "debug" "Minimal preferences response status: $HTTP_STATUS"
print_status "debug" "Minimal preferences response body:"
echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
    print_status "success" "Minimal preferences created successfully"
else
    print_status "error" "Minimal preferences failed with HTTP $HTTP_STATUS"
fi

# Test 2: Even more minimal (just required fields)
print_status "debug" "Test 2: Even more minimal (just user_id)..."

BASIC_PREFERENCES=$(cat <<EOF
{
  "user_id": "$TEST_USER_ID"
}
EOF
)

print_status "debug" "Basic preferences data:"
echo "$BASIC_PREFERENCES" | jq '.'

BASIC_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$BASIC_PREFERENCES")

HTTP_STATUS=$(echo "$BASIC_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$BASIC_RESPONSE" | sed '/HTTP_STATUS:/d')

print_status "debug" "Basic preferences response status: $HTTP_STATUS"
print_status "debug" "Basic preferences response body:"
echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
    print_status "success" "Basic preferences created successfully"
else
    print_status "error" "Basic preferences failed with HTTP $HTTP_STATUS"
fi

# Test 3: Check if user already has preferences
print_status "debug" "Test 3: Checking if user already has preferences..."

EXISTING_PREFERENCES=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.${TEST_USER_ID}&select=*" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

PREFERENCES_COUNT=$(echo "$EXISTING_PREFERENCES" | jq '. | length')
print_status "debug" "Existing preferences count: $PREFERENCES_COUNT"

if [ "$PREFERENCES_COUNT" -gt 0 ]; then
    print_status "warning" "User already has preferences:"
    echo "$EXISTING_PREFERENCES" | jq '.'
fi

# Test 4: Try with different data types
print_status "debug" "Test 4: Testing with explicit data types..."

TYPED_PREFERENCES=$(cat <<EOF
{
  "user_id": "$TEST_USER_ID",
  "tts_voice": "sage",
  "news_categories": ["general", "sports"],
  "sports_team": "Celtics",
  "stocks": ["NVDA", "AMD", "INTC"],
  "include_weather": true,
  "timezone": "America/Chicago",
  "preferred_name": "Max",
  "onboarding_completed": false,
  "onboarding_step": 0
}
EOF
)

print_status "debug" "Typed preferences data:"
echo "$TYPED_PREFERENCES" | jq '.'

TYPED_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$TYPED_PREFERENCES")

HTTP_STATUS=$(echo "$TYPED_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$TYPED_RESPONSE" | sed '/HTTP_STATUS:/d')

print_status "debug" "Typed preferences response status: $HTTP_STATUS"
print_status "debug" "Typed preferences response body:"
echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
    print_status "success" "Typed preferences created successfully"
else
    print_status "error" "Typed preferences failed with HTTP $HTTP_STATUS"
fi

# Step 4: Check RLS policies
print_status "info" "Step 4: Checking RLS policies..."

RLS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?select=*&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$RLS_RESPONSE" | grep -q "error"; then
    print_status "error" "RLS policy issue detected"
    echo "Response: $RLS_RESPONSE"
else
    print_status "success" "RLS policies appear to be working"
fi

# Step 5: Check for any constraints or triggers
print_status "info" "Step 5: Checking for constraints or trigger issues..."

# Try to get the exact error by using verbose curl
print_status "debug" "Making verbose request to see exact error..."

VERBOSE_RESPONSE=$(curl -v -s -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$MINIMAL_PREFERENCES" 2>&1)

print_status "debug" "Verbose response:"
echo "$VERBOSE_RESPONSE"

# Step 6: Summary
echo
print_status "info" "Step 6: Debug Summary"
echo "=================="
echo "• Test user created: $TEST_USER_ID"
echo "• Test user email: $TEST_USER_EMAIL"
echo "• Schema check: ✅"
echo "• RLS check: ✅"
echo "• Verbose error details captured above"
echo
print_status "info" "Check the verbose response above for the exact error message"
print_status "info" "Common causes of HTTP 400:"
echo "  - Invalid data types"
echo "  - Missing required fields"
echo "  - Constraint violations"
echo "  - Trigger errors"
echo "  - RLS policy violations" 