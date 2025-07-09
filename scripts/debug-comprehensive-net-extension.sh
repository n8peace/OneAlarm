#!/bin/bash

# Comprehensive Net Extension Error Diagnostic
# This script checks all possible sources of the net extension error

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Develop environment details
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔍 Comprehensive Net Extension Error Diagnostic${NC}"
echo "=================================================="

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
        "debug")
            echo -e "${CYAN}🔍 $message${NC}"
            ;;
    esac
}

# Step 1: Check if net extension is installed
print_status "info" "Step 1: Checking net extension installation..."

NET_EXTENSION_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT extname FROM pg_extension WHERE extname = '\''net'\'';"}')

print_status "debug" "Net extension check response:"
echo "$NET_EXTENSION_CHECK" | jq '.' 2>/dev/null || echo "$NET_EXTENSION_CHECK"

# Step 2: Check all functions that use net extension
print_status "info" "Step 2: Checking all functions that use net extension..."

NET_FUNCTIONS_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT proname, prosrc FROM pg_proc WHERE prosrc LIKE '\''%net%'\'';"}')

print_status "debug" "Functions using net extension:"
echo "$NET_FUNCTIONS_CHECK" | jq '.' 2>/dev/null || echo "$NET_FUNCTIONS_CHECK"

# Step 3: Check RLS policies on user_preferences
print_status "info" "Step 3: Checking RLS policies on user_preferences..."

RLS_POLICIES_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = '\''user_preferences'\'';"}')

print_status "debug" "RLS policies on user_preferences:"
echo "$RLS_POLICIES_CHECK" | jq '.' 2>/dev/null || echo "$RLS_POLICIES_CHECK"

# Step 4: Check for any triggers on user_preferences
print_status "info" "Step 4: Checking triggers on user_preferences..."

TRIGGERS_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT tgname, tgtype, tgenabled FROM pg_trigger WHERE tgrelid = (SELECT oid FROM pg_class WHERE relname = '\''user_preferences'\'');"}')

print_status "debug" "Triggers on user_preferences:"
echo "$TRIGGERS_CHECK" | jq '.' 2>/dev/null || echo "$TRIGGERS_CHECK"

# Step 5: Check for any views that might reference net extension
print_status "info" "Step 5: Checking views that might use net extension..."

VIEWS_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT viewname, definition FROM pg_views WHERE definition LIKE '\''%net%'\'';"}')

print_status "debug" "Views using net extension:"
echo "$VIEWS_CHECK" | jq '.' 2>/dev/null || echo "$VIEWS_CHECK"

# Step 6: Check for any materialized views
print_status "info" "Step 6: Checking materialized views..."

MATVIEWS_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT matviewname, definition FROM pg_matviews WHERE definition LIKE '\''%net%'\'';"}')

print_status "debug" "Materialized views using net extension:"
echo "$MATVIEWS_CHECK" | jq '.' 2>/dev/null || echo "$MATVIEWS_CHECK"

# Step 7: Check for any foreign key constraints that might trigger functions
print_status "info" "Step 7: Checking foreign key constraints..."

FK_CHECK=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT conname, confrelid::regclass, confupdtype, confdeltype FROM pg_constraint WHERE conrelid = (SELECT oid FROM pg_class WHERE relname = '\''user_preferences'\'') AND contype = '\''f'\'';"}')

print_status "debug" "Foreign key constraints on user_preferences:"
echo "$FK_CHECK" | jq '.' 2>/dev/null || echo "$FK_CHECK"

# Step 8: Test a simple UPDATE without tts_voice to isolate the issue
print_status "info" "Step 8: Testing UPDATE without tts_voice..."

# Get an existing user
USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id')

if [ "$EXISTING_USER_ID" != "null" ] && [ -n "$EXISTING_USER_ID" ]; then
    print_status "debug" "Testing UPDATE with user: $EXISTING_USER_ID"
    
    # Test UPDATE without tts_voice
    UPDATE_WITHOUT_TTS=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X PATCH "${DEVELOP_URL}/rest/v1/user_preferences?user_id=eq.$EXISTING_USER_ID" \
      -H "apikey: ${DEVELOP_SERVICE_KEY}" \
      -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -d '{"preferred_name": "Test Update Without TTS"}')
    
    HTTP_STATUS=$(echo "$UPDATE_WITHOUT_TTS" | grep "HTTPSTATUS:" | cut -d: -f2)
    RESPONSE_BODY=$(echo "$UPDATE_WITHOUT_TTS" | sed '/HTTPSTATUS:/d')
    
    print_status "debug" "UPDATE without tts_voice status: $HTTP_STATUS"
    print_status "debug" "UPDATE without tts_voice response:"
    echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
    
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "204" ]; then
        print_status "success" "UPDATE without tts_voice succeeded"
    else
        print_status "error" "UPDATE without tts_voice failed with HTTP $HTTP_STATUS"
    fi
else
    print_status "warning" "No existing user found for testing"
fi

# Step 9: Check if the issue is with the REST API itself
print_status "info" "Step 9: Checking if issue is with REST API configuration..."

API_CONFIG_CHECK=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/user_preferences?select=*&limit=0" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

print_status "debug" "REST API configuration check:"
echo "$API_CONFIG_CHECK" | jq '.' 2>/dev/null || echo "$API_CONFIG_CHECK"

print_status "info" "Step 10: Analysis Summary"
echo "====================="
print_status "info" "The net extension error is likely coming from one of these sources:"
echo "1. RLS policies that use functions with net extension"
echo "2. Default values on columns that call functions"
echo "3. Check constraints that reference functions"
echo "4. System-level triggers or functions"
echo "5. REST API configuration issues"
echo ""
print_status "info" "Next steps:"
echo "1. Review the output above for any net extension references"
echo "2. Check if RLS policies need to be simplified"
echo "3. Consider disabling RLS temporarily to isolate the issue"
echo "4. Check if the issue is specific to the develop environment" 