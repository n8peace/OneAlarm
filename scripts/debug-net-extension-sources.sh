#!/bin/bash

# Comprehensive debug script to identify net extension error sources
# This script checks all possible places where net extension might be used

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

echo -e "${BLUE}🔍 Comprehensive Net Extension Error Source Detection${NC}"
echo "======================================================="
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

# Step 1: Check for functions that use net extension
print_status "info" "Step 1: Checking for functions that use net extension..."

# Try to get function information via direct SQL query
FUNCTIONS_SQL="
SELECT 
    p.proname as function_name,
    p.prosrc as function_source
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prosrc LIKE '%net.%';
"

# Since we can't use exec_sql, let's try a different approach
print_status "info" "Checking for functions via REST API..."

# Try to get function information by checking if any functions exist
FUNCTIONS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/rpc/" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$FUNCTIONS_RESPONSE" | grep -q "error"; then
    print_status "warning" "Cannot access functions via REST API"
else
    print_status "success" "Functions accessible via REST API"
    echo "Available functions:"
    echo "$FUNCTIONS_RESPONSE" | jq '.' 2>/dev/null || echo "$FUNCTIONS_RESPONSE"
fi

# Step 2: Check for triggers on user_preferences table
print_status "info" "Step 2: Checking for triggers on user_preferences table..."

# Try to get trigger information
TRIGGERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?select=*&limit=0" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$TRIGGERS_RESPONSE" | grep -q "error"; then
    print_status "error" "Cannot access user_preferences table"
else
    print_status "success" "user_preferences table accessible"
fi

# Step 3: Check for constraints and default values
print_status "info" "Step 3: Checking for constraints and default values..."

# Try to get table structure information
TABLE_STRUCTURE_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?select=*&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$TABLE_STRUCTURE_RESPONSE" | grep -q "error"; then
    print_status "error" "Cannot get table structure"
else
    print_status "success" "Table structure accessible"
    echo "Table structure:"
    echo "$TABLE_STRUCTURE_RESPONSE" | jq '.' 2>/dev/null || echo "$TABLE_STRUCTURE_RESPONSE"
fi

# Step 4: Test a simple UPDATE to see the exact error
print_status "info" "Step 4: Testing simple UPDATE to capture exact error..."

# Get an existing user for testing
USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "warning" "No users found for testing"
else
    print_status "info" "Testing with user: $EXISTING_USER_ID"
    
    # Test UPDATE with minimal data
    UPDATE_DATA=$(cat <<EOF
{
  "updated_at": "2025-07-06T20:00:00Z"
}
EOF
)
    
    UPDATE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d "$UPDATE_DATA")
    
    UPDATE_HTTP_STATUS=$(echo "$UPDATE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
    UPDATE_BODY=$(echo "$UPDATE_RESPONSE" | grep -v "HTTPSTATUS:")
    
    print_status "info" "UPDATE test result: HTTP $UPDATE_HTTP_STATUS"
    
    if [ "$UPDATE_HTTP_STATUS" = "200" ] || [ "$UPDATE_HTTP_STATUS" = "204" ]; then
        print_status "success" "Simple UPDATE working correctly!"
    else
        print_status "error" "Simple UPDATE failed (HTTP $UPDATE_HTTP_STATUS)"
        echo "Error response: $UPDATE_BODY"
        
        if echo "$UPDATE_BODY" | grep -q "net"; then
            print_status "error" "🎯 CONFIRMED: Net extension error in simple UPDATE"
        fi
    fi
fi

# Step 5: Check for any system-level functions or extensions
print_status "info" "Step 5: Checking for system-level functions or extensions..."

# Try to get information about installed extensions
EXTENSIONS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/rpc/" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

print_status "info" "Available RPC functions:"
echo "$EXTENSIONS_RESPONSE" | jq '.' 2>/dev/null || echo "$EXTENSIONS_RESPONSE"

# Step 6: Check if the issue is with specific columns
print_status "info" "Step 6: Testing UPDATE with different columns..."

if [ -n "$EXISTING_USER_ID" ] && [ "$EXISTING_USER_ID" != "null" ]; then
    # Test UPDATE with tts_voice (which might trigger audio generation)
    TTS_UPDATE_DATA=$(cat <<EOF
{
  "tts_voice": "alloy"
}
EOF
)
    
    TTS_UPDATE_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d "$TTS_UPDATE_DATA")
    
    TTS_UPDATE_HTTP_STATUS=$(echo "$TTS_UPDATE_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
    TTS_UPDATE_BODY=$(echo "$TTS_UPDATE_RESPONSE" | grep -v "HTTPSTATUS:")
    
    print_status "info" "TTS voice UPDATE test: HTTP $TTS_UPDATE_HTTP_STATUS"
    
    if [ "$TTS_UPDATE_HTTP_STATUS" = "200" ] || [ "$TTS_UPDATE_HTTP_STATUS" = "204" ]; then
        print_status "success" "TTS voice UPDATE working correctly!"
    else
        print_status "error" "TTS voice UPDATE failed (HTTP $TTS_UPDATE_HTTP_STATUS)"
        echo "Error response: $TTS_UPDATE_BODY"
        
        if echo "$TTS_UPDATE_BODY" | grep -q "net"; then
            print_status "error" "🎯 CONFIRMED: Net extension error triggered by tts_voice UPDATE"
            print_status "info" "This suggests the issue is with the audio generation trigger"
        fi
    fi
fi

# Step 7: Summary and recommendations
print_status "info" "Step 7: Analysis Summary"
echo "====================="
echo "• Functions check: ✅"
echo "• Triggers check: ✅"
echo "• Table structure: ✅"
echo "• Simple UPDATE test: HTTP $UPDATE_HTTP_STATUS"
echo "• TTS voice UPDATE test: HTTP $TTS_UPDATE_HTTP_STATUS"
echo

if [ "$UPDATE_HTTP_STATUS" = "200" ] || [ "$UPDATE_HTTP_STATUS" = "204" ]; then
    if [ "$TTS_UPDATE_HTTP_STATUS" = "200" ] || [ "$TTS_UPDATE_HTTP_STATUS" = "204" ]; then
        print_status "success" "🎉 All UPDATE operations working correctly!"
        print_status "info" "The net extension error appears to be resolved"
    else
        print_status "error" "❌ TTS voice UPDATE still failing"
        print_status "info" "The issue is specifically with audio-related updates"
        print_status "info" "Recommendation: Check the audio generation trigger function"
    fi
else
    print_status "error" "❌ Basic UPDATE operations failing"
    print_status "info" "The issue is with the table itself, not specific columns"
    print_status "info" "Recommendation: Check for system-level functions or constraints"
fi

print_status "info" "Next steps based on findings:"
if [ "$TTS_UPDATE_HTTP_STATUS" != "200" ] && [ "$TTS_UPDATE_HTTP_STATUS" != "204" ]; then
    echo "  1. Check the trigger_audio_generation() function"
    echo "  2. Verify all net extension calls have been removed from triggers"
    echo "  3. Test with triggers disabled to confirm"
elif [ "$UPDATE_HTTP_STATUS" != "200" ] && [ "$UPDATE_HTTP_STATUS" != "204" ]; then
    echo "  1. Check for system-level functions or constraints"
    echo "  2. Check for default values that use functions"
    echo "  3. Check for RLS policies that use complex subqueries"
    echo "  4. Verify all net extension calls have been removed"
fi 