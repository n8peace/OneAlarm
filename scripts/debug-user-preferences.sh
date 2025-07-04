#!/bin/bash

# Debug User Preferences Creation Script
# Tests creating user preferences with detailed error reporting

set -e

# Source shared configuration
source ./scripts/config.sh

# Override with production URL
SUPABASE_URL="https://bfrvahxmokeyrfnlaiwd.supabase.co"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Debug User Preferences Creation${NC}"
echo "====================================="
echo ""

# Check if service role key is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo ""
    echo "Usage: ./scripts/debug-user-preferences.sh YOUR_SERVICE_ROLE_KEY [USER_ID]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/debug-user-preferences.sh YOUR_KEY                    # Use existing user"
    echo "  ./scripts/debug-user-preferences.sh YOUR_KEY USER_UUID          # Use specific user"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to ${SUPABASE_URL}/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
fi

SERVICE_ROLE_KEY="$1"
SPECIFIC_USER_ID="$2"

echo -e "${CYAN}📋 Project:${NC} $SUPABASE_URL"
echo ""

# Step 1: Get or create a test user
if [ -n "$SPECIFIC_USER_ID" ]; then
    echo -e "${CYAN}🔍 Using provided user ID:${NC} $SPECIFIC_USER_ID"
    TEST_USER_ID="$SPECIFIC_USER_ID"
else
    echo -e "${CYAN}🔍 Looking for existing test user...${NC}"
    
    # Try to find an existing test user
    EXISTING_USER_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/users?select=id,email&limit=1" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY")
    
    if [ $? -eq 0 ] && echo "$EXISTING_USER_RESPONSE" | jq -e '.[0].id' >/dev/null 2>&1; then
        TEST_USER_ID=$(echo "$EXISTING_USER_RESPONSE" | jq -r '.[0].id')
        TEST_USER_EMAIL=$(echo "$EXISTING_USER_RESPONSE" | jq -r '.[0].email')
        echo -e "${GREEN}  ✅ Found existing user: $TEST_USER_ID ($TEST_USER_EMAIL)${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No existing user found, creating new test user...${NC}"
        
        # Create a new test user
        TEST_USER_EMAIL="debug-test-$(date +%s)@example.com"
        USER_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/users" \
            -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
            -H "apikey: $SERVICE_ROLE_KEY" \
            -H "Content-Type: application/json" \
            -H "Prefer: return=representation" \
            -d "{
                \"email\": \"$TEST_USER_EMAIL\",
                \"onboarding_done\": true,
                \"subscription_status\": \"trialing\"
            }")
        
        if [ $? -eq 0 ] && echo "$USER_RESPONSE" | jq -e '.[0].id' >/dev/null 2>&1; then
            TEST_USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')
            echo -e "${GREEN}  ✅ Created new user: $TEST_USER_ID${NC}"
        else
            echo -e "${RED}  ❌ User creation failed: $USER_RESPONSE${NC}"
            exit 1
        fi
    fi
fi

echo ""

# Step 2: Check if user preferences already exist
echo -e "${CYAN}🔍 Checking existing user preferences...${NC}"
EXISTING_PREFS_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/user_preferences?user_id=eq.$TEST_USER_ID&select=*" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY")

if [ $? -eq 0 ] && echo "$EXISTING_PREFS_RESPONSE" | jq -e '.[0]' >/dev/null 2>&1; then
    echo -e "${YELLOW}  ⚠️  User preferences already exist:${NC}"
    echo "$EXISTING_PREFS_RESPONSE" | jq '.'
    echo ""
    echo -e "${CYAN}🔍 Attempting to update preferences...${NC}"
    METHOD="PATCH"
    URL="$SUPABASE_URL/rest/v1/user_preferences?user_id=eq.$TEST_USER_ID"
else
    echo -e "${GREEN}  ✅ No existing preferences found${NC}"
    echo -e "${CYAN}🔍 Attempting to create new preferences...${NC}"
    METHOD="POST"
    URL="$SUPABASE_URL/rest/v1/user_preferences"
fi

# Step 3: Test preference creation/update with detailed debugging
PREFERENCES_DATA='{
    "user_id": "'$TEST_USER_ID'",
    "tts_voice": "alloy",
    "news_categories": ["general", "business"],
    "sports_team": "Lakers",
    "stocks": ["AAPL", "GOOGL"],
    "include_weather": true,
    "timezone": "America/New_York",
    "preferred_name": "Debug Test User"
}'

echo -e "${CYAN}📤 Sending $METHOD request to:${NC} $URL"
echo -e "${CYAN}📋 Data:${NC}"
echo "$PREFERENCES_DATA" | jq '.'
echo ""

# Make the request with verbose output
if [ "$METHOD" = "POST" ]; then
    PREFERENCES_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "$URL" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$PREFERENCES_DATA")
else
    PREFERENCES_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X PATCH "$URL" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$PREFERENCES_DATA")
fi

# Extract HTTP status and response body
HTTP_STATUS=$(echo "$PREFERENCES_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$PREFERENCES_RESPONSE" | sed '/HTTP_STATUS:/d')

echo -e "${CYAN}📥 Response Status:${NC} $HTTP_STATUS"
echo -e "${CYAN}📥 Response Body:${NC}"
echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
echo ""

# Step 4: Verify the result
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo -e "${GREEN}✅ User preferences $METHOD successful!${NC}"
    
    # Fetch and display the final preferences
    echo -e "${CYAN}🔍 Final user preferences:${NC}"
    FINAL_PREFS=$(curl -s -X GET "$SUPABASE_URL/rest/v1/user_preferences?user_id=eq.$TEST_USER_ID&select=*" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY")
    echo "$FINAL_PREFS" | jq '.'
    
else
    echo -e "${RED}❌ User preferences $METHOD failed!${NC}"
    echo -e "${YELLOW}🔍 Debugging information:${NC}"
    echo "  - User ID: $TEST_USER_ID"
    echo "  - Method: $METHOD"
    echo "  - URL: $URL"
    echo "  - HTTP Status: $HTTP_STATUS"
    echo ""
    echo -e "${YELLOW}🔍 Possible issues:${NC}"
    echo "  1. Foreign key constraint violation"
    echo "  2. RLS policy blocking the operation"
    echo "  3. Invalid data format"
    echo "  4. Missing required fields"
    echo "  5. Constraint name conflicts"
fi

echo ""
echo -e "${BLUE}📋 Debug Summary:${NC}"
echo "  - User ID: $TEST_USER_ID"
echo "  - Method: $METHOD"
echo "  - Status: $HTTP_STATUS"
echo "  - Success: $([ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ] && echo "Yes" || echo "No")" 