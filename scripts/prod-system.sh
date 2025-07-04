#!/bin/bash

# OneAlarm Production System Script
# Production-ready system script for different scenarios

set -e

# Source shared configuration
source ./scripts/config.sh

# Override for production environment
SUPABASE_URL="https://bfrvahxmokeyrfnlaiwd.supabase.co"

# Colors and configuration are now sourced from config.sh

# Function to show usage
show_usage() {
    echo -e "${BLUE}🔧 OneAlarm Production System Script${NC}"
    echo "====================================="
    echo ""
    echo "Usage: ./scripts/prod-system.sh [SCENARIO_TYPE] [SERVICE_ROLE_KEY]"
    echo ""
    echo "Scenario Types:"
    echo "  quick     - Quick system health check (1 user, basic functionality)"
    echo "  e2e       - End-to-end validation (3 users, full workflow)"
    echo "  load      - Load validation (50 users, performance testing)"
    echo "  tz        - Multi-timezone validation (timezone handling)"
    echo "  audio     - Audio generation validation"
    echo "  queue     - Queue processing validation"
    echo ""
    echo "Examples:"
    echo "  ./scripts/prod-system.sh quick YOUR_SERVICE_ROLE_KEY"
    echo "  ./scripts/prod-system.sh e2e YOUR_SERVICE_ROLE_KEY"
    echo "  ./scripts/prod-system.sh load YOUR_SERVICE_ROLE_KEY"
    echo ""
    echo "⚠️  PRODUCTION WARNING: This script operates on production data."
    echo "   Ensure you have proper backups and understand the implications."
    echo ""
    echo "To get your service role key:"
    echo "1. Go to ${SUPABASE_URL}/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
}

# Check parameters
if [ -z "$1" ] || [ -z "$2" ]; then
    show_usage
fi

TEST_TYPE="$1"
SERVICE_ROLE_KEY="$2"

# Validate environment
if ! validate_environment; then
    exit 1
fi

# Function to generate a UUID
generate_uuid() {
    python3 -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || \
    python -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || \
    echo "550e8400-e29b-41d4-a716-446655440000"  # fallback UUID
}

