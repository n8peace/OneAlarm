#!/bin/bash

# Apply fix for manage_alarm_audio_queue function in develop environment
# This removes the reference to the non-existent updated_at column

set -e

# Source shared configuration
source ./scripts/config.sh

# Develop environment variables
SUPABASE_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔧 Applying fix for manage_alarm_audio_queue function in develop${NC}"
echo "====================================="
echo ""

# Read the SQL fix
SQL_FIX=$(cat scripts/fix-develop-manage-alarm-audio-queue.sql)

echo -e "${YELLOW}📋 Applying SQL fix...${NC}"

# Apply the fix using the REST API
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": $(echo "$SQL_FIX" | jq -R -s .)}")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Fix applied successfully!${NC}"
    echo ""
    echo -e "${BLUE}🔍 Testing the fix...${NC}"
    
    # Run the test again to see if it works
    ./scripts/test-system-develop.sh e2e "$SERVICE_ROLE_KEY"
else
    echo -e "${RED}❌ Failed to apply fix${NC}"
    echo "HTTP Status: $HTTP_STATUS"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi 