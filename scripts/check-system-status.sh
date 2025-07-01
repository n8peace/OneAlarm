#!/bin/bash

# OneAlarm System Status Check Script
# Comprehensive system health check and monitoring

set -e

# Source shared configuration
source ./scripts/config.sh

# Function to show usage
show_usage() {
    echo -e "${BLUE}🔍 OneAlarm System Status Check${NC}"
    echo "====================================="
    echo ""
    echo "Usage: ./scripts/check-system-status.sh [SERVICE_ROLE_KEY]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/check-system-status.sh YOUR_SERVICE_ROLE_KEY"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to ${SUPABASE_URL}/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
}

# Check if service role key is provided
if [ -z "$1" ]; then
    show_usage
fi

SERVICE_ROLE_KEY="$1"

# Validate environment
if ! validate_environment; then
    exit 1
fi

echo -e "${BLUE}🔍 OneAlarm System Status Check${NC}"
echo "====================================="
echo ""

# Function to make API calls
make_api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
            -H "apikey: $SERVICE_ROLE_KEY" \
            -d "$data"
    else
        curl -s -X "$method" "$endpoint" \
            -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
            -H "apikey: $SERVICE_ROLE_KEY"
    fi
}

echo -e "${BLUE}📋 Step 1: Function Health Check${NC}"
echo "====================================="

# Check generate-alarm-audio function
echo -e "${YELLOW}🔧 Checking generate-alarm-audio function...${NC}"
FUNCTION_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/functions/v1/generate-alarm-audio")

if echo "$FUNCTION_RESPONSE" | grep -q "OneAlarm"; then
    echo -e "${GREEN}✅ Function is healthy${NC}"
else
    echo -e "${RED}❌ Function health check failed${NC}"
    echo "Response: $FUNCTION_RESPONSE"
fi

echo ""

echo -e "${BLUE}📋 Step 2: Database Connectivity${NC}"
echo "====================================="

# Check users table
echo -e "${YELLOW}👥 Checking users table...${NC}"
USERS_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/users?select=count")

