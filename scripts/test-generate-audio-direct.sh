#!/bin/bash

# Test generate-audio function directly
# This script tests the generate-audio function with a direct API call

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

echo -e "${BLUE}🎵 Testing generate-audio Function Directly${NC}"
echo "============================================="
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

# Step 1: Find a test user
print_status "info" "Step 1: Finding a test user..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=3" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$USERS_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to fetch users"
    echo "Response: $USERS_RESPONSE"
    exit 1
fi

USER_COUNT=$(echo "$USERS_RESPONSE" | jq '. | length')
print_status "info" "Found $USER_COUNT users"

if [ "$USER_COUNT" -eq 0 ]; then
    print_status "error" "No users found. Please create a test user first."
    exit 1
fi

# Get the first user ID
TEST_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id')
print_status "info" "Using test user: $TEST_USER_ID"

# Step 2: Check if user has preferences
print_status "info" "Step 2: Checking user preferences..."

PREFERENCES_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.${TEST_USER_ID}&select=*" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$PREFERENCES_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to fetch user preferences"
    echo "Response: $PREFERENCES_RESPONSE"
    exit 1
fi

PREFERENCES_COUNT=$(echo "$PREFERENCES_RESPONSE" | jq '. | length')
if [ "$PREFERENCES_COUNT" -eq 0 ]; then
    print_status "warning" "No preferences found for user. Creating preferences..."
    
    # Create preferences
    CREATE_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d "{
        \"user_id\": \"${TEST_USER_ID}\",
        \"tts_voice\": \"alloy\",
        \"preferred_name\": \"Test User\",
        \"timezone\": \"America/New_York\"
      }")
    
    if echo "$CREATE_RESPONSE" | grep -q "error"; then
        print_status "error" "Failed to create user preferences"
        echo "Response: $CREATE_RESPONSE"
        exit 1
    else
        print_status "success" "Created user preferences"
    fi
else
    print_status "success" "Found existing user preferences"
    CURRENT_PREFERENCES=$(echo "$PREFERENCES_RESPONSE" | jq '.[0]')
    echo "Current preferences:"
    echo "$CURRENT_PREFERENCES" | jq '.'
fi

# Step 3: Check current audio files count
print_status "info" "Step 3: Checking current audio files count..."

AUDIO_BEFORE_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/audio?user_id=eq.${TEST_USER_ID}&select=count" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

AUDIO_BEFORE_COUNT=$(echo "$AUDIO_BEFORE_RESPONSE" | jq '. | length')
print_status "info" "Audio files before test: $AUDIO_BEFORE_COUNT"

# Step 4: Call generate-audio function directly
print_status "info" "Step 4: Calling generate-audio function directly..."

# Sample request body for generate-audio
REQUEST_BODY='{
  "userId": "'${TEST_USER_ID}'",
  "forceRegenerate": false
}'

echo "Request body:"
echo "$REQUEST_BODY" | jq '.'

# Call the function
FUNCTION_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/functions/v1/generate-audio" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -d "$REQUEST_BODY")

echo "Function response:"
echo "$FUNCTION_RESPONSE" | jq '.'

# Check if the response indicates success
if echo "$FUNCTION_RESPONSE" | grep -q '"success":true'; then
    print_status "success" "✅ generate-audio function call successful"
else
    print_status "error" "❌ generate-audio function call failed"
    echo "Response: $FUNCTION_RESPONSE"
fi

# Step 5: Wait a moment for processing
print_status "info" "Step 5: Waiting for audio generation to complete..."
sleep 10

# Step 6: Check if new audio files were created
print_status "info" "Step 6: Checking for new audio files..."

AUDIO_AFTER_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/audio?user_id=eq.${TEST_USER_ID}&select=*&order=created_at.desc" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

AUDIO_AFTER_COUNT=$(echo "$AUDIO_AFTER_RESPONSE" | jq '. | length')
print_status "info" "Audio files after test: $AUDIO_AFTER_COUNT"

if [ "$AUDIO_AFTER_COUNT" -gt "$AUDIO_BEFORE_COUNT" ]; then
    print_status "success" "✅ New audio files created! Count increased from $AUDIO_BEFORE_COUNT to $AUDIO_AFTER_COUNT"
    
    # Show the new audio files
    echo "New audio files:"
    echo "$AUDIO_AFTER_RESPONSE" | jq '.[0:3] | .[] | "• \(.audio_type): \(.generated_at) - \(.status)"'
else
    print_status "warning" "⚠️ No new audio files created. Checking logs..."
fi

# Step 7: Check function logs
print_status "info" "Step 7: Checking function logs..."

LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?event_type=eq.function_completed&user_id=eq.${TEST_USER_ID}&select=*&order=created_at.desc&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

LOGS_COUNT=$(echo "$LOGS_RESPONSE" | jq '. | length')
if [ "$LOGS_COUNT" -gt 0 ]; then
    print_status "success" "✅ Found $LOGS_COUNT function completion logs"
    echo "Recent function logs:"
    echo "$LOGS_RESPONSE" | jq '.[0:2] | .[] | "• \(.created_at): \(.meta.success) - \(.meta.message)"'
else
    print_status "warning" "⚠️ No function completion logs found"
fi

# Step 8: Check for any errors
print_status "info" "Step 8: Checking for errors..."

ERROR_LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?event_type=eq.audio_generation_function_failed&user_id=eq.${TEST_USER_ID}&select=*&order=created_at.desc&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

ERROR_COUNT=$(echo "$ERROR_LOGS_RESPONSE" | jq '. | length')
if [ "$ERROR_COUNT" -gt 0 ]; then
    print_status "error" "❌ Found $ERROR_COUNT error logs"
    echo "Error logs:"
    echo "$ERROR_LOGS_RESPONSE" | jq '.[0:2] | .[] | "• \(.created_at): \(.meta.error)"'
else
    print_status "success" "No error logs found"
fi

echo
print_status "success" "Test completed!"
echo
echo -e "${BLUE}📋 Summary:${NC}"
echo "• Test user: $TEST_USER_ID"
echo "• Audio files before: $AUDIO_BEFORE_COUNT"
echo "• Audio files after: $AUDIO_AFTER_COUNT"
echo "• Function logs: $LOGS_COUNT"
echo "• Error logs: $ERROR_COUNT"
echo "• Function working: $([ $AUDIO_AFTER_COUNT -gt $AUDIO_BEFORE_COUNT ] && echo "✅ YES" || echo "❌ NO")"
echo
echo -e "${BLUE}📋 Sample Request Body:${NC}"
echo "$REQUEST_BODY" | jq '.'
echo 