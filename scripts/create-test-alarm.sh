#!/bin/bash

# Test Alarm Creation Script
# Creates test alarms for testing audio generation

set -e

# Source shared configuration
source ./scripts/config.sh

echo -e "${BLUE}⏰ OneAlarm Test Alarm Creation${NC}"
echo "====================================="
echo ""

# Check if service role key is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo ""
    echo "Usage: ./scripts/create-test-alarm.sh YOUR_SERVICE_ROLE_KEY [USER_ID]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/create-test-alarm.sh YOUR_KEY                    # Create alarm for first available user"
    echo "  ./scripts/create-test-alarm.sh YOUR_KEY USER_UUID          # Create alarm for specific user"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to ${SUPABASE_URL}/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
fi

SERVICE_ROLE_KEY="$1"
TARGET_USER_ID="$2"

echo -e "${CYAN}📋 Project:${NC} $SUPABASE_URL"
echo ""

# Function to get first available user
get_first_user() {
    echo -e "${YELLOW}🔍 Finding first available user...${NC}"
    
    USER_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/users?select=id,email&limit=1" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json")
    
    if echo "$USER_RESPONSE" | jq -e '.[0].id' >/dev/null 2>&1; then
        USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')
        USER_EMAIL=$(echo "$USER_RESPONSE" | jq -r '.[0].email')
        echo -e "${GREEN}✅ Found user: $USER_EMAIL ($USER_ID)${NC}"
        echo "$USER_ID"
    else
        echo -e "${RED}❌ No users found. Please create a test user first:${NC}"
        echo "  ./scripts/create-test-user.sh $SERVICE_ROLE_KEY"
        exit 1
    fi
}

# Function to create test alarm
create_test_alarm() {
    local user_id="$1"
    local alarm_time="$2"
    local timezone="$3"
    local alarm_date="$4"
    
    echo -e "${YELLOW}⏰ Creating alarm for $alarm_time $timezone on $alarm_date...${NC}"
    
    ALARM_DATA=$(cat <<EOF
{
    "user_id": "$user_id",
    "alarm_date": "$alarm_date",
    "alarm_time_local": "$alarm_time",
    "alarm_timezone": "$timezone",
    "active": true
}
EOF
)
    
    ALARM_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/alarms" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$ALARM_DATA")
    
    if echo "$ALARM_RESPONSE" | jq -e '.[0].id' >/dev/null 2>&1; then
        ALARM_ID=$(echo "$ALARM_RESPONSE" | jq -r '.[0].id')
        echo -e "${GREEN}✅ Alarm created: $ALARM_ID${NC}"
        echo "$ALARM_ID"
    else
        echo -e "${RED}❌ Alarm creation failed: $ALARM_RESPONSE${NC}"
        return 1
    fi
}

# Determine user ID
if [ -n "$TARGET_USER_ID" ]; then
    USER_ID="$TARGET_USER_ID"
    echo -e "${CYAN}👤 Using specified user: $USER_ID${NC}"
else
    USER_ID=$(get_first_user)
fi

echo ""

# Calculate tomorrow's date
TOMORROW=$(date -d "tomorrow" +"%Y-%m-%d" 2>/dev/null || date -v+1d +"%Y-%m-%d" 2>/dev/null || echo "")

if [ -z "$TOMORROW" ]; then
    echo -e "${RED}❌ Error: Could not calculate tomorrow's date${NC}"
    exit 1
fi

echo -e "${CYAN}📅 Creating alarms for: $TOMORROW${NC}"
echo ""

# Create multiple test alarms with different times
ALARM_TIMES=("07:00" "07:30" "08:00" "08:30" "09:00")
TIMEZONES=("America/New_York" "America/Los_Angeles" "America/Chicago" "America/Denver" "America/Phoenix")

CREATED_ALARMS=()

for i in "${!ALARM_TIMES[@]}"; do
    alarm_time="${ALARM_TIMES[$i]}"
    timezone="${TIMEZONES[$i]}"
    
    alarm_id=$(create_test_alarm "$USER_ID" "$alarm_time" "$timezone" "$TOMORROW")
    
    if [ $? -eq 0 ]; then
        CREATED_ALARMS+=("$alarm_id")
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}📋 Creation Summary${NC}"
echo "=================="
echo -e "${GREEN}✅ Successfully created ${#CREATED_ALARMS[@]} test alarm(s)${NC}"
echo ""

if [ ${#CREATED_ALARMS[@]} -gt 0 ]; then
    echo -e "${CYAN}⏰ Created Alarm IDs:${NC}"
    for alarm_id in "${CREATED_ALARMS[@]}"; do
        echo "  - $alarm_id"
    done
    echo ""
    
    echo -e "${YELLOW}🧪 Test Scenarios Created:${NC}"
    echo "  - Multiple time zones (EST, PST, CST, MST, MST)"
    echo "  - Different wake-up times (7:00 AM - 9:00 AM)"
    echo "  - All alarms scheduled for tomorrow"
    echo ""
    
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "1. Wait for audio generation (58 minutes before each alarm):"
    for i in "${!ALARM_TIMES[@]}"; do
        alarm_time="${ALARM_TIMES[$i]}"
        timezone="${TIMEZONES[$i]}"
        echo "   - $alarm_time $timezone → Audio generated at $(date -d "tomorrow $alarm_time - 58 minutes" +"%H:%M" 2>/dev/null || echo "calculated time")"
    done
    echo ""
    echo "2. Monitor queue processing:"
    echo "   ./scripts/monitor-system.sh $SERVICE_ROLE_KEY"
    echo ""
    echo "3. Check recent audio files:"
    echo "   ./scripts/check-recent-audio.sh $SERVICE_ROLE_KEY"
    echo ""
    echo "4. Run system tests:"
    echo "   ./scripts/test-system.sh e2e $SERVICE_ROLE_KEY"
fi 