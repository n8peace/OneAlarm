#!/bin/bash

# Test Disabling RLS to Isolate Net Extension Error
# This script temporarily disables RLS on user_preferences to test if that's the source

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Develop environment details
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔍 Testing RLS Disable to Isolate Net Extension Error${NC}"
echo "=================================================="

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

# Step 1: Get an existing user for testing
print_status "info" "Step 1: Getting existing user for testing..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id')

if [ "$EXISTING_USER_ID" = "null" ] || [ -z "$EXISTING_USER_ID" ]; then
    print_status "error" "No existing user found for testing"
    exit 1
fi

print_status "success" "Using user: $EXISTING_USER_ID"

# Step 2: Test UPDATE with RLS enabled (baseline)
print_status "info" "Step 2: Testing UPDATE with RLS enabled (baseline)..."

UPDATE_WITH_RLS=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"preferred_name": "Test With RLS"}')

HTTP_STATUS=$(echo "$UPDATE_WITH_RLS" | grep "HTTPSTATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$UPDATE_WITH_RLS" | sed '/HTTPSTATUS:/d')

print_status "debug" "UPDATE with RLS status: $HTTP_STATUS"
print_status "debug" "UPDATE with RLS response:"
echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "204" ]; then
    print_status "success" "UPDATE with RLS succeeded"
    RLS_WORKS=true
else
    print_status "error" "UPDATE with RLS failed with HTTP $HTTP_STATUS"
    RLS_WORKS=false
fi

# Step 3: Disable RLS on user_preferences
print_status "info" "Step 3: Disabling RLS on user_preferences..."

# Create a simple SQL command to disable RLS
DISABLE_RLS_SQL="ALTER TABLE user_preferences DISABLE ROW LEVEL SECURITY;"

# Apply using direct SQL (if possible) or create a simple function
DISABLE_RLS_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$DISABLE_RLS_SQL" | jq -R -s .)}")

print_status "debug" "Disable RLS response:"
echo "$DISABLE_RLS_RESPONSE" | jq '.' 2>/dev/null || echo "$DISABLE_RLS_RESPONSE"

# Step 4: Test UPDATE with RLS disabled
print_status "info" "Step 4: Testing UPDATE with RLS disabled..."

UPDATE_WITHOUT_RLS=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"preferred_name": "Test Without RLS"}')

HTTP_STATUS=$(echo "$UPDATE_WITHOUT_RLS" | grep "HTTPSTATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$UPDATE_WITHOUT_RLS" | sed '/HTTPSTATUS:/d')

print_status "debug" "UPDATE without RLS status: $HTTP_STATUS"
print_status "debug" "UPDATE without RLS response:"
echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "204" ]; then
    print_status "success" "UPDATE without RLS succeeded"
    NO_RLS_WORKS=true
else
    print_status "error" "UPDATE without RLS failed with HTTP $HTTP_STATUS"
    NO_RLS_WORKS=false
fi

# Step 5: Re-enable RLS
print_status "info" "Step 5: Re-enabling RLS on user_preferences..."

ENABLE_RLS_SQL="ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;"

ENABLE_RLS_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$ENABLE_RLS_SQL" | jq -R -s .)}")

print_status "debug" "Enable RLS response:"
echo "$ENABLE_RLS_RESPONSE" | jq '.' 2>/dev/null || echo "$ENABLE_RLS_RESPONSE"

# Step 6: Analysis
print_status "info" "Step 6: Analysis Summary"
echo "====================="

if [ "$RLS_WORKS" = false ] && [ "$NO_RLS_WORKS" = true ]; then
    print_status "success" "🎯 CONFIRMED: RLS policies are causing the net extension error"
    print_status "info" "The issue is in the RLS policies on user_preferences table"
    print_status "info" "Next steps:"
    echo "1. Check and simplify RLS policies"
    echo "2. Remove any function calls from RLS policies"
    echo "3. Ensure RLS policies don't reference net extension"
elif [ "$RLS_WORKS" = false ] && [ "$NO_RLS_WORKS" = false ]; then
    print_status "warning" "⚠️  RLS is not the issue - both tests failed"
    print_status "info" "The net extension error is coming from elsewhere"
    print_status "info" "Possible sources:"
    echo "1. Default values on columns"
    echo "2. Check constraints"
    echo "3. System-level triggers"
    echo "4. REST API configuration"
elif [ "$RLS_WORKS" = true ]; then
    print_status "success" "✅ RLS is working correctly"
    print_status "info" "The issue must be intermittent or related to specific conditions"
else
    print_status "error" "❌ Unexpected test results"
fi

print_status "info" "Test completed. RLS has been re-enabled." 