#!/bin/bash

# OneAlarm System Monitoring Script
# Monitors queue, audio files, and system health
# Updated with recent fixes and improvements

set -e

# Source shared configuration
source ./scripts/config.sh

# Configuration
SERVICE_ROLE_KEY="${1:-$SUPABASE_SERVICE_ROLE_KEY}"

if [ -z "$SERVICE_ROLE_KEY" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo "Usage: $0 YOUR_SERVICE_ROLE_KEY"
    echo "Or set SUPABASE_SERVICE_ROLE_KEY environment variable"
    exit 1
fi

echo -e "${BLUE}📊 OneAlarm System Monitor${NC}"
echo "====================================="
echo -e "${BLUE}📊 Configuration:${NC}"
echo "• Project URL: $SUPABASE_URL"
echo "• Monitoring: Queue, audio files, system health"
echo "• Recent fixes: ON CONFLICT removal, success determination logic"
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

echo -e "${BLUE}📋 Step 1: Queue Status${NC}"
echo "====================================="

# Check queue status
QUEUE_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio_generation_queue?select=*&order=created_at.desc&limit=10")

echo -e "${YELLOW}📊 Recent Queue Items:${NC}"
echo "$QUEUE_RESPONSE" | jq -r '.[] | "• \(.alarm_id): \(.status) (scheduled: \(.scheduled_for))"' 2>/dev/null || echo "No queue items found"

# Count by status
PENDING_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "pending")] | length' 2>/dev/null || echo "0")
PROCESSING_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "processing")] | length' 2>/dev/null || echo "0")
COMPLETED_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "completed")] | length' 2>/dev/null || echo "0")
FAILED_COUNT=$(echo "$QUEUE_RESPONSE" | jq -r '[.[] | select(.status == "failed")] | length' 2>/dev/null || echo "0")

echo -e "${CYAN}📊 Queue Summary:${NC}"
echo "• Pending: $PENDING_COUNT"
echo "• Processing: $PROCESSING_COUNT"
echo "• Completed: $COMPLETED_COUNT"
echo "• Failed: $FAILED_COUNT"

echo ""

echo -e "${BLUE}📋 Step 2: Audio Files Status${NC}"
echo "====================================="

# Check recent audio files
AUDIO_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/audio?select=*&order=generated_at.desc&limit=10")

echo -e "${YELLOW}📊 Recent Audio Files:${NC}"
echo "$AUDIO_RESPONSE" | jq -r '.[] | "• \(.clip_id): \(.audio_type) (\(.file_size) bytes) - \(.generated_at)"' 2>/dev/null || echo "No audio files found"

# Count by type
COMBINED_COUNT=$(echo "$AUDIO_RESPONSE" | jq -r '[.[] | select(.audio_type == "combined")] | length' 2>/dev/null || echo "0")
WEATHER_COUNT=$(echo "$AUDIO_RESPONSE" | jq -r '[.[] | select(.audio_type == "weather")] | length' 2>/dev/null || echo "0")
CONTENT_COUNT=$(echo "$AUDIO_RESPONSE" | jq -r '[.[] | select(.audio_type == "content")] | length' 2>/dev/null || echo "0")

echo -e "${CYAN}📊 Audio Summary:${NC}"
echo "• Combined: $COMBINED_COUNT"
echo "• Weather: $WEATHER_COUNT"
echo "• Content: $CONTENT_COUNT"

echo ""

echo -e "${BLUE}📋 Step 3: System Health${NC}"
echo "====================================="

# Check function health
FUNCTION_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/functions/v1/generate-alarm-audio")

if echo "$FUNCTION_RESPONSE" | grep -q "OneAlarm"; then
    echo -e "${GREEN}✅ Function is healthy${NC}"
else
    echo -e "${RED}❌ Function health check failed${NC}"
    echo "Response: $FUNCTION_RESPONSE"
fi

# Check database connectivity
DB_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/users?select=count")

if echo "$DB_RESPONSE" | grep -q "count"; then
    USER_COUNT=$(echo "$DB_RESPONSE" | jq -r '.[0].count' 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}✅ Database accessible (${USER_COUNT} users)${NC}"
else
    echo -e "${RED}❌ Database access failed${NC}"
fi

echo ""

echo -e "${BLUE}📋 Step 4: Recent Activity${NC}"
echo "====================================="

# Check recent logs
LOGS_RESPONSE=$(make_api_call "GET" "$SUPABASE_URL/rest/v1/logs?select=event_type,created_at&order=created_at.desc&limit=5")

echo -e "${YELLOW}📊 Recent System Events:${NC}"
echo "$LOGS_RESPONSE" | jq -r '.[] | "• \(.event_type) - \(.created_at)"' 2>/dev/null || echo "No recent events found"

echo ""

echo -e "${GREEN}✅ System monitoring completed${NC}" 