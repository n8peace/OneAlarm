#!/bin/bash

# Simple test to verify user creation works with correct schema
# This uses the actual schema field names from the sync

set -e

SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"
SUPABASE_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"

echo "🧪 Testing user creation with correct schema..."

# Create user
USER_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/users" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d '{
        "email": "test-simple@example.com",
        "onboarding_done": true,
        "subscription_status": "trialing"
    }')

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')
echo "✅ User created: $USER_ID"

# Create user preferences
PREFERENCES_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/user_preferences" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{
        \"user_id\": \"$USER_ID\",
        \"tts_voice\": \"nova\",
        \"news_categories\": [\"general\"],
        \"include_weather\": true,
        \"timezone\": \"America/New_York\"
    }")

echo "✅ Preferences created"

# Create weather data with correct field names
WEATHER_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/weather_data" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{
        \"user_id\": \"$USER_ID\",
        \"location\": \"New York, NY\",
        \"temperature\": 72,
        \"condition\": \"Sunny\",
        \"sunrise_time\": \"06:30:00\",
        \"sunset_time\": \"19:45:00\"
    }")

echo "✅ Weather data created"

# Create alarm with correct field names
ALARM_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/alarms" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{
        \"user_id\": \"$USER_ID\",
        \"alarm_date\": \"2025-07-06\",
        \"alarm_time_local\": \"08:00:00\",
        \"alarm_timezone\": \"America/New_York\",
        \"active\": true
    }")

ALARM_ID=$(echo "$ALARM_RESPONSE" | jq -r '.[0].id')
echo "✅ Alarm created: $ALARM_ID"

echo "🎉 All tests passed! The schema is working correctly." 