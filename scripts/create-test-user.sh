#!/bin/bash

# Enhanced Test User Creation Script
# Creates single or multiple test users with varied preferences

set -e

# Source shared configuration
source ./scripts/config.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}👤 OneAlarm Test User Creation${NC}"
echo "================================"
echo ""

# Check if service role key is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo ""
    echo "Usage: ./scripts/create-test-user.sh YOUR_SERVICE_ROLE_KEY [COUNT]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/create-test-user.sh YOUR_KEY        # Create 1 test user"
    echo "  ./scripts/create-test-user.sh YOUR_KEY 5      # Create 5 test users"
    echo "  ./scripts/create-test-user.sh YOUR_KEY 10     # Create 10 test users"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to ${SUPABASE_URL}/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
fi

SERVICE_ROLE_KEY="$1"
USER_COUNT="${2:-1}"

echo -e "${CYAN}📋 Project:${NC} $SUPABASE_URL"
echo -e "${CYAN}👥 Creating:${NC} $USER_COUNT test user(s)"
echo ""

# Test user configurations
USER_CONFIGS=(
    # User 1: Basic preferences
    '{"tts_voice":"alloy","news_categories":["general"],"sports_team":null,"stocks":null,"include_weather":true,"timezone":"America/New_York","preferred_name":"Alex"}'
    
    # User 2: Business focused
    '{"tts_voice":"nova","news_categories":["business"],"sports_team":null,"stocks":["AAPL","GOOGL"],"include_weather":true,"timezone":"America/Los_Angeles","preferred_name":"Jordan"}'
    
    # User 3: Sports enthusiast
    '{"tts_voice":"echo","news_categories":["sports"],"sports_team":"Lakers","stocks":null,"include_weather":false,"timezone":"America/Chicago","preferred_name":"Casey"}'
    
    # User 4: Tech focused
    '{"tts_voice":"onyx","news_categories":["technology"],"sports_team":null,"stocks":["TSLA","NVDA"],"include_weather":true,"timezone":"America/Denver","preferred_name":"Taylor"}'
    
    # User 5: Comprehensive
    '{"tts_voice":"shimmer","news_categories":["general","business","technology"],"sports_team":"Warriors","stocks":["MSFT","AMZN"],"include_weather":true,"timezone":"America/Phoenix","preferred_name":"Morgan"}'
    
    # User 6: Minimalist
    '{"tts_voice":"fable","news_categories":["general"],"sports_team":null,"stocks":null,"include_weather":false,"timezone":"America/Seattle","preferred_name":"Riley"}'
    
    # User 7: Stock trader
    '{"tts_voice":"ash","news_categories":["business"],"sports_team":null,"stocks":["SPY","QQQ","IWM"],"include_weather":true,"timezone":"America/New_York","preferred_name":"Drew"}'
    
    # User 8: Multi-sport
    '{"tts_voice":"verse","news_categories":["sports"],"sports_team":"Celtics","stocks":null,"include_weather":true,"timezone":"America/Boston","preferred_name":"Sam"}'
    
    # User 9: Default preferences
    '{"tts_voice":null,"news_categories":["general"],"sports_team":null,"stocks":null,"include_weather":false,"timezone":null,"preferred_name":null}'
    
    # User 10: Inspiring preferences
    '{"tts_voice":"shimmer","news_categories":["general"],"sports_team":"Spurs","stocks":null,"include_weather":true,"timezone":"America/Los_Angeles","preferred_name":"Maya"}'
)

# Function to create a single test user
create_test_user() {
    local user_index="$1"
    local config_index="$2"
    
    # Generate a unique email for the test user
    TEST_USER_EMAIL="test+$(date +%s)-${user_index}@example.com"
    
    echo -e "${CYAN}👤 Creating user $user_index${NC}"
    
    # Create test user (let database auto-generate UUID)
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
        echo -e "${GREEN}  ✅ User created with ID: $TEST_USER_ID${NC}"
    else
        echo -e "${RED}  ❌ User creation failed: $USER_RESPONSE${NC}"
        return 1
    fi
    
    # Create user preferences using upsert logic
    local user_config="${USER_CONFIGS[$config_index]}"
    local preferences_data=$(echo "$user_config" | jq --arg user_id "$TEST_USER_ID" '. + {"user_id": $user_id}')
    
    PREFERENCES_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/user_preferences" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$preferences_data")
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ Preferences created${NC}"
    else
        echo -e "${RED}  ❌ Preferences creation failed: $PREFERENCES_RESPONSE${NC}"
    fi
    
    # Create weather data
    WEATHER_DATA=$(cat <<EOF
{
    "user_id": "$TEST_USER_ID",
    "location": "New York, NY",
    "current_temp": 72,
    "high_temp": 78,
    "low_temp": 65,
    "condition": "Partly Cloudy",
    "sunrise_time": "06:30",
    "sunset_time": "19:45"
}
EOF
)
    
    WEATHER_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/weather_data" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$WEATHER_DATA")
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✅ Weather data created${NC}"
    else
        echo -e "${RED}  ❌ Weather data creation failed: $WEATHER_RESPONSE${NC}"
    fi
    
    echo -e "${GREEN}  ✅ User $user_index complete: $TEST_USER_ID${NC}"
    echo ""
}

# Create users
echo -e "${BLUE}🚀 Creating test users...${NC}"
echo ""

for i in $(seq 1 $USER_COUNT); do
    config_index=$(( (i - 1) % ${#USER_CONFIGS[@]} ))
    create_test_user $i $config_index
done

echo -e "${GREEN}🎉 Test user creation completed!${NC}"
echo -e "${CYAN}📊 Created $USER_COUNT test users${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Create test alarms: ./scripts/create-test-alarm.sh YOUR_SERVICE_ROLE_KEY"
echo "2. Run system tests: ./scripts/test-system.sh e2e YOUR_SERVICE_ROLE_KEY"
echo "3. Check system status: ./scripts/check-system-status.sh YOUR_SERVICE_ROLE_KEY" 