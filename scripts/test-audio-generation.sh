#!/bin/bash

# Test script for audio generation function in develop environment
# This script will help troubleshoot why audio generation is not working

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

echo -e "${BLUE}🔍 Audio Generation Function Troubleshooting${NC}"
echo "=================================================="
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

# 1. Test function health check
print_status "info" "Testing function health check..."
HEALTH_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/functions/v1/generate-alarm-audio" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$HEALTH_RESPONSE" | grep -q "generate-alarm-audio"; then
    print_status "success" "Function health check passed"
else
    print_status "error" "Function health check failed"
    echo "Response: $HEALTH_RESPONSE"
fi
echo

# 2. Test queue processing (no alarmId)
print_status "info" "Testing queue processing..."
QUEUE_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/functions/v1/generate-alarm-audio" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "Queue processing response:"
echo "$QUEUE_RESPONSE" | jq '.' 2>/dev/null || echo "$QUEUE_RESPONSE"
echo

# 3. Check current queue status
print_status "info" "Checking current queue status..."
QUEUE_STATUS=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/audio_generation_queue" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: count=exact" \
  -d '{"select": "alarm_id,user_id,status,scheduled_for,created_at"}' | jq '.' 2>/dev/null || echo "Failed to get queue status")

echo "Current queue items:"
echo "$QUEUE_STATUS"
echo

# 4. Check if there are any pending items
PENDING_COUNT=$(echo "$QUEUE_STATUS" | jq -r '.[] | select(.status == "pending") | .alarm_id' 2>/dev/null | wc -l)
print_status "info" "Found $PENDING_COUNT pending queue items"

if [ "$PENDING_COUNT" -gt 0 ]; then
    print_status "info" "Testing manual processing of pending items..."
    
    # Get the first pending alarm ID
    FIRST_PENDING_ALARM=$(echo "$QUEUE_STATUS" | jq -r '.[] | select(.status == "pending") | .alarm_id' 2>/dev/null | head -1)
    
    if [ -n "$FIRST_PENDING_ALARM" ] && [ "$FIRST_PENDING_ALARM" != "null" ]; then
        print_status "info" "Testing specific alarm processing for: $FIRST_PENDING_ALARM"
        
        ALARM_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/functions/v1/generate-alarm-audio" \
          -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
          -H "Content-Type: application/json" \
          -d "{\"alarmId\": \"$FIRST_PENDING_ALARM\"}")
        
        echo "Specific alarm processing response:"
        echo "$ALARM_RESPONSE" | jq '.' 2>/dev/null || echo "$ALARM_RESPONSE"
    else
        print_status "warning" "No valid pending alarm ID found"
    fi
fi
echo

# 5. Check recent logs
print_status "info" "Checking recent function logs..."
RECENT_LOGS=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/logs" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: count=exact" \
  -d '{"select": "event_type,user_id,meta,created_at", "order": "created_at.desc", "limit": 10}' | jq '.' 2>/dev/null || echo "Failed to get logs")

echo "Recent logs:"
echo "$RECENT_LOGS"
echo

# 6. Check audio table
print_status "info" "Checking audio table..."
AUDIO_COUNT=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/audio" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: count=exact" \
  -d '{"select": "id,alarm_id,audio_type,status,created_at"}' | jq -r 'length' 2>/dev/null || echo "0")

print_status "info" "Total audio files in database: $AUDIO_COUNT"

# 7. Summary and recommendations
echo
echo -e "${BLUE}📋 Troubleshooting Summary${NC}"
echo "=============================="

if echo "$QUEUE_RESPONSE" | grep -q '"success":true'; then
    print_status "success" "Function endpoint is responding correctly"
else
    print_status "error" "Function endpoint may have issues"
fi

if [ "$PENDING_COUNT" -gt 0 ]; then
    print_status "warning" "There are $PENDING_COUNT pending queue items that need processing"
else
    print_status "success" "No pending queue items found"
fi

if [ "$AUDIO_COUNT" -eq 0 ]; then
    print_status "warning" "No audio files have been generated yet"
else
    print_status "success" "Audio files exist in the database"
fi

echo
echo -e "${BLUE}🔧 Next Steps${NC}"
echo "============="
echo "1. Check Supabase dashboard for environment variables:"
echo "   - SUPABASE_URL"
echo "   - SUPABASE_SERVICE_ROLE_KEY" 
echo "   - OPENAI_API_KEY"
echo
echo "2. Verify cron job is active in Supabase dashboard"
echo
echo "3. Check function logs in Supabase dashboard for errors"
echo
echo "4. Test manual function invocation with specific alarm IDs"
echo
echo "5. Compare environment variables with working main environment" 