#!/bin/bash

# OneAlarm Recent Audio Check Script
# Checks recent audio generation activity and status

set -e

# Source shared configuration
source ./scripts/config.sh

# Function to show usage
show_usage() {
    echo -e "${BLUE}🎵 OneAlarm Recent Audio Check${NC}"
    echo "====================================="
    echo ""
    echo "Usage: ./scripts/check-recent-audio.sh [SERVICE_ROLE_KEY] [HOURS]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/check-recent-audio.sh YOUR_SERVICE_ROLE_KEY"
    echo "  ./scripts/check-recent-audio.sh YOUR_SERVICE_ROLE_KEY 24"
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
HOURS="${2:-6}"  # Default to 6 hours if not specified

# Validate environment
if ! validate_environment; then
    exit 1
fi

echo -e "${BLUE}🎵 OneAlarm Recent Audio Check${NC}"
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

echo -e "${BLUE}📋 Step 1: Recent Audio Files (Last ${HOURS} hours)${NC}"
echo "====================================="

# Calculate timestamp for X hours ago
TIMESTAMP=$(date -u -d "${HOURS} hours ago" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -v-${HOURS}H +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || echo "")

if [ -n "$TIMESTAMP" ]; then
    AUDIO_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio?select=*&generated_at=gte.$TIMESTAMP&order=generated_at.desc")
else
    # Fallback: get last 50 audio files
    AUDIO_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio?select=*&order=generated_at.desc&limit=50")
fi

if echo "$AUDIO_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    AUDIO_COUNT=$(echo "$AUDIO_RESPONSE" | jq 'length')
    echo -e "${GREEN}✅ Found ${AUDIO_COUNT} audio files${NC}"
    
    if [ "$AUDIO_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}📋 Recent audio files:${NC}"
        echo "$AUDIO_RESPONSE" | jq -r '.[] | "• \(.clip_id): \(.audio_type) (\(.file_size) bytes) - \(.generated_at)"' 2>/dev/null || echo "  No audio files found"
        
        # Count by type
        COMBINED_COUNT=$(echo "$AUDIO_RESPONSE" | jq -r '[.[] | select(.audio_type == "combined")] | length' 2>/dev/null || echo "0")
        WEATHER_COUNT=$(echo "$AUDIO_RESPONSE" | jq -r '[.[] | select(.audio_type == "weather")] | length' 2>/dev/null || echo "0")
        CONTENT_COUNT=$(echo "$AUDIO_RESPONSE" | jq -r '[.[] | select(.audio_type == "content")] | length' 2>/dev/null || echo "0")
        
        echo -e "${CYAN}📊 Audio type breakdown:${NC}"
        echo "• Combined: $COMBINED_COUNT"
        echo "• Weather: $WEATHER_COUNT"
        echo "• Content: $CONTENT_COUNT"
    fi
else
    echo -e "${YELLOW}⚠️  No recent audio files found${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 2: Recent Queue Activity${NC}"
echo "====================================="

# Check recent queue activity
if [ -n "$TIMESTAMP" ]; then
    QUEUE_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=*&created_at=gte.$TIMESTAMP&order=created_at.desc")
else
    QUEUE_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=*&order=created_at.desc&limit=50")
fi

if echo "$QUEUE_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    QUEUE_COUNT=$(echo "$QUEUE_RESPONSE" | jq 'length')
    echo -e "${GREEN}✅ Found ${QUEUE_COUNT} queue items${NC}"
    
    if [ "$QUEUE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}📋 Recent queue items:${NC}"
        echo "$QUEUE_RESPONSE" | jq -r '.[] | "• \(.alarm_id): \(.status) (scheduled: \(.scheduled_for))"' 2>/dev/null || echo "  No queue items found"
        
        # Count by status
        PENDING_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "pending")] | length' 2>/dev/null || echo "0")
        PROCESSING_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "processing")] | length' 2>/dev/null || echo "0")
        COMPLETED_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "completed")] | length' 2>/dev/null || echo "0")
        FAILED_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "failed")] | length' 2>/dev/null || echo "0")
        
        echo -e "${CYAN}📊 Queue status breakdown:${NC}"
        echo "• Pending: $PENDING_COUNT"
        echo "• Processing: $PROCESSING_COUNT"
        echo "• Completed: $COMPLETED_COUNT"
        echo "• Failed: $FAILED_COUNT"
    fi
else
    echo -e "${YELLOW}⚠️  No recent queue activity found${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 3: Recent System Logs${NC}"
echo "====================================="

# Check recent system logs
if [ -n "$TIMESTAMP" ]; then
    LOGS_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/logs?select=*&created_at=gte.$TIMESTAMP&order=created_at.desc")
else
    LOGS_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/logs?select=*&order=created_at.desc&limit=50")
fi

if echo "$LOGS_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    LOGS_COUNT=$(echo "$LOGS_RESPONSE" | jq 'length')
    echo -e "${GREEN}✅ Found ${LOGS_COUNT} system logs${NC}"
    
    if [ "$LOGS_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}📋 Recent system events:${NC}"
        echo "$LOGS_RESPONSE" | jq -r '.[] | "• \(.event_type) - \(.created_at)"' 2>/dev/null || echo "  No logs found"
        
        # Count by event type
        AUDIO_GENERATION_COUNT=$(echo "$LOGS_RESPONSE" | jq -r '[.[] | select(.event_type | contains("audio_generation"))] | length' 2>/dev/null || echo "0")
        QUEUE_PROCESSING_COUNT=$(echo "$LOGS_RESPONSE" | jq -r '[.[] | select(.event_type | contains("queue"))] | length' 2>/dev/null || echo "0")
        ERROR_COUNT=$(echo "$LOGS_RESPONSE" | jq -r '[.[] | select(.event_type | contains("error"))] | length' 2>/dev/null || echo "0")
        
        echo -e "${CYAN}📊 Event type breakdown:${NC}"
        echo "• Audio Generation: $AUDIO_GENERATION_COUNT"
        echo "• Queue Processing: $QUEUE_PROCESSING_COUNT"
        echo "• Errors: $ERROR_COUNT"
    fi
else
    echo -e "${YELLOW}⚠️  No recent system logs found${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 4: Summary${NC}"
echo "====================================="

# Overall summary
echo -e "${CYAN}📊 Activity Summary (Last ${HOURS} hours)${NC}"
echo "• Audio Files Generated: $AUDIO_COUNT"
echo "• Queue Items Processed: $QUEUE_COUNT"
echo "• System Events Logged: $LOGS_COUNT"

# Success rate calculation
if [ "$QUEUE_COUNT" -gt 0 ]; then
    SUCCESS_RATE=$(echo "scale=1; $COMPLETED_COUNT * 100 / $QUEUE_COUNT" | bc 2>/dev/null || echo "0")
    echo "• Success Rate: ${SUCCESS_RATE}%"
fi

if [ "$FAILED_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Warning: ${FAILED_COUNT} failed queue items detected${NC}"
fi

echo ""
echo -e "${GREEN}✅ Recent audio check completed${NC}" 