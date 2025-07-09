#!/bin/bash

# Test script to check if user preferences UPDATE operations work
# This will help determine if the net extension error is resolved

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

echo -e "${BLUE}🔍 Testing User Preferences UPDATE Operations${NC}"
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

# Step 1: Get existing user preferences
print_status "info" "Step 1: Getting existing user preferences..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "error" "No users found for testing"
    exit 1
fi

print_status "success" "Using user: $EXISTING_USER_ID"

# Get current preferences
PREFERENCES_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$PREFERENCES_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to get user preferences"
    echo "Response: $PREFERENCES_RESPONSE"
    exit 1
fi

print_status "success" "Current preferences retrieved"
echo "Current preferences:"
echo "$PREFERENCES_RESPONSE" | jq '.'

# Step 2: Test UPDATE operation
print_status "info" "Step 2: Testing UPDATE operation..."

UPDATE_DATA=$(cat <<EOF
{
  "tts_voice": "nova",
  "preferred_name": "Updated Test User",
  "timezone": "America/Los_Angeles"
}
EOF
)

print_status "info" "Updating preferences with data:"
echo "$UPDATE_DATA" | jq '.'

UPDATE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "$UPDATE_DATA")

UPDATE_HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
UPDATE_BODY=$(echo "$UPDATE_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "UPDATE response status: $UPDATE_HTTP_STATUS"

if [ "$UPDATE_HTTP_STATUS" = "200" ]; then
    print_status "success" "User preferences updated successfully!"
    echo "Updated preferences:"
    echo "$UPDATE_BODY" | jq '.'
    
    # Check if the update triggered any audio generation
    print_status "info" "Checking if audio generation was triggered..."
    
    # Wait a moment for any async operations
    sleep 2
    
    # Check logs for audio generation trigger
    LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?event_type=eq.preferences_updated_audio_trigger&user_id=eq.$EXISTING_USER_ID&order=created_at.desc&limit=1" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")
    
    if echo "$LOGS_RESPONSE" | jq -e '.[0]' > /dev/null 2>&1; then
        print_status "success" "Audio generation trigger logged successfully"
        echo "Trigger log:"
        echo "$LOGS_RESPONSE" | jq '.[0]'
    else
        print_status "warning" "No audio generation trigger log found"
    fi
    
else
    print_status "error" "User preferences update failed (HTTP $UPDATE_HTTP_STATUS)"
    echo "Error response: $UPDATE_BODY"
    
    # Check if it's the net extension error
    if echo "$UPDATE_BODY" | grep -q "net"; then
        print_status "error" "🎯 CONFIRMED: Net extension error still exists during UPDATE"
    fi
fi

# Step 3: Test INSERT with a new user
print_status "info" "Step 3: Testing INSERT with a new user..."

# Create a new user for testing
NEW_USER_EMAIL="test+$(date +%s)@example.com"
USER_DATA=$(cat <<EOF
{
  "email": "$NEW_USER_EMAIL",
  "password": "testpassword123"
}
EOF
)

print_status "info" "Creating new user: $NEW_USER_EMAIL"

NEW_USER_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X POST "${DEVELOP_URL}/auth/v1/signup" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "$USER_DATA")

NEW_USER_HTTP_STATUS=$(echo "$NEW_USER_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
NEW_USER_BODY=$(echo "$NEW_USER_RESPONSE" | grep -v "HTTPSTATUS:")

if [ "$NEW_USER_HTTP_STATUS" = "200" ] || [ "$NEW_USER_HTTP_STATUS" = "201" ]; then
    NEW_USER_ID=$(echo "$NEW_USER_BODY" | jq -r '.user.id // empty')
    print_status "success" "New user created: $NEW_USER_ID"
    
    # Now try to create preferences for the new user
    NEW_PREFERENCES_DATA=$(cat <<EOF
{
  "user_id": "$NEW_USER_ID",
  "timezone": "Europe/London",
  "tts_voice": "echo",
  "preferred_name": "New Test User"
}
EOF
)
    
    print_status "info" "Creating preferences for new user..."
    
    NEW_PREFERENCES_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=representation" \
      -d "$NEW_PREFERENCES_DATA")
    
    NEW_PREFERENCES_HTTP_STATUS=$(echo "$NEW_PREFERENCES_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
    NEW_PREFERENCES_BODY=$(echo "$NEW_PREFERENCES_RESPONSE" | grep -v "HTTPSTATUS:")
    
    if [ "$NEW_PREFERENCES_HTTP_STATUS" = "201" ]; then
        print_status "success" "New user preferences created successfully!"
        echo "New preferences:"
        echo "$NEW_PREFERENCES_BODY" | jq '.'
    else
        print_status "error" "New user preferences creation failed (HTTP $NEW_PREFERENCES_HTTP_STATUS)"
        echo "Error response: $NEW_PREFERENCES_BODY"
        
        if echo "$NEW_PREFERENCES_BODY" | grep -q "net"; then
            print_status "error" "🎯 CONFIRMED: Net extension error still exists during INSERT"
        fi
    fi
else
    print_status "warning" "Failed to create new user (HTTP $NEW_USER_HTTP_STATUS)"
    echo "Response: $NEW_USER_BODY"
fi

# Step 4: Summary
print_status "info" "Step 4: Test Summary"
echo "=================="
echo "• Existing user preferences: ✅"
echo "• UPDATE operation: HTTP $UPDATE_HTTP_STATUS"
echo "• New user creation: HTTP $NEW_USER_HTTP_STATUS"
echo "• New user preferences: HTTP $NEW_PREFERENCES_HTTP_STATUS"
echo

if [ "$UPDATE_HTTP_STATUS" = "200" ] && [ "$NEW_PREFERENCES_HTTP_STATUS" = "201" ]; then
    print_status "success" "🎉 All user preferences operations working correctly!"
    print_status "info" "The net extension error appears to be resolved"
else
    print_status "error" "❌ Some operations still failing"
    print_status "info" "Check the specific error messages above"
fi 