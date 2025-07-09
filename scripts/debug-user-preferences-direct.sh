#!/bin/bash

# Debug script to directly check user_preferences table for net extension issues
# This bypasses the exec_sql function and queries directly

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

echo -e "${BLUE}🔍 Direct Debug: User Preferences Net Extension Error${NC}"
echo "====================================================="
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

# Step 1: Check table structure directly via REST API
print_status "info" "Step 1: Checking user_preferences table structure..."

TABLE_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?select=*&limit=0" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$TABLE_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to access user_preferences table"
    echo "Response: $TABLE_RESPONSE"
    exit 1
fi

print_status "success" "Table structure accessible"

# Step 2: Check for existing users to test with
print_status "info" "Step 2: Checking for existing users..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$USERS_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to access users table"
    echo "Response: $USERS_RESPONSE"
    exit 1
fi

print_status "success" "Users table accessible"

# Extract first user ID for testing
EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "warning" "No existing users found, creating a test user..."
    
    # Try creating a user with a simpler approach
    TEST_USER_EMAIL="debug+$(date +%s)@example.com"
    USER_DATA=$(cat <<EOF
{
  "email": "$TEST_USER_EMAIL",
  "password": "testpassword123"
}
EOF
)
    
    USER_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X POST "${DEVELOP_URL}/auth/v1/signup" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -d "$USER_DATA")
    
    HTTP_STATUS=$(echo "$USER_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
    RESPONSE_BODY=$(echo "$USER_RESPONSE" | grep -v "HTTPSTATUS:")
    
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
        EXISTING_USER_ID=$(echo "$RESPONSE_BODY" | jq -r '.user.id // empty')
        print_status "success" "Test user created: $EXISTING_USER_ID"
    else
        print_status "error" "Failed to create test user (HTTP $HTTP_STATUS)"
        echo "Response: $RESPONSE_BODY"
        print_status "info" "Using a dummy UUID for testing..."
        EXISTING_USER_ID="00000000-0000-0000-0000-000000000001"
    fi
else
    print_status "success" "Using existing user: $EXISTING_USER_ID"
fi

# Step 3: Test user preferences creation with existing user
print_status "info" "Step 3: Testing user preferences creation..."

PREFERENCES_DATA=$(cat <<EOF
{
  "user_id": "$EXISTING_USER_ID",
  "timezone": "America/New_York",
  "tts_voice": "alloy",
  "preferred_name": "Test User"
}
EOF
)

print_status "info" "Attempting to create user preferences with data:"
echo "$PREFERENCES_DATA" | jq '.'

PREFERENCES_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$PREFERENCES_DATA")

PREFERENCES_HTTP_STATUS=$(echo "$PREFERENCES_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
PREFERENCES_BODY=$(echo "$PREFERENCES_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "User preferences creation response status: $PREFERENCES_HTTP_STATUS"

if [ "$PREFERENCES_HTTP_STATUS" = "201" ] || [ "$PREFERENCES_HTTP_STATUS" = "200" ]; then
    print_status "success" "User preferences created successfully!"
    print_status "info" "The issue may have been resolved by previous fixes"
else
    print_status "error" "User preferences creation failed (HTTP $PREFERENCES_HTTP_STATUS)"
    echo "Error response: $PREFERENCES_BODY"
    
    # Check if it's the net extension error
    if echo "$PREFERENCES_BODY" | grep -q "net"; then
        print_status "error" "🎯 CONFIRMED: Net extension error still exists"
        print_status "info" "The error is coming from the table itself, not triggers"
    fi
    
    # Check for other common errors
    if echo "$PREFERENCES_BODY" | grep -q "duplicate"; then
        print_status "warning" "Duplicate key error - preferences may already exist for this user"
    fi
    
    if echo "$PREFERENCES_BODY" | grep -q "foreign key"; then
        print_status "error" "Foreign key constraint error - user may not exist"
    fi
fi

# Step 4: Check RLS policies specifically
print_status "info" "Step 4: Checking RLS policies..."

# Try to get RLS policy information by attempting different operations
print_status "info" "Testing RLS policy access..."

# Test SELECT access
SELECT_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X GET "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

SELECT_HTTP_STATUS=$(echo "$SELECT_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
SELECT_BODY=$(echo "$SELECT_RESPONSE" | grep -v "HTTPSTATUS:")

if [ "$SELECT_HTTP_STATUS" = "200" ]; then
    print_status "success" "RLS SELECT policy working"
else
    print_status "error" "RLS SELECT policy issue (HTTP $SELECT_HTTP_STATUS)"
    echo "Response: $SELECT_BODY"
fi

# Step 5: Summary and Next Steps
print_status "info" "Step 5: Summary and Next Steps"
echo "====================================="
echo "• Table accessibility: ✅"
echo "• Users table accessibility: ✅"
echo "• Test user ID: $EXISTING_USER_ID"
echo "• User preferences creation: HTTP $PREFERENCES_HTTP_STATUS"
echo "• RLS SELECT test: HTTP $SELECT_HTTP_STATUS"
echo
if [ "$PREFERENCES_HTTP_STATUS" = "201" ] || [ "$PREFERENCES_HTTP_STATUS" = "200" ]; then
    print_status "success" "🎉 Issue appears to be resolved!"
else
    print_status "error" "❌ Issue persists - further investigation needed"
    print_status "info" "Next steps:"
    echo "  1. Check RLS policies for user_preferences table"
    echo "  2. Check for default values that use functions"
    echo "  3. Check for system-level triggers or functions"
    echo "  4. Verify all net extension calls have been removed"
    echo "  5. Check if the error is in the RLS policy evaluation"
fi 