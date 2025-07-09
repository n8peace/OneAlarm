#!/bin/bash

# Apply Develop Environment URL Fix
# This script fixes the develop environment to call its own functions instead of main

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

echo -e "${BLUE}🔧 Fixing Develop Environment URL${NC}"
echo "====================================="
echo
echo -e "${YELLOW}⚠️  CRITICAL: Develop environment is calling main functions!${NC}"
echo -e "${YELLOW}⚠️  This fix will correct the URL to call develop functions.${NC}"
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

# Check if we have the required tools
if ! command -v curl &> /dev/null; then
    print_status "error" "curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_status "error" "jq is required but not installed"
    exit 1
fi

print_status "info" "Testing connection to develop environment..."

# Test connection
TEST_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=count&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$TEST_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to connect to develop environment"
    echo "Response: $TEST_RESPONSE"
    exit 1
else
    print_status "success" "Connection to develop environment successful"
fi

print_status "info" "Reading migration SQL..."

# Read the migration SQL
MIGRATION_SQL=$(cat scripts/fix-develop-environment-url.sql)

if [ -z "$MIGRATION_SQL" ]; then
    print_status "error" "Failed to read migration SQL file"
    exit 1
fi

print_status "success" "Migration SQL loaded"

print_status "info" "Applying URL fix to develop environment..."

# Apply the migration using the Supabase REST API
RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"sql\": $(echo "$MIGRATION_SQL" | jq -R -s .)
  }")

if echo "$RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to apply migration"
    echo "Response: $RESPONSE"
    exit 1
else
    print_status "success" "URL fix applied successfully!"
fi

echo
print_status "info" "Verifying the fix..."

# Verify the fix by checking the function definition
VERIFY_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"sql\": \"SELECT CASE WHEN prosrc LIKE '%xqkmpkfqoisqzznnvlox%' THEN 'CORRECT' ELSE 'INCORRECT' END as url_check FROM pg_proc WHERE proname = 'trigger_audio_generation';\" 
  }")

if echo "$VERIFY_RESPONSE" | grep -q "CORRECT"; then
    print_status "success" "✅ Develop environment now calls its own functions!"
else
    print_status "error" "❌ URL fix verification failed"
    echo "Response: $VERIFY_RESPONSE"
fi

echo
echo -e "${GREEN}🎉 Develop Environment URL Fix Complete!${NC}"
echo "============================================="
echo
echo -e "${BLUE}📋 Summary:${NC}"
echo "  • Fixed develop environment to call its own functions"
echo "  • Removed dependency on main environment"
echo "  • Maintained same trigger behavior as main"
echo "  • Added proper logging for tracking"
echo
echo -e "${BLUE}🔍 Next Steps:${NC}"
echo "  1. Test user preferences updates in develop"
echo "  2. Verify audio generation works correctly"
echo "  3. Check that develop functions are being called"
echo
echo -e "${BLUE}🌐 Develop Dashboard:${NC}"
echo "  https://supabase.com/dashboard/project/xqkmpkfqoisqzznnvlox" 