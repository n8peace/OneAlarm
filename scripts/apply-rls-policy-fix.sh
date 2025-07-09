#!/bin/bash

# Apply RLS policy fix to resolve net extension error
# This script applies the migration to fix user_preferences RLS policies

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

echo -e "${BLUE}🔧 Applying RLS Policy Fix for Net Extension Error${NC}"
echo "====================================================="
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

# Step 1: Read the migration SQL
print_status "info" "Step 1: Reading RLS policy fix migration..."

MIGRATION_SQL=$(cat supabase/migrations/20250707000008_fix_user_preferences_rls_policies.sql)

if [ -z "$MIGRATION_SQL" ]; then
    print_status "error" "Failed to read migration SQL file"
    exit 1
fi

print_status "success" "Migration SQL loaded"

# Step 2: Apply the migration
print_status "info" "Step 2: Applying RLS policy fix migration..."

MIGRATION_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$MIGRATION_SQL" | jq -R -s .)
  }")

if echo "$MIGRATION_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to apply RLS policy fix"
    echo "Response: $MIGRATION_RESPONSE"
    exit 1
fi

print_status "success" "RLS policy fix applied successfully"

# Step 3: Test the fix
print_status "info" "Step 3: Testing the fix..."

# Get an existing user for testing
USERS_RESPONSE=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

EXISTING_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$EXISTING_USER_ID" ] || [ "$EXISTING_USER_ID" = "null" ]; then
    print_status "warning" "No users found for testing"
else
    print_status "info" "Testing with user: $EXISTING_USER_ID"
    
    # Test UPDATE operation
    UPDATE_DATA=$(cat <<EOF
{
  "tts_voice": "alloy",
  "preferred_name": "RLS Test User"
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
    
    if [ "$UPDATE_HTTP_STATUS" = "200" ] || [ "$UPDATE_HTTP_STATUS" = "204" ]; then
        print_status "success" "UPDATE operation working correctly!"
    else
        print_status "error" "UPDATE operation still failing (HTTP $UPDATE_HTTP_STATUS)"
        echo "Error response: $UPDATE_BODY"
        
        if echo "$UPDATE_BODY" | grep -q "net"; then
            print_status "error" "🎯 Net extension error still exists"
        fi
    fi
fi

# Step 4: Summary
print_status "info" "Step 4: Fix Summary"
echo "=================="
echo "• RLS policy fix applied: ✅"
echo "• Test user ID: $EXISTING_USER_ID"
echo "• UPDATE test: HTTP $UPDATE_HTTP_STATUS"
echo

if [ "$UPDATE_HTTP_STATUS" = "200" ] || [ "$UPDATE_HTTP_STATUS" = "204" ]; then
    print_status "success" "🎉 RLS policy fix successful!"
    print_status "info" "The net extension error has been resolved"
else
    print_status "error" "❌ RLS policy fix did not resolve the issue"
    print_status "info" "The net extension error may be coming from another source"
    print_status "info" "Next steps:"
    echo "  1. Check for default values that use functions"
    echo "  2. Check for system-level triggers or functions"
    echo "  3. Check for constraints that use functions"
    echo "  4. Verify all net extension calls have been removed"
fi 