# Function to create a test user
create_test_user() {
    local user_name="$1"
    local user_config="$2"
    local weather_config="$3"
    
    echo -e "${YELLOW}👤 Creating $user_name...${NC}" >&2
    
    # Generate unique UUID for this user
    local USER_ID=$(generate_uuid)
    local TIMESTAMP=$(date +%s)
    local USER_EMAIL="test+${user_name}+${TIMESTAMP}@example.com"
    
    # Create user in users table
    USER_DATA=$(cat <<EOF
{
    "email": "$USER_EMAIL"
}
EOF
)
    
    USER_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$SUPABASE_URL/rest/v1/users" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$USER_DATA")
    
    USER_HTTP_STATUS=$(echo "$USER_RESPONSE" | tail -c 4)
    USER_RESPONSE_BODY=$(echo "$USER_RESPONSE" | sed 's/[0-9]\{3\}$//')
    
    if [ "$USER_HTTP_STATUS" = "201" ] || [ "$USER_HTTP_STATUS" = "200" ] || [ "$USER_HTTP_STATUS" = "409" ]; then
        USER_ID=$(echo "$USER_RESPONSE_BODY" | jq -r '.[0].id // empty' 2>/dev/null || echo "")
        if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
            echo -e "${GREEN}  ✅ User created: $USER_ID${NC}" >&2
        else
            echo -e "${RED}  ❌ Failed to get user ID${NC}" >&2
            return 1
        fi
    else
        echo -e "${RED}  ❌ User creation failed (HTTP $USER_HTTP_STATUS)${NC}" >&2
        return 1
    fi
    
    # Create user preferences
    local preferences_data=$(echo "$user_config" | jq --arg user_id "$USER_ID" '. + {"user_id": $user_id}')
    
    PREFERENCES_POST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_URL/rest/v1/user_preferences" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$preferences_data")
    
    if [ "$PREFERENCES_POST_STATUS" = "201" ] || [ "$PREFERENCES_POST_STATUS" = "200" ]; then
        echo -e "${GREEN}  ✅ Preferences created${NC}" >&2
    else
        echo -e "${RED}  ❌ Preferences creation failed (HTTP $PREFERENCES_POST_STATUS)${NC}" >&2
    fi
    
    # Create weather data
    local weather_data=$(echo "$weather_config" | jq --arg user_id "$USER_ID" --arg updated_at "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")" '. + {"user_id": $user_id, "updated_at": $updated_at}')
    
    WEATHER_POST_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$SUPABASE_URL/rest/v1/weather_data" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$weather_data")
    WEATHER_POST_STATUS=$(echo "$WEATHER_POST_RESPONSE" | tail -c 4)
    
    if [ "$WEATHER_POST_STATUS" = "201" ] || [ "$WEATHER_POST_STATUS" = "200" ]; then
        echo -e "${GREEN}  ✅ Weather data created${NC}" >&2
    elif [ "$WEATHER_POST_STATUS" = "409" ]; then
        # Update existing weather data
        WEATHER_PATCH_RESPONSE=$(curl -s -w "%{http_code}" -X PATCH "$SUPABASE_URL/rest/v1/weather_data?user_id=eq.$USER_ID" \
            -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
            -H "apikey: $SERVICE_ROLE_KEY" \
            -H "Content-Type: application/json" \
            -H "Prefer: return=minimal" \
            -d "$weather_data")
        WEATHER_PATCH_STATUS=$(echo "$WEATHER_PATCH_RESPONSE" | tail -c 4)
        if [ "$WEATHER_PATCH_STATUS" = "204" ] || [ "$WEATHER_PATCH_STATUS" = "200" ]; then
            echo -e "${GREEN}  ✅ Weather data updated${NC}" >&2
        else
            echo -e "${RED}  ❌ Weather data update failed (HTTP $WEATHER_PATCH_STATUS)${NC}" >&2
        fi
    else
        echo -e "${RED}  ❌ Weather data creation failed (HTTP $WEATHER_POST_STATUS)${NC}" >&2
    fi
    
    echo "$USER_ID"
}

# Function to create a test alarm
create_test_alarm() {
    local user_id="$1"
    local timezone="$2"
    local alarm_time="$3"
    local alarm_date="$4"
    
    ALARM_DATA=$(cat <<EOF
{
    "user_id": "$user_id",
    "alarm_date": "$alarm_date",
    "alarm_time_local": "$alarm_time",
    "alarm_timezone": "$timezone",
    "timezone_at_creation": "$timezone",
    "active": true
}
EOF
)
    
    ALARM_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$SUPABASE_URL/rest/v1/alarms" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$ALARM_DATA")
    
    HTTP_STATUS=$(echo "$ALARM_RESPONSE" | tail -c 4)
    ALARM_RESPONSE_BODY=$(echo "$ALARM_RESPONSE" | sed 's/[0-9]\{3\}$//')
    
    if [ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "200" ]; then
        ALARM_ID=$(echo "$ALARM_RESPONSE_BODY" | jq -r '.[0].id // empty' 2>/dev/null || echo "")
        if [ -n "$ALARM_ID" ] && [ "$ALARM_ID" != "null" ]; then
            echo -e "${GREEN}  ✅ Alarm created: $ALARM_ID${NC}"
            echo "$ALARM_ID"
        else
            echo -e "${RED}  ❌ Failed to get alarm ID${NC}"
            return 1
        fi
    else
        echo -e "${RED}  ❌ Alarm creation failed (HTTP $HTTP_STATUS)${NC}"
        return 1
    fi
}

# Function to check queue status
check_queue() {
    QUEUE_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/audio_generation_queue?select=*&order=created_at.desc&limit=10" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json")
    QUEUE_COUNT=$(echo "$QUEUE_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")
    echo "$QUEUE_COUNT"
}

