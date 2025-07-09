#!/bin/bash

# Test user preferences trigger script
# This script tests that the trigger works by updating a user preference

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

echo -e "${BLUE}🧪 Testing User Preferences Trigger${NC}"
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

# Step 1: Find a test user with preferences and alarms
print_status "info" "Step 1: Finding a test user with preferences and alarms..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=5" \
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

# Step 2: Check user preferences
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

# Step 3: Check if user has alarms
print_status "info" "Step 3: Checking if user has alarms..."

ALARMS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/alarms?user_id=eq.${TEST_USER_ID}&select=id,active&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$ALARMS_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to fetch alarms"
    echo "Response: $ALARMS_RESPONSE"
    exit 1
fi

ALARMS_COUNT=$(echo "$ALARMS_RESPONSE" | jq '. | length')
if [ "$ALARMS_COUNT" -eq 0 ]; then
    print_status "warning" "No alarms found for user. Creating a test alarm..."
    
    # Create a test alarm
    TOMORROW=$(date -v+1d +%Y-%m-%d)
    CREATE_ALARM_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/alarms" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d "{
        \"user_id\": \"${TEST_USER_ID}\",
        \"alarm_date\": \"${TOMORROW}\",
        \"alarm_time_local\": \"07:00:00\",
        \"alarm_timezone\": \"America/New_York\",
        \"active\": true
      }")
    
    if echo "$CREATE_ALARM_RESPONSE" | grep -q "error"; then
        print_status "error" "Failed to create test alarm"
        echo "Response: $CREATE_ALARM_RESPONSE"
        exit 1
    else
        print_status "success" "Created test alarm"
    fi
else
    print_status "success" "Found $ALARMS_COUNT existing alarms"
fi

# Step 4: Get current queue count before test
print_status "info" "Step 4: Checking current queue count..."

QUEUE_BEFORE_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/audio_generation_queue?user_id=eq.${TEST_USER_ID}&select=count" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

QUEUE_BEFORE_COUNT=$(echo "$QUEUE_BEFORE_RESPONSE" | jq '. | length')
print_status "info" "Queue items before test: $QUEUE_BEFORE_COUNT"

# Step 5: Update user preference to trigger the function
print_status "info" "Step 5: Updating user preference to trigger audio generation..."

UPDATE_RESPONSE=$(curl -s -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.${TEST_USER_ID}" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d '{
    "tts_voice": "nova"
  }')

if echo "$UPDATE_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to update user preference"
    echo "Response: $UPDATE_RESPONSE"
    exit 1
else
    print_status "success" "Updated user preference (tts_voice: alloy → nova)"
fi

# Step 6: Wait a moment for the trigger to execute
print_status "info" "Step 6: Waiting for trigger to execute..."
sleep 3

# Step 7: Check if queue items were created
print_status "info" "Step 7: Checking if queue items were created..."

QUEUE_AFTER_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/audio_generation_queue?user_id=eq.${TEST_USER_ID}&select=*&order=created_at.desc" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

QUEUE_AFTER_COUNT=$(echo "$QUEUE_AFTER_RESPONSE" | jq '. | length')
print_status "info" "Queue items after test: $QUEUE_AFTER_COUNT"

if [ "$QUEUE_AFTER_COUNT" -gt "$QUEUE_BEFORE_COUNT" ]; then
    print_status "success" "✅ TRIGGER WORKING! Queue items increased from $QUEUE_BEFORE_COUNT to $QUEUE_AFTER_COUNT"
    
    # Show the new queue items
    echo "New queue items:"
    echo "$QUEUE_AFTER_RESPONSE" | jq '.[0:3] | .[] | "• \(.alarm_id): \(.status) - \(.scheduled_for)"'
else
    print_status "warning" "⚠️ No new queue items created. Checking logs..."
    
    # Check logs for trigger execution
    LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?event_type=eq.preferences_updated_audio_trigger&user_id=eq.${TEST_USER_ID}&select=*&order=created_at.desc&limit=5" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")
    
    LOGS_COUNT=$(echo "$LOGS_RESPONSE" | jq '. | length')
    if [ "$LOGS_COUNT" -gt 0 ]; then
        print_status "success" "✅ Trigger executed! Found $LOGS_COUNT log entries"
        echo "Recent trigger logs:"
        echo "$LOGS_RESPONSE" | jq '.[0:2] | .[] | "• \(.created_at): \(.meta.action)"'
    else
        print_status "error" "❌ No trigger logs found. Trigger may not be working."
    fi
fi

# Step 8: Check for any errors in logs
print_status "info" "Step 8: Checking for errors in recent logs..."

ERROR_LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?select=*&order=created_at.desc&limit=10" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

ERROR_COUNT=$(echo "$ERROR_LOGS_RESPONSE" | jq '[.[] | select(.event_type | contains("error"))] | length')
if [ "$ERROR_COUNT" -gt 0 ]; then
    print_status "warning" "Found $ERROR_COUNT recent error logs"
    echo "Recent errors:"
    echo "$ERROR_LOGS_RESPONSE" | jq '[.[] | select(.event_type | contains("error"))] | .[0:3] | .[] | "• \(.created_at): \(.event_type) - \(.meta)"'
else
    print_status "success" "No recent errors found"
fi

echo
print_status "success" "Test completed!"
echo
echo -e "${BLUE}📋 Summary:${NC}"
echo "• Test user: $TEST_USER_ID"
echo "• Queue items before: $QUEUE_BEFORE_COUNT"
echo "• Queue items after: $QUEUE_AFTER_COUNT"
echo "• Trigger working: $([ $QUEUE_AFTER_COUNT -gt $QUEUE_BEFORE_COUNT ] && echo "✅ YES" || echo "❌ NO")"
echo
