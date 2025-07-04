#!/bin/bash

# Simple RLS policy comparison by testing operations
# This script tests key operations to identify RLS differences

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Environment URLs and keys
DEV_URL="https://joyavvleaxqzksopnmjs.supabase.co"
DEV_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og"

PROD_URL="https://bfrvahxmokeyrfnlaiwd.supabase.co"
PROD_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcnZhaHhtb2tleXJmbmxhaXdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQzMDI2NCwiZXhwIjoyMDY3MDA2MjY0fQ.C2x_AIkig4Fc7JSEyrkxve7E4uAwwvSRhPNDAeOfW-A"

echo -e "${BLUE}🔍 RLS Policy Test Comparison${NC}"
echo "====================================="
echo ""

# Function to test operation
test_operation() {
    local url="$1"
    local key="$2"
    local env_name="$3"
    local operation="$4"
    local endpoint="$5"
    local data="$6"
    
    echo -e "${YELLOW}Testing $operation in $env_name...${NC}"
    
    local response
    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X POST "$url$endpoint" \
            -H "Authorization: Bearer $key" \
            -H "apikey: $key" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "%{http_code}" -X GET "$url$endpoint" \
            -H "Authorization: Bearer $key" \
            -H "apikey: $key" \
            -H "Content-Type: application/json")
    fi
    
    local http_code=$(echo "$response" | tail -c 4)
    local response_body=$(echo "$response" | sed 's/[0-9]\{3\}$//')
    
    echo "  HTTP Code: $http_code"
    if [ -n "$response_body" ]; then
        echo "  Response: $response_body"
    fi
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "  ${GREEN}✅ SUCCESS${NC}"
        return 0
    else
        echo -e "  ${RED}❌ FAILED${NC}"
        return 1
    fi
}

# Test user creation and get user ID
echo -e "${BLUE}📋 Test 1: User Creation${NC}"
echo "====================================="

DEV_USER_DATA='{"email":"test+rls+dev+'"$(date +%s)"'@example.com"}'
PROD_USER_DATA='{"email":"test+rls+prod+'"$(date +%s)"'@example.com"}'

# Create dev user
DEV_USER_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$DEV_URL/rest/v1/users" \
    -H "Authorization: Bearer $DEV_KEY" \
    -H "apikey: $DEV_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "$DEV_USER_DATA")

DEV_USER_HTTP=$(echo "$DEV_USER_RESPONSE" | tail -c 4)
DEV_USER_BODY=$(echo "$DEV_USER_RESPONSE" | sed 's/[0-9]\{3\}$//')

if [ "$DEV_USER_HTTP" = "201" ]; then
    DEV_USER_ID=$(echo "$DEV_USER_BODY" | jq -r '.[0].id')
    echo -e "${GREEN}✅ Dev user created: $DEV_USER_ID${NC}"
    DEV_USER_SUCCESS=0
else
    echo -e "${RED}❌ Dev user creation failed${NC}"
    DEV_USER_SUCCESS=1
fi

