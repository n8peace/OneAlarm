#!/bin/bash

# Debug script to identify which column triggers the net extension error
# This will help pinpoint the exact source of the issue

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

echo -e "${BLUE}🔍 Debug: Column-Specific Net Extension Error Detection${NC}"
echo "======================================================="
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

# Step 1: Get an existing user for testing
print_status "info" "Step 1: Getting test user..."

USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "error" "No users found for testing"
    exit 1
fi

print_status "success" "Using test user: $EXISTING_USER_ID"

# Step 2: Test UPDATE with updated_at (simple timestamp)
print_status "info" "Step 2: Testing UPDATE with updated_at column..."

UPDATED_AT_DATA=$(cat <<EOF
{
  "updated_at": "2025-07-06T20:00:00Z"
}
EOF
)

UPDATED_AT_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$UPDATED_AT_DATA")

UPDATED_AT_HTTP_STATUS=$(echo "$UPDATED_AT_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
UPDATED_AT_BODY=$(echo "$UPDATED_AT_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "updated_at UPDATE test: HTTP $UPDATED_AT_HTTP_STATUS"

if [ "$UPDATED_AT_HTTP_STATUS" = "200" ] || [ "$UPDATED_AT_HTTP_STATUS" = "204" ]; then
    print_status "success" "updated_at UPDATE working correctly!"
else
    print_status "error" "updated_at UPDATE failed (HTTP $UPDATED_AT_HTTP_STATUS)"
    echo "Error response: $UPDATED_AT_BODY"
fi

# Step 3: Test UPDATE with timezone
print_status "info" "Step 3: Testing UPDATE with timezone column..."

TIMEZONE_DATA=$(cat <<EOF
{
  "timezone": "America/Los_Angeles"
}
EOF
)

TIMEZONE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$TIMEZONE_DATA")

TIMEZONE_HTTP_STATUS=$(echo "$TIMEZONE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
TIMEZONE_BODY=$(echo "$TIMEZONE_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "timezone UPDATE test: HTTP $TIMEZONE_HTTP_STATUS"

if [ "$TIMEZONE_HTTP_STATUS" = "200" ] || [ "$TIMEZONE_HTTP_STATUS" = "204" ]; then
    print_status "success" "timezone UPDATE working correctly!"
else
    print_status "error" "timezone UPDATE failed (HTTP $TIMEZONE_HTTP_STATUS)"
    echo "Error response: $TIMEZONE_BODY"
fi

# Step 4: Test UPDATE with news_categories
print_status "info" "Step 4: Testing UPDATE with news_categories column..."

NEWS_CATEGORIES_DATA=$(cat <<EOF
{
  "news_categories": ["general", "sports"]
}
EOF
)

NEWS_CATEGORIES_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$NEWS_CATEGORIES_DATA")

NEWS_CATEGORIES_HTTP_STATUS=$(echo "$NEWS_CATEGORIES_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
NEWS_CATEGORIES_BODY=$(echo "$NEWS_CATEGORIES_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "news_categories UPDATE test: HTTP $NEWS_CATEGORIES_HTTP_STATUS"

if [ "$NEWS_CATEGORIES_HTTP_STATUS" = "200" ] || [ "$NEWS_CATEGORIES_HTTP_STATUS" = "204" ]; then
    print_status "success" "news_categories UPDATE working correctly!"
else
    print_status "error" "news_categories UPDATE failed (HTTP $NEWS_CATEGORIES_HTTP_STATUS)"
    echo "Error response: $NEWS_CATEGORIES_BODY"
fi

# Step 5: Test UPDATE with sports_team
print_status "info" "Step 5: Testing UPDATE with sports_team column..."

SPORTS_TEAM_DATA=$(cat <<EOF
{
  "sports_team": "Celtics"
}
EOF
)

SPORTS_TEAM_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$SPORTS_TEAM_DATA")

SPORTS_TEAM_HTTP_STATUS=$(echo "$SPORTS_TEAM_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
SPORTS_TEAM_BODY=$(echo "$SPORTS_TEAM_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "sports_team UPDATE test: HTTP $SPORTS_TEAM_HTTP_STATUS"

if [ "$SPORTS_TEAM_HTTP_STATUS" = "200" ] || [ "$SPORTS_TEAM_HTTP_STATUS" = "204" ]; then
    print_status "success" "sports_team UPDATE working correctly!"
else
    print_status "error" "sports_team UPDATE failed (HTTP $SPORTS_TEAM_HTTP_STATUS)"
    echo "Error response: $SPORTS_TEAM_BODY"
fi

# Step 6: Test UPDATE with stocks
print_status "info" "Step 6: Testing UPDATE with stocks column..."

STOCKS_DATA=$(cat <<EOF
{
  "stocks": ["AAPL", "GOOGL"]
}
EOF
)

STOCKS_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$STOCKS_DATA")

STOCKS_HTTP_STATUS=$(echo "$STOCKS_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
STOCKS_BODY=$(echo "$STOCKS_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "stocks UPDATE test: HTTP $STOCKS_HTTP_STATUS"

if [ "$STOCKS_HTTP_STATUS" = "200" ] || [ "$STOCKS_HTTP_STATUS" = "204" ]; then
    print_status "success" "stocks UPDATE working correctly!"
else
    print_status "error" "stocks UPDATE failed (HTTP $STOCKS_HTTP_STATUS)"
    echo "Error response: $STOCKS_BODY"
fi

# Step 7: Test UPDATE with include_weather
print_status "info" "Step 7: Testing UPDATE with include_weather column..."

INCLUDE_WEATHER_DATA=$(cat <<EOF
{
  "include_weather": false
}
EOF
)

INCLUDE_WEATHER_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$INCLUDE_WEATHER_DATA")

INCLUDE_WEATHER_HTTP_STATUS=$(echo "$INCLUDE_WEATHER_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
INCLUDE_WEATHER_BODY=$(echo "$INCLUDE_WEATHER_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "include_weather UPDATE test: HTTP $INCLUDE_WEATHER_HTTP_STATUS"

if [ "$INCLUDE_WEATHER_HTTP_STATUS" = "200" ] || [ "$INCLUDE_WEATHER_HTTP_STATUS" = "204" ]; then
    print_status "success" "include_weather UPDATE working correctly!"
else
    print_status "error" "include_weather UPDATE failed (HTTP $INCLUDE_WEATHER_HTTP_STATUS)"
    echo "Error response: $INCLUDE_WEATHER_BODY"
fi

# Step 8: Test UPDATE with preferred_name
print_status "info" "Step 8: Testing UPDATE with preferred_name column..."

PREFERRED_NAME_DATA=$(cat <<EOF
{
  "preferred_name": "Test User"
}
EOF
)

PREFERRED_NAME_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$PREFERRED_NAME_DATA")

PREFERRED_NAME_HTTP_STATUS=$(echo "$PREFERRED_NAME_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
PREFERRED_NAME_BODY=$(echo "$PREFERRED_NAME_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "preferred_name UPDATE test: HTTP $PREFERRED_NAME_HTTP_STATUS"

if [ "$PREFERRED_NAME_HTTP_STATUS" = "200" ] || [ "$PREFERRED_NAME_HTTP_STATUS" = "204" ]; then
    print_status "success" "preferred_name UPDATE working correctly!"
else
    print_status "error" "preferred_name UPDATE failed (HTTP $PREFERRED_NAME_HTTP_STATUS)"
    echo "Error response: $PREFERRED_NAME_BODY"
fi

# Step 9: Test UPDATE with tts_voice (the problematic one)
print_status "info" "Step 9: Testing UPDATE with tts_voice column..."

TTS_VOICE_DATA=$(cat <<EOF
{
  "tts_voice": "alloy"
}
EOF
)

TTS_VOICE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d "$TTS_VOICE_DATA")

TTS_VOICE_HTTP_STATUS=$(echo "$TTS_VOICE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
TTS_VOICE_BODY=$(echo "$TTS_VOICE_RESPONSE" | grep -v "HTTPSTATUS:")

print_status "info" "tts_voice UPDATE test: HTTP $TTS_VOICE_HTTP_STATUS"

if [ "$TTS_VOICE_HTTP_STATUS" = "200" ] || [ "$TTS_VOICE_HTTP_STATUS" = "204" ]; then
    print_status "success" "tts_voice UPDATE working correctly!"
else
    print_status "error" "tts_voice UPDATE failed (HTTP $TTS_VOICE_HTTP_STATUS)"
    echo "Error response: $TTS_VOICE_BODY"
fi

# Step 10: Summary
print_status "info" "Step 10: Column Test Summary"
echo "=========================="
echo "• updated_at: HTTP $UPDATED_AT_HTTP_STATUS"
echo "• timezone: HTTP $TIMEZONE_HTTP_STATUS"
echo "• news_categories: HTTP $NEWS_CATEGORIES_HTTP_STATUS"
echo "• sports_team: HTTP $SPORTS_TEAM_HTTP_STATUS"
echo "• stocks: HTTP $STOCKS_HTTP_STATUS"
echo "• include_weather: HTTP $INCLUDE_WEATHER_HTTP_STATUS"
echo "• preferred_name: HTTP $PREFERRED_NAME_HTTP_STATUS"
echo "• tts_voice: HTTP $TTS_VOICE_HTTP_STATUS"
echo

# Identify which columns are failing
FAILING_COLUMNS=()
if [ "$UPDATED_AT_HTTP_STATUS" != "200" ] && [ "$UPDATED_AT_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("updated_at")
fi
if [ "$TIMEZONE_HTTP_STATUS" != "200" ] && [ "$TIMEZONE_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("timezone")
fi
if [ "$NEWS_CATEGORIES_HTTP_STATUS" != "200" ] && [ "$NEWS_CATEGORIES_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("news_categories")
fi
if [ "$SPORTS_TEAM_HTTP_STATUS" != "200" ] && [ "$SPORTS_TEAM_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("sports_team")
fi
if [ "$STOCKS_HTTP_STATUS" != "200" ] && [ "$STOCKS_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("stocks")
fi
if [ "$INCLUDE_WEATHER_HTTP_STATUS" != "200" ] && [ "$INCLUDE_WEATHER_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("include_weather")
fi
if [ "$PREFERRED_NAME_HTTP_STATUS" != "200" ] && [ "$PREFERRED_NAME_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("preferred_name")
fi
if [ "$TTS_VOICE_HTTP_STATUS" != "200" ] && [ "$TTS_VOICE_HTTP_STATUS" != "204" ]; then
    FAILING_COLUMNS+=("tts_voice")
fi

if [ ${#FAILING_COLUMNS[@]} -eq 0 ]; then
    print_status "success" "🎉 All column UPDATE operations working correctly!"
    print_status "info" "The net extension error appears to be resolved"
elif [ ${#FAILING_COLUMNS[@]} -eq 1 ]; then
    print_status "error" "❌ Column ${FAILING_COLUMNS[0]} is causing the net extension error"
    print_status "info" "Check for default values or constraints on this column"
else
    print_status "error" "❌ Multiple columns are failing: ${FAILING_COLUMNS[*]}"
    print_status "info" "This suggests a system-level issue affecting all columns"
fi 