if echo "$USERS_RESPONSE" | grep -q "count"; then
    USER_COUNT=$(echo "$USERS_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}✅ Users table accessible (${USER_COUNT} users)${NC}"
else
    echo -e "${RED}❌ Users table access failed${NC}"
    echo "Response: $USERS_RESPONSE"
fi

# Check alarms table
echo -e "${YELLOW}⏰ Checking alarms table...${NC}"
ALARMS_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/alarms?select=count")

if echo "$ALARMS_RESPONSE" | grep -q "count"; then
    ALARM_COUNT=$(echo "$ALARMS_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}✅ Alarms table accessible (${ALARM_COUNT} alarms)${NC}"
else
    echo -e "${RED}❌ Alarms table access failed${NC}"
    echo "Response: $ALARMS_RESPONSE"
fi

# Check audio_generation_queue table
echo -e "${YELLOW}🎵 Checking audio generation queue...${NC}"
QUEUE_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=count")

if echo "$QUEUE_RESPONSE" | grep -q "count"; then
    QUEUE_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}✅ Queue table accessible (${QUEUE_COUNT} items)${NC}"
else
    echo -e "${RED}❌ Queue table access failed${NC}"
    echo "Response: $QUEUE_RESPONSE"
fi

echo ""

echo -e "${BLUE}📋 Step 3: Queue Status${NC}"
echo "====================================="

# Get queue items by status
if [ "$QUEUE_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}📊 Queue items by status:${NC}"
    
    # Count by status
    PENDING_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=count&status=eq.pending")
    PROCESSING_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=count&status=eq.processing")
    COMPLETED_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=count&status=eq.completed")
    FAILED_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=count&status=eq.failed")
    
    PENDING_COUNT=$(echo "$PENDING_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "0")
    PROCESSING_COUNT=$(echo "$PROCESSING_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "0")
    COMPLETED_COUNT=$(echo "$COMPLETED_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "0")
    FAILED_COUNT=$(echo "$FAILED_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "0")
    
    echo -e "  • Pending: ${CYAN}$PENDING_COUNT${NC}"
    echo -e "  • Processing: ${YELLOW}$PROCESSING_COUNT${NC}"
    echo -e "  • Completed: ${GREEN}$COMPLETED_COUNT${NC}"
    echo -e "  • Failed: ${RED}$FAILED_COUNT${NC}"
    
    # Show recent queue items
    echo -e "${YELLOW}📋 Recent queue items:${NC}"
    RECENT_QUEUE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=alarm_id,status,scheduled_for&order=created_at.desc&limit=5")
    
    if echo "$RECENT_QUEUE" | jq -e '.' >/dev/null 2>&1; then
        echo "$RECENT_QUEUE" | jq -r '.[] | "  • \(.alarm_id): \(.status) (scheduled: \(.scheduled_for))"' 2>/dev/null || echo "  No recent items found"
    else
        echo "  Unable to fetch recent items"
    fi
else
    echo -e "${GREEN}✅ Queue is empty${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 4: Recent Audio Files${NC}"
echo "====================================="

# Check recent audio files
AUDIO_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio?select=clip_id,audio_type,file_size,generated_at&order=generated_at.desc&limit=5")

if echo "$AUDIO_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    AUDIO_COUNT=$(echo "$AUDIO_RESPONSE" | jq 'length')
    echo -e "${GREEN}✅ Recent audio files found (${AUDIO_COUNT} files)${NC}"
    
    echo -e "${YELLOW}📋 Recent audio files:${NC}"
    echo "$AUDIO_RESPONSE" | jq -r '.[] | "  • \(.clip_id): \(.audio_type) (\(.file_size) bytes) - \(.generated_at)"' 2>/dev/null || echo "  No audio files found"
else
    echo -e "${YELLOW}⚠️  No recent audio files found${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 5: System Logs${NC}"
echo "====================================="

# Check recent system logs
LOGS_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/logs?select=event_type,created_at&order=created_at.desc&limit=5")

if echo "$LOGS_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    LOGS_COUNT=$(echo "$LOGS_RESPONSE" | jq 'length')
    echo -e "${GREEN}✅ Recent system logs found (${LOGS_COUNT} logs)${NC}"
    
    echo -e "${YELLOW}📋 Recent system events:${NC}"
    echo "$LOGS_RESPONSE" | jq -r '.[] | "  • \(.event_type) - \(.created_at)"' 2>/dev/null || echo "  No logs found"
else
    echo -e "${YELLOW}⚠️  No recent system logs found${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 6: Daily Content Status${NC}"
echo "====================================="

# Check daily content
CONTENT_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/daily_content?select=content_date,general_content,business_content,technology_content,sports_content&order=content_date.desc&limit=1")

if echo "$CONTENT_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    CONTENT_COUNT=$(echo "$CONTENT_RESPONSE" | jq 'length')
    if [ "$CONTENT_COUNT" -gt 0 ]; then
        LATEST_DATE=$(echo "$CONTENT_RESPONSE" | jq -r '.[0].content_date' 2>/dev/null || echo "Unknown")
        echo -e "${GREEN}✅ Daily content available (latest: ${LATEST_DATE})${NC}"
        
        # Check content completeness
        GENERAL_LENGTH=$(echo "$CONTENT_RESPONSE" | jq -r '.[0].general_content | length' 2>/dev/null || echo "0")
        BUSINESS_LENGTH=$(echo "$CONTENT_RESPONSE" | jq -r '.[0].business_content | length' 2>/dev/null || echo "0")
        TECH_LENGTH=$(echo "$CONTENT_RESPONSE" | jq -r '.[0].technology_content | length' 2>/dev/null || echo "0")
        SPORTS_LENGTH=$(echo "$CONTENT_RESPONSE" | jq -r '.[0].sports_content | length' 2>/dev/null || echo "0")
        
        echo -e "${YELLOW}📋 Content categories:${NC}"
        echo -e "  • General: ${CYAN}${GENERAL_LENGTH} items${NC}"
        echo -e "  • Business: ${CYAN}${BUSINESS_LENGTH} items${NC}"
        echo -e "  • Technology: ${CYAN}${TECH_LENGTH} items${NC}"
        echo -e "  • Sports: ${CYAN}${SPORTS_LENGTH} items${NC}"
    else
        echo -e "${YELLOW}⚠️  No daily content found${NC}"
    fi
else
    echo -e "${RED}❌ Daily content access failed${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 7: System Summary${NC}"
echo "====================================="

# Overall system status
echo -e "${CYAN}📊 System Overview${NC}"
echo "• Project URL: $SUPABASE_URL"
echo "• Users: $USER_COUNT"
echo "• Alarms: $ALARM_COUNT"
echo "• Queue Items: $QUEUE_COUNT"
echo "• Recent Audio Files: $AUDIO_COUNT"
echo "• Recent Logs: $LOGS_COUNT"

echo ""
echo -e "${CYAN}🔗 Dashboard Links${NC}"
echo "• Supabase Dashboard: https://supabase.com/dashboard/project/$(echo $SUPABASE_URL | sed 's|https://||' | sed 's|.supabase.co||')"
echo "• Supabase Functions: https://supabase.com/dashboard/project/$(echo $SUPABASE_URL | sed 's|https://||' | sed 's|.supabase.co||')/functions"
echo "• Supabase Database: https://supabase.com/dashboard/project/$(echo $SUPABASE_URL | sed 's|https://||' | sed 's|.supabase.co||')/editor"
echo "• Supabase Storage: https://supabase.com/dashboard/project/$(echo $SUPABASE_URL | sed 's|https://||' | sed 's|.supabase.co||')/storage"

echo ""
echo -e "${GREEN}✅ System status check completed${NC}" 