# Create prod user
PROD_USER_RESPONSE=$(curl -s -w "%{http_code}" -X POST "$PROD_URL/rest/v1/users" \
    -H "Authorization: Bearer $PROD_KEY" \
    -H "apikey: $PROD_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "$PROD_USER_DATA")

PROD_USER_HTTP=$(echo "$PROD_USER_RESPONSE" | tail -c 4)
PROD_USER_BODY=$(echo "$PROD_USER_RESPONSE" | sed 's/[0-9]\{3\}$//')

if [ "$PROD_USER_HTTP" = "201" ]; then
    PROD_USER_ID=$(echo "$PROD_USER_BODY" | jq -r '.[0].id')
    echo -e "${GREEN}✅ Prod user created: $PROD_USER_ID${NC}"
    PROD_USER_SUCCESS=0
else
    echo -e "${RED}❌ Prod user creation failed${NC}"
    PROD_USER_SUCCESS=1
fi

echo ""

# Test user preferences creation
echo -e "${BLUE}📋 Test 2: User Preferences Creation${NC}"
echo "====================================="

if [ $DEV_USER_SUCCESS -eq 0 ]; then
    DEV_PREF_DATA="{\"user_id\":\"$DEV_USER_ID\",\"tts_voice\":\"alloy\",\"preferred_name\":\"Test\"}"
    test_operation "$DEV_URL" "$DEV_KEY" "dev" "preferences creation" "/rest/v1/user_preferences" "$DEV_PREF_DATA"
    DEV_PREF_SUCCESS=$?
else
    echo -e "${YELLOW}Skipping dev preferences test - no user created${NC}"
    DEV_PREF_SUCCESS=1
fi

if [ $PROD_USER_SUCCESS -eq 0 ]; then
    PROD_PREF_DATA="{\"user_id\":\"$PROD_USER_ID\",\"tts_voice\":\"alloy\",\"preferred_name\":\"Test\"}"
    test_operation "$PROD_URL" "$PROD_KEY" "prod" "preferences creation" "/rest/v1/user_preferences" "$PROD_PREF_DATA"
    PROD_PREF_SUCCESS=$?
else
    echo -e "${YELLOW}Skipping prod preferences test - no user created${NC}"
    PROD_PREF_SUCCESS=1
fi

echo ""

# Test user preferences update (to trigger audio generation)
echo -e "${BLUE}📋 Test 3: User Preferences Update (Audio Trigger)${NC}"
echo "====================================="

if [ $DEV_USER_SUCCESS -eq 0 ]; then
    DEV_UPDATE_DATA='{"tts_voice":"echo"}'
    test_operation "$DEV_URL" "$DEV_KEY" "dev" "preferences update" "/rest/v1/user_preferences?user_id=eq.$DEV_USER_ID" "$DEV_UPDATE_DATA"
    DEV_UPDATE_SUCCESS=$?
else
    echo -e "${YELLOW}Skipping dev preferences update test - no user created${NC}"
    DEV_UPDATE_SUCCESS=1
fi

if [ $PROD_USER_SUCCESS -eq 0 ]; then
    PROD_UPDATE_DATA='{"tts_voice":"echo"}'
    test_operation "$PROD_URL" "$PROD_KEY" "prod" "preferences update" "/rest/v1/user_preferences?user_id=eq.$PROD_USER_ID" "$PROD_UPDATE_DATA"
    PROD_UPDATE_SUCCESS=$?
else
    echo -e "${YELLOW}Skipping prod preferences update test - no user created${NC}"
    PROD_UPDATE_SUCCESS=1
fi

echo ""

# Test alarm creation
echo -e "${BLUE}📋 Test 4: Alarm Creation${NC}"
echo "====================================="

if [ $DEV_USER_SUCCESS -eq 0 ]; then
    DEV_ALARM_DATA="{\"user_id\":\"$DEV_USER_ID\",\"alarm_date\":\"2025-07-04\",\"alarm_time_local\":\"14:30:00\",\"alarm_timezone\":\"America/New_York\",\"timezone_at_creation\":\"America/New_York\",\"active\":true}"
    test_operation "$DEV_URL" "$DEV_KEY" "dev" "alarm creation" "/rest/v1/alarms" "$DEV_ALARM_DATA"
    DEV_ALARM_SUCCESS=$?
else
    echo -e "${YELLOW}Skipping dev alarm test - no user created${NC}"
    DEV_ALARM_SUCCESS=1
fi

if [ $PROD_USER_SUCCESS -eq 0 ]; then
    PROD_ALARM_DATA="{\"user_id\":\"$PROD_USER_ID\",\"alarm_date\":\"2025-07-04\",\"alarm_time_local\":\"14:30:00\",\"alarm_timezone\":\"America/New_York\",\"timezone_at_creation\":\"America/New_York\",\"active\":true}"
    test_operation "$PROD_URL" "$PROD_KEY" "prod" "alarm creation" "/rest/v1/alarms" "$PROD_ALARM_DATA"
    PROD_ALARM_SUCCESS=$?
else
    echo -e "${YELLOW}Skipping prod alarm test - no user created${NC}"
    PROD_ALARM_SUCCESS=1
fi

echo ""

# Summary
echo -e "${BLUE}📋 RLS Test Summary${NC}"
echo "====================================="

echo "Dev Environment:"
echo "  • User creation: $([ $DEV_USER_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"
echo "  • Preferences creation: $([ $DEV_PREF_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"
echo "  • Preferences update: $([ $DEV_UPDATE_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"
echo "  • Alarm creation: $([ $DEV_ALARM_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"

echo ""
echo "Prod Environment:"
echo "  • User creation: $([ $PROD_USER_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"
echo "  • Preferences creation: $([ $PROD_PREF_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"
echo "  • Preferences update: $([ $PROD_UPDATE_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"
echo "  • Alarm creation: $([ $PROD_ALARM_SUCCESS -eq 0 ] && echo "✅" || echo "❌")"

echo ""

# Identify differences
if [ $DEV_USER_SUCCESS -ne $PROD_USER_SUCCESS ]; then
    echo -e "${RED}❌ User creation differs between environments${NC}"
fi

if [ $DEV_PREF_SUCCESS -ne $PROD_PREF_SUCCESS ]; then
    echo -e "${RED}❌ Preferences creation differs between environments${NC}"
fi

if [ $DEV_UPDATE_SUCCESS -ne $PROD_UPDATE_SUCCESS ]; then
    echo -e "${RED}❌ Preferences update differs between environments${NC}"
fi

if [ $DEV_ALARM_SUCCESS -ne $PROD_ALARM_SUCCESS ]; then
    echo -e "${RED}❌ Alarm creation differs between environments${NC}"
fi

if [ $DEV_USER_SUCCESS -eq $PROD_USER_SUCCESS ] && [ $DEV_PREF_SUCCESS -eq $PROD_PREF_SUCCESS ] && [ $DEV_UPDATE_SUCCESS -eq $PROD_UPDATE_SUCCESS ] && [ $DEV_ALARM_SUCCESS -eq $PROD_ALARM_SUCCESS ]; then
    echo -e "${GREEN}✅ All RLS policies appear to match between environments${NC}"
fi

echo ""
echo -e "${CYAN}💡 Next steps:${NC}"
echo "• If preferences creation fails in prod, check RLS policies"
echo "• If preferences update fails in prod, check trigger permissions"
echo "• The 'permission denied for schema net' error suggests RLS is blocking the trigger" 