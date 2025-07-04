#!/bin/bash

# Test production audio trigger
# This script updates a user preference to trigger audio generation

set -e

# Source shared configuration
source ./scripts/config.sh

# Function to show usage
show_usage() {
    echo -e "${BLUE}🧪 Test Production Audio Trigger${NC}"
    echo "====================================="
    echo ""
    echo "Usage: ./scripts/test-prod-audio-trigger.sh [SERVICE_ROLE_KEY] [USER_ID]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/test-prod-audio-trigger.sh YOUR_SERVICE_ROLE_KEY 123e4567-e89b-12d3-a456-426614174000"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to https://bfrvahxmokeyrfnlaiwd.supabase.co/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
}

# Check if required parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    show_usage
fi

SERVICE_ROLE_KEY="$1"
USER_ID="$2"

# Override for production
SUPABASE_URL="https://bfrvahxmokeyrfnlaiwd.supabase.co"

echo -e "${BLUE}🧪 Test Production Audio Trigger${NC}"
echo "====================================="
echo ""

echo -e "${YELLOW}🔍 Step 1: Check current user preferences...${NC}"
PREFERENCES_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/user_preferences?user_id=eq.$USER_ID&select=*" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY")

if echo "$PREFERENCES_RESPONSE" | jq -e '.' >/dev/null 2>&1; then
    CURRENT_PREFERENCES=$(echo "$PREFERENCES_RESPONSE" | jq '.[0]')
    echo -e "${GREEN}✅ Found user preferences:${NC}"
    echo "$CURRENT_PREFERENCES" | jq '.'
else
    echo -e "${RED}❌ User preferences not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔍 Step 2: Update tts_voice to trigger audio generation...${NC}"

# Get current tts_voice
CURRENT_VOICE=$(echo "$CURRENT_PREFERENCES" | jq -r '.tts_voice')
NEW_VOICE="alloy"  # Set to default to trigger change

if [ "$CURRENT_VOICE" = "$NEW_VOICE" ]; then
    NEW_VOICE="echo"  # Use different voice to ensure change
fi

echo -e "Current voice: ${CYAN}$CURRENT_VOICE${NC}"
echo -e "New voice: ${CYAN}$NEW_VOICE${NC}"

# Update the preference
UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$SUPABASE_URL/rest/v1/user_preferences?user_id=eq.$USER_ID" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -d "{\"tts_voice\": \"$NEW_VOICE\"}")

HTTP_CODE=$(echo "$UPDATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Preference updated successfully${NC}"
else
    echo -e "${RED}❌ Failed to update preference (HTTP $HTTP_CODE)${NC}"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

echo ""
echo -e "${YELLOW}🔍 Step 3: Check for trigger logs...${NC}"

# Wait a moment for the trigger to fire
sleep 2

# Check for trigger logs
TRIGGER_LOGS=$(curl -s -X GET "$SUPABASE_URL/rest/v1/logs?event_type=eq.preferences_updated_audio_trigger&user_id=eq.$USER_ID&order=created_at.desc&limit=1" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY")

if echo "$TRIGGER_LOGS" | jq -e '.' >/dev/null 2>&1 && [ "$(echo "$TRIGGER_LOGS" | jq 'length')" -gt 0 ]; then
    echo -e "${GREEN}✅ Trigger fired successfully!${NC}"
    echo "Trigger log:"
    echo "$TRIGGER_LOGS" | jq '.[0]'
else
    echo -e "${RED}❌ No trigger logs found${NC}"
    echo "This indicates the trigger may not be working"
fi

echo ""
echo -e "${YELLOW}🔍 Step 4: Check for audio generation...${NC}"

# Wait a bit longer for audio generation
sleep 3

# Check for recent audio files
AUDIO_FILES=$(curl -s -X GET "$SUPABASE_URL/rest/v1/audio?user_id=eq.$USER_ID&order=created_at.desc&limit=5" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY")

if echo "$AUDIO_FILES" | jq -e '.' >/dev/null 2>&1 && [ "$(echo "$AUDIO_FILES" | jq 'length')" -gt 0 ]; then
    echo -e "${GREEN}✅ Audio files found!${NC}"
    echo "Recent audio files:"
    echo "$AUDIO_FILES" | jq '.[] | "• \(.audio_type): \(.status) - \(.created_at)"'
else
    echo -e "${YELLOW}⚠️  No recent audio files found${NC}"
    echo "Audio generation may still be in progress or failed"
fi

echo ""
echo -e "${GREEN}✅ Test completed!${NC}" 