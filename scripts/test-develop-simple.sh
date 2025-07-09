#!/bin/bash

# Simple test for develop environment
# This script tests the develop environment directly without config conflicts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Develop environment configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🧪 Simple Develop Environment Test${NC}"
echo "====================================="
echo ""

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

# Step 1: Test connectivity
print_status "info" "Step 1: Testing connectivity to develop environment..."

CONNECTIVITY_TEST=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X GET "${DEVELOP_URL}/rest/v1/" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

HTTP_STATUS=$(echo "$CONNECTIVITY_TEST" | grep "HTTPSTATUS:" | cut -d: -f2)

if [ "$HTTP_STATUS" = "200" ]; then
    print_status "success" "Develop environment accessible"
else
    print_status "error" "Cannot access develop environment (HTTP $HTTP_STATUS)"
    exit 1
fi

# Step 2: Create a test user
print_status "info" "Step 2: Creating a test user..."

TIMESTAMP=$(date +%s)
USER_EMAIL="test+develop+${TIMESTAMP}@example.com"

USER_DATA=$(cat <<EOF
{
    "email": "$USER_EMAIL",
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
    print_status "error" "Failed to create user"
    echo "Response: $USER_RESPONSE"
    exit 1
fi

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id // empty' 2>/dev/null || echo "")
if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
    print_status "error" "Failed to get user ID"
    echo "Response: $USER_RESPONSE"
    exit 1
fi

print_status "success" "Created test user: $USER_ID"

# Step 3: Create user preferences
print_status "info" "Step 3: Creating user preferences..."

PREFERENCES_DATA=$(cat <<EOF
{
    "user_id": "$USER_ID",
    "tts_voice": "nova",
    "news_categories": ["general", "technology"],
    "sports_team": "Lakers",
    "stocks": ["AAPL", "GOOGL", "TSLA"],
    "include_weather": true,
    "timezone": "America/Los_Angeles",
    "preferred_name": "TestUser"
}
EOF
)

PREFERENCES_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/user_preferences" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$PREFERENCES_DATA")

if echo "$PREFERENCES_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to create user preferences"
    echo "Response: $PREFERENCES_RESPONSE"
    exit 1
fi

print_status "success" "Created user preferences"

# Step 4: Check if queue entry was created
print_status "info" "Step 4: Checking if queue entry was created..."

sleep 2  # Give triggers time to fire

QUEUE_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/audio_generation_queue?user_id=eq.${USER_ID}" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

QUEUE_COUNT=$(echo "$QUEUE_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")

if [ "$QUEUE_COUNT" -gt 0 ]; then
    print_status "success" "Queue entry created! Found $QUEUE_COUNT entries"
    echo "Queue entries:"
    echo "$QUEUE_RESPONSE" | jq '.' 2>/dev/null || echo "$QUEUE_RESPONSE"
else
    print_status "warning" "No queue entries found. This might be expected if no alarms exist."
fi

# Step 5: Check logs
print_status "info" "Step 5: Checking logs..."

LOGS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?user_id=eq.${USER_ID}&order=created_at.desc&limit=5" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

LOGS_COUNT=$(echo "$LOGS_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")

if [ "$LOGS_COUNT" -gt 0 ]; then
    print_status "success" "Logs found! Found $LOGS_COUNT entries"
    echo "Recent logs:"
    echo "$LOGS_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGS_RESPONSE"
else
    print_status "warning" "No logs found for this user"
fi

# Step 6: Create an alarm to test alarm trigger
print_status "info" "Step 6: Creating a test alarm..."

ALARM_TIME=$(date -v+10M '+%H:%M:%S')
ALARM_DATE=$(date '+%Y-%m-%d')

ALARM_DATA=$(cat <<EOF
{
    "user_id": "$USER_ID",
    "alarm_date": "$ALARM_DATE",
    "alarm_time_local": "$ALARM_TIME",
    "alarm_timezone": "America/Los_Angeles",
    "active": true
}
EOF
)

ALARM_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/alarms" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "$ALARM_DATA")

if echo "$ALARM_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to create alarm"
    echo "Response: $ALARM_RESPONSE"
    exit 1
fi

ALARM_ID=$(echo "$ALARM_RESPONSE" | jq -r '.[0].id // empty' 2>/dev/null || echo "")
if [ -z "$ALARM_ID" ] || [ "$ALARM_ID" = "null" ]; then
    print_status "error" "Failed to get alarm ID"
    echo "Response: $ALARM_RESPONSE"
    exit 1
fi

print_status "success" "Created test alarm: $ALARM_ID"

# Step 7: Check if alarm queue entry was created
print_status "info" "Step 7: Checking if alarm queue entry was created..."

sleep 2  # Give triggers time to fire

ALARM_QUEUE_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/audio_generation_queue?alarm_id=eq.${ALARM_ID}" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

ALARM_QUEUE_COUNT=$(echo "$ALARM_QUEUE_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")

if [ "$ALARM_QUEUE_COUNT" -gt 0 ]; then
    print_status "success" "Alarm queue entry created! Found $ALARM_QUEUE_COUNT entries"
    echo "Alarm queue entries:"
    echo "$ALARM_QUEUE_RESPONSE" | jq '.' 2>/dev/null || echo "$ALARM_QUEUE_RESPONSE"
else
    print_status "warning" "No alarm queue entries found"
fi

# Summary
echo ""
print_status "info" "Test Summary:"
echo "  • User created: $USER_ID"
echo "  • Preferences created: ✅"
echo "  • Alarm created: $ALARM_ID"
echo "  • Queue entries (preferences): $QUEUE_COUNT"
echo "  • Queue entries (alarm): $ALARM_QUEUE_COUNT"
echo "  • Log entries: $LOGS_COUNT"

if [ "$QUEUE_COUNT" -gt 0 ] || [ "$ALARM_QUEUE_COUNT" -gt 0 ]; then
    print_status "success" "🎉 Develop environment triggers are working!"
else
    print_status "warning" "⚠️  No queue entries found. Triggers may not be firing."
fi

echo ""
print_status "info" "Test completed successfully!" 