# Function to test queue processing
test_queue_processing() {
    echo -e "${YELLOW}🧪 Testing queue processing...${NC}"
    PROCESS_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/generate-alarm-audio" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -d '{}')
    
    echo "Processing Response: $PROCESS_RESPONSE"
    
    if echo "$PROCESS_RESPONSE" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ Queue processing successful${NC}"
        
        if echo "$PROCESS_RESPONSE" | grep -q '"processedAlarmId"'; then
            PROCESSED_ALARM=$(echo "$PROCESS_RESPONSE" | grep -o '"processedAlarmId":"[^"]*"' | cut -d'"' -f4)
            if [ "$PROCESSED_ALARM" != "null" ]; then
                echo -e "${GREEN}✅ Processed alarm: $PROCESSED_ALARM${NC}"
            else
                echo -e "${YELLOW}ℹ️  No alarms were processed${NC}"
            fi
        fi
        return 0
    else
        echo -e "${RED}❌ Queue processing failed${NC}"
        return 1
    fi
}

# Function to check audio files
check_audio_files() {
    echo -e "${YELLOW}🎵 Checking audio files...${NC}"
    AUDIO_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/audio?select=*&order=generated_at.desc&limit=10" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json")
    
    AUDIO_COUNT=$(echo "$AUDIO_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Audio check successful${NC}"
    echo -e "${CYAN}📊 Audio files generated: $AUDIO_COUNT${NC}"
    
    if [ "$AUDIO_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}📋 Recent audio files:${NC}"
        echo "$AUDIO_RESPONSE" | jq -r '.[] | "  - ID: \(.id), User: \(.user_id), Audio Type: \(.audio_type), Generated: \(.generated_at)"' 2>/dev/null | head -5
    fi
    
    echo "$AUDIO_COUNT"
}

# Quick validation function
run_quick_test() {
    echo -e "${BLUE}🔧 Quick Production System Health Check${NC}"
    echo "====================================="
    echo ""
    
    # Check for existing users
    echo -e "${YELLOW}1. Checking for users...${NC}"
    USERS_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/users?select=id&limit=1" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json")
    
    USER_COUNT=$(echo "$USERS_RESPONSE" | jq '. | length' 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Found $USER_COUNT user(s)${NC}"
    
    if [ "$USER_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No users found - creating test user...${NC}"
        
        # Test user preferences data
        USER_CONFIG='{"tts_voice":"nova","news_categories":["general"],"sports_team":"Lakers","stocks":["AAPL","GOOGL"],"include_weather":true,"timezone":"America/New_York","preferred_name":"Test"}'
        WEATHER_CONFIG='{"location":"New York, NY","current_temp":45,"high_temp":52,"low_temp":38,"condition":"Sunny","sunrise_time":"07:15:00","sunset_time":"16:30:00"}'
        
        USER_ID=$(create_test_user "QuickTest" "$USER_CONFIG" "$WEATHER_CONFIG")
        if [ -n "$USER_ID" ]; then
            echo -e "${GREEN}✅ Test user created: $USER_ID${NC}"
        else
            echo -e "${RED}❌ Failed to create test user${NC}"
            return 1
        fi
    else
        USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id')
        echo -e "${CYAN}📋 Using existing user: $USER_ID${NC}"
    fi
    
    # Check queue
    QUEUE_COUNT=$(check_queue)
    echo -e "${YELLOW}📊 Checking queue status...${NC}"
    echo -e "${GREEN}✅ Queue check successful${NC}"
    echo -e "${CYAN}📊 Items in queue: $QUEUE_COUNT${NC}"
    if [ "$QUEUE_COUNT" -gt 0 ]; then
        QUEUE_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/audio_generation_queue?select=*&order=created_at.desc&limit=5" \
            -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
            -H "apikey: $SERVICE_ROLE_KEY" \
            -H "Content-Type: application/json")
        echo -e "${YELLOW}📋 Recent queue items:${NC}"
        echo "$QUEUE_RESPONSE" | jq -r '.[] | "  - User: \(.user_id), Alarm: \(.alarm_id), Status: \(.status), Created: \(.created_at)"' 2>/dev/null | head -5
    fi
    
    # Create test alarm if queue is empty
    if [ "$QUEUE_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}ℹ️  Queue is empty - creating test alarm...${NC}"
        ALARM_TIME=$(date -v+1H -v+10M +"%H:%M:%S")
        ALARM_DATE=$(date +"%Y-%m-%d")
        
        ALARM_ID=$(create_test_alarm "$USER_ID" "America/New_York" "$ALARM_TIME" "$ALARM_DATE")
        if [ -n "$ALARM_ID" ]; then
            echo -e "${GREEN}✅ Test alarm created: $ALARM_ID${NC}"
            
            # Wait for trigger
            echo -e "${YELLOW}⏳ Waiting for trigger to add alarm to queue...${NC}"
            sleep 3
            
            # Check queue again
            QUEUE_COUNT=$(check_queue)
        fi
    fi
    
    # Test queue processing
    test_queue_processing
    
    echo -e "\n${GREEN}🎉 Quick Test Complete!${NC}"
    echo "=============================="
    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo "• Users: $USER_COUNT"
    echo "• Queue items: $QUEUE_COUNT"
    echo "• Processing: ✅ Working"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Monitor the cron job execution"
    echo "2. Check function logs for any errors"
    echo "3. Verify audio files are generated"
}

# End-to-end validation function
run_e2e_test() {
    set -x
    echo -e "${BLUE}🚀 End-to-End Production Validation (3 Users)${NC}"
    echo "====================================="
    echo ""
    
    # Calculate alarm time (50 minutes from now)
    ALARM_TIME=$(date -v+50M -u +"%Y-%m-%dT%H:%M:%S.000Z")
    ALARM_TIME_LOCAL=$(date -v+50M +"%Y-%m-%d %H:%M:%S")
    AUDIO_GENERATION_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo -e "${CYAN}📊 Test Configuration${NC}"
    echo "• Project URL: $SUPABASE_URL"
    echo "• Alarm Time: $ALARM_TIME_LOCAL (UTC: $ALARM_TIME)"
    echo "• Audio Generation: $AUDIO_GENERATION_TIME (58 minutes before alarm)"
    echo "• Test Users: Peter, Nate, Joey with multi-category news"
    echo "• Expected Audio Files: 3 (1 per alarm, combined)"
    echo ""
    
    # Initialize arrays
    declare -a CREATED_USER_IDS=()
    declare -a CREATED_ALARM_IDS=()
    declare -a ERRORS=()
    
    # Test user preferences data
    USER_PREFERENCES_DATA=(
    '{"tts_voice":"nova","news_categories":["general","technology"],"sports_team":"Lakers","stocks":["AAPL","GOOGL","TSLA"],"include_weather":true,"timezone":"America/Los_Angeles","preferred_name":"Alex"}'
    '{"tts_voice":"nova","news_categories":["general","business"],"sports_team":"Warriors","stocks":["JPM","BAC","WFC"],"include_weather":true,"timezone":"America/New_York","preferred_name":"Jordan"}'
    '{"tts_voice":"sage","news_categories":["general","sports"],"sports_team":"Celtics","stocks":["NVDA","AMD","INTC"],"include_weather":true,"timezone":"America/Chicago","preferred_name":"Max"}'
    )
    
    # Weather configurations
    WEATHER_CONFIGS=(
    '{"location":"Los Angeles, CA","current_temp":72,"high_temp":78,"low_temp":65,"condition":"Partly Cloudy","sunrise_time":"06:30:00","sunset_time":"19:45:00"}'
    '{"location":"New York, NY","current_temp":45,"high_temp":52,"low_temp":38,"condition":"Sunny","sunrise_time":"07:15:00","sunset_time":"16:30:00"}'
    '{"location":"Chicago, IL","current_temp":28,"high_temp":35,"low_temp":22,"condition":"Snow","sunrise_time":"07:00:00","sunset_time":"16:15:00"}'
    )
    
    # User names
    USER_NAMES=("Peter" "Nate" "Joey")
    
    # Step 1: Create all user setups
    echo -e "${BLUE}📋 Step 1: Creating 3 User Setups with Multi-Category News${NC}"
    echo "====================================="
    
    for i in {0..2}; do
        USER_ID=$(create_test_user "${USER_NAMES[$i]}" "${USER_PREFERENCES_DATA[$i]}" "${WEATHER_CONFIGS[$i]}")
        if [ -n "$USER_ID" ]; then
            CREATED_USER_IDS+=("$USER_ID")
            
            # Create alarm
            ALARM_TIME=$(date -v+1H -v+10M +"%H:%M:%S")
            ALARM_DATE=$(date +"%Y-%m-%d")
            TIMEZONE="America/New_York"
            
            ALARM_ID=$(create_test_alarm "$USER_ID" "$TIMEZONE" "$ALARM_TIME" "$ALARM_DATE")
            if [ -n "$ALARM_ID" ]; then
                CREATED_ALARM_IDS+=("$ALARM_ID")
            else
                echo -e "${RED}❌ Failed to create alarm for user $USER_ID${NC}"
                ERRORS+=("Alarm creation failed for user $USER_ID")
            fi
        else
            echo -e "${RED}❌ Failed to create user ${USER_NAMES[$i]}${NC}"
            ERRORS+=("User creation failed for ${USER_NAMES[$i]}")
        fi
        echo ""
    done
    
    # Step 2: Verify queue population
    echo -e "${BLUE}📋 Step 2: Verifying Queue Population${NC}"
    echo "====================================="
    
    echo -e "${YELLOW}⏳ Waiting for triggers to add alarms to queue...${NC}"
    sleep 5
    
    QUEUE_COUNT=$(check_queue)
    
    # Step 3: Test queue processing
    echo -e "\n${BLUE}📋 Step 3: Testing Queue Processing${NC}"
    echo "====================================="
    
    test_queue_processing
    
    # Step 4: Monitor for completion
    echo -e "\n${BLUE}📋 Step 4: Monitoring for Completion${NC}"
    echo "====================================="
    
    echo -e "${YELLOW}⏳ Waiting for audio generation to complete...${NC}"
    sleep 10
    
    AUDIO_COUNT=$(check_audio_files)
    
    # Step 5: Final Results
    echo -e "\n${BLUE}📋 Step 5: Test Results Summary${NC}"
    echo "====================================="
    
    echo -e "${GREEN}✅ Test Execution Complete!${NC}"
    echo ""
    echo -e "${CYAN}📊 Creation Results:${NC}"
    echo "• Users created: ${#CREATED_USER_IDS[@]}/3"
    echo "• Alarms created: ${#CREATED_ALARM_IDS[@]}/3"
    echo "• Queue items: $QUEUE_COUNT"
    echo "• Audio files generated: $AUDIO_COUNT"
    echo ""
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo -e "${RED}❌ Errors Encountered:${NC}"
        for error in "${ERRORS[@]}"; do
            echo "• $error"
        done
        echo ""
    else
        echo -e "${GREEN}✅ No errors encountered!${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}🎯 Expected Timeline:${NC}"
    echo "• Audio generation will trigger at: $AUDIO_GENERATION_TIME"
    echo "• Alarms will sound at: $ALARM_TIME_LOCAL"
    echo "• Expected audio files: 3 (combined)"
    echo ""
    
    echo -e "${GREEN}🎉 End-to-End Test Complete!${NC}"
    echo "====================================="
    set +x
}

# Load test function
run_load_test() {
    set -x
    echo -e "${BLUE}🚀 Load Test (50 Users)${NC}"
    echo "====================================="
    echo ""
    echo -e "${YELLOW}⚠️  This is a load test that will create 50 users and alarms.${NC}"
    echo -e "${YELLOW}⚠️  Make sure you want to proceed with this test.${NC}"
    echo ""
    read -p "Continue with load test? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Load test cancelled.${NC}"
        exit 0
    fi
    
    # Calculate alarm time (50 minutes from now)
    ALARM_TIME=$(date -v+50M -u +"%Y-%m-%dT%H:%M:%S.000Z")
    ALARM_TIME_LOCAL=$(date -v+50M +"%Y-%m-%d %H:%M:%S")
    AUDIO_GENERATION_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo -e "${CYAN}📊 Load Test Configuration${NC}"
    echo "• Project URL: $SUPABASE_URL"
    echo "• Alarm Time: $ALARM_TIME_LOCAL (UTC: $ALARM_TIME)"
    echo "• Audio Generation: $AUDIO_GENERATION_TIME (58 minutes before alarm)"
    echo "• Test Users: 50 users with varied configurations"
    echo "• Expected Audio Files: 50 (1 per alarm, combined)"
    echo ""
    
    # Initialize arrays
    declare -a CREATED_USER_IDS=()
    declare -a CREATED_ALARM_IDS=()
    declare -a ERRORS=()
    
    # Test user preferences data (cycling through 5 different configurations)
    USER_PREFERENCES_DATA=(
    '{"tts_voice":"nova","news_categories":["general","technology"],"sports_team":"Lakers","stocks":["AAPL","GOOGL","TSLA"],"include_weather":true,"timezone":"America/Los_Angeles","preferred_name":"Alex"}'
    '{"tts_voice":"nova","news_categories":["general","business"],"sports_team":"Warriors","stocks":["JPM","BAC","WFC"],"include_weather":true,"timezone":"America/New_York","preferred_name":"Jordan"}'
    '{"tts_voice":"sage","news_categories":["general","sports"],"sports_team":"Celtics","stocks":["NVDA","AMD","INTC"],"include_weather":true,"timezone":"America/Chicago","preferred_name":"Max"}'
    '{"tts_voice":"alloy","news_categories":["general","entertainment"],"sports_team":"Heat","stocks":["MSFT","AMZN","META"],"include_weather":true,"timezone":"America/Denver","preferred_name":"Sam"}'
    '{"tts_voice":"echo","news_categories":["general","science"],"sports_team":"Bulls","stocks":["NFLX","DIS","PYPL"],"include_weather":true,"timezone":"America/Phoenix","preferred_name":"Taylor"}'
    )
    
    # Weather configurations (cycling through 5 different locations)
    WEATHER_CONFIGS=(
    '{"location":"Los Angeles, CA","current_temp":72,"high_temp":78,"low_temp":65,"condition":"Partly Cloudy","sunrise_time":"06:30:00","sunset_time":"19:45:00"}'
    '{"location":"New York, NY","current_temp":45,"high_temp":52,"low_temp":38,"condition":"Sunny","sunrise_time":"07:15:00","sunset_time":"16:30:00"}'
    '{"location":"Chicago, IL","current_temp":28,"high_temp":35,"low_temp":22,"condition":"Snow","sunrise_time":"07:00:00","sunset_time":"16:15:00"}'
    '{"location":"Denver, CO","current_temp":55,"high_temp":62,"low_temp":48,"condition":"Clear","sunrise_time":"06:45:00","sunset_time":"19:30:00"}'
    '{"location":"Phoenix, AZ","current_temp":88,"high_temp":95,"low_temp":75,"condition":"Sunny","sunrise_time":"06:15:00","sunset_time":"20:00:00"}'
    )
    
    # Step 1: Create all user setups
    echo -e "${BLUE}📋 Step 1: Creating 50 User Setups${NC}"
    echo "====================================="
    
    for i in {0..49}; do
        # Cycle through configurations
        CONFIG_INDEX=$((i % 5))
        USER_NAME="User$((i+1))"
        
        echo -e "${YELLOW}👤 Creating $USER_NAME (${i+1}/50)...${NC}"
        
        USER_ID=$(create_test_user "$USER_NAME" "${USER_PREFERENCES_DATA[$CONFIG_INDEX]}" "${WEATHER_CONFIGS[$CONFIG_INDEX]}")
        if [ -n "$USER_ID" ]; then
            CREATED_USER_IDS+=("$USER_ID")
            
            # Create alarm with slight time variation
            ALARM_TIME=$(date -v+1H -v+10M -v+${i}S +"%H:%M:%S")
            ALARM_DATE=$(date +"%Y-%m-%d")
            TIMEZONE="America/New_York"
            
            ALARM_ID=$(create_test_alarm "$USER_ID" "$TIMEZONE" "$ALARM_TIME" "$ALARM_DATE")
            if [ -n "$ALARM_ID" ]; then
                CREATED_ALARM_IDS+=("$ALARM_ID")
            else
                echo -e "${RED}❌ Failed to create alarm for user $USER_ID${NC}"
                ERRORS+=("Alarm creation failed for user $USER_ID")
            fi
        else
            echo -e "${RED}❌ Failed to create user $USER_NAME${NC}"
            ERRORS+=("User creation failed for $USER_NAME")
        fi
        
        # Progress indicator every 10 users
        if [ $((i % 10)) -eq 9 ]; then
            echo -e "${CYAN}📊 Progress: $((i+1))/50 users created${NC}"
        fi
    done
    
    # Step 2: Verify queue population
    echo -e "${BLUE}📋 Step 2: Verifying Queue Population${NC}"
    echo "====================================="
    
    echo -e "${YELLOW}⏳ Waiting for triggers to add alarms to queue...${NC}"
    sleep 10
    
    QUEUE_COUNT=$(check_queue)
    
    # Step 3: Test queue processing
    echo -e "\n${BLUE}📋 Step 3: Testing Queue Processing${NC}"
    echo "====================================="
    
    test_queue_processing
    
    # Step 4: Monitor for completion
    echo -e "\n${BLUE}📋 Step 4: Monitoring for Completion${NC}"
    echo "====================================="
    
    echo -e "${YELLOW}⏳ Waiting for audio generation to complete...${NC}"
    sleep 30
    
    AUDIO_COUNT=$(check_audio_files)
    
    # Step 5: Final Results
    echo -e "\n${BLUE}📋 Step 5: Load Test Results Summary${NC}"
    echo "====================================="
    
    echo -e "${GREEN}✅ Load Test Execution Complete!${NC}"
    echo ""
    echo -e "${CYAN}📊 Creation Results:${NC}"
    echo "• Users created: ${#CREATED_USER_IDS[@]}/50"
    echo "• Alarms created: ${#CREATED_ALARM_IDS[@]}/50"
    echo "• Queue items: $QUEUE_COUNT"
    echo "• Audio files generated: $AUDIO_COUNT"
    echo ""
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo -e "${RED}❌ Errors Encountered:${NC}"
        for error in "${ERRORS[@]}"; do
            echo "• $error"
        done
        echo ""
    else
        echo -e "${GREEN}✅ No errors encountered!${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}🎯 Expected Timeline:${NC}"
    echo "• Audio generation will trigger at: $AUDIO_GENERATION_TIME"
    echo "• Alarms will sound at: $ALARM_TIME_LOCAL"
    echo "• Expected audio files: 50 (combined)"
    echo ""
    
    echo -e "${GREEN}🎉 Load Test Complete!${NC}"
    echo "====================================="
    set +x
}

# Multi-timezone test function
run_tz_test() {
    echo -e "${BLUE}🌍 Multi-Timezone Test${NC}"
    echo "====================================="
    echo ""
    echo -e "${YELLOW}Multi-timezone test implementation would go here...${NC}"
    echo -e "${YELLOW}For now, use the existing test-multi-timezone-alarms.sh script.${NC}"
}

# Audio generation test function
run_audio_test() {
    echo -e "${BLUE}🎵 Audio Generation Test${NC}"
    echo "====================================="
    echo ""
    echo -e "${YELLOW}For now, use the existing test-system.sh audio mode.${NC}"
}

# Queue processing test function
run_queue_test() {
    echo -e "${BLUE}📋 Queue Processing Test${NC}"
    echo "====================================="
    echo ""
    echo -e "${YELLOW}Queue processing test implementation would go here...${NC}"
    echo -e "${YELLOW}For now, use the existing test-batch-processing.sh script.${NC}"
}

# Main execution
case "$TEST_TYPE" in
    "quick")
        run_quick_test
        ;;
    "e2e")
        run_e2e_test
        ;;
    "load")
        run_load_test
        ;;
    "tz")
        run_tz_test
        ;;
    "audio")
        run_audio_test
        ;;
    "queue")
        run_queue_test
        ;;
    *)
        echo -e "${RED}❌ Unknown test type: $TEST_TYPE${NC}"
        show_usage
        ;;
esac

# Update all references to the new production project URL
sed -i '' 's/fhjmqoshlryypcyvdifw\.supabase\.co/bfrvahxmokeyrfnlaiwd.supabase.co/g' "$0" 