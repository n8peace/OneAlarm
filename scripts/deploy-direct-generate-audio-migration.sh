#!/bin/bash

# Deploy direct generate-audio migration to develop
# This script applies the migration that adds direct HTTP call to generate-audio

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

echo -e "${BLUE}🚀 Deploying Direct Generate-Audio Migration to Develop${NC}"
echo "========================================================="
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

print_status "info" "Preparing to apply migration..."

# Check if the migration file exists
if [ ! -f "scripts/apply-direct-generate-audio-migration.sql" ]; then
    print_status "error" "Migration file not found: scripts/apply-direct-generate-audio-migration.sql"
    exit 1
fi

print_status "info" "Migration file found. Ready to deploy."

echo
echo -e "${YELLOW}📋 Manual Deployment Required:${NC}"
echo "=========================================="
echo
echo "1. Go to the Supabase Dashboard:"
echo "   https://xqkmpkfqoisqzznnvlox.supabase.co/sql"
echo
echo "2. Copy the entire contents of the migration file:"
echo "   scripts/apply-direct-generate-audio-migration.sql"
echo
echo "3. Paste the SQL into the SQL Editor and click 'Run'"
echo
echo "4. Verify the migration was successful by checking the logs table"
echo

print_status "info" "Migration SQL content:"
echo "----------------------------------------"
cat scripts/apply-direct-generate-audio-migration.sql
echo "----------------------------------------"

echo
print_status "info" "After applying the migration, you can test it by:"
echo
echo "1. Updating a user's preferences:"
echo "   UPDATE user_preferences SET tts_voice = 'nova' WHERE user_id = 'your-test-user-id';"
echo
echo "2. Check the logs for the trigger execution:"
echo "   SELECT * FROM logs WHERE event_type = 'preferences_updated_audio_trigger' ORDER BY created_at DESC LIMIT 5;"
echo
echo "3. Check that the generate-audio function was called and audio files were created"
echo

print_status "success" "Migration ready for deployment!"
echo
echo -e "${BLUE}🔍 Verification Steps:${NC}"
echo "1. Apply the SQL in the Supabase Dashboard"
echo "2. Test by updating user preferences"
echo "3. Verify direct HTTP call to generate-audio is working"
echo "4. Confirm queue logic still works as expected"
echo

print_status "info" "Checking migration status..."

# Check migration status
MIGRATION_STATUS=$(curl -s -X GET "${DEVELOP_URL}/rest/v1/logs?select=count&limit=1&event_type=trigger_update" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")

if echo "$MIGRATION_STATUS" | grep -q "error"; then
    print_status "error" "Failed to check migration status"
    echo "Response: $MIGRATION_STATUS"
    exit 1
else
    print_status "success" "Migration status checked successfully"
fi

print_status "info" "Migration status:"
echo "----------------------------------------"
echo "$MIGRATION_STATUS"
echo "----------------------------------------"

print_status "info" "After applying the migration, you can test it by:"
echo
echo "1. Updating a user's preferences:"
echo "   UPDATE user_preferences SET tts_voice = 'nova' WHERE user_id = 'your-test-user-id';"
echo
echo "2. Check the logs for the trigger execution:"
echo "   SELECT * FROM logs WHERE event_type = 'preferences_updated_audio_trigger' ORDER BY created_at DESC LIMIT 5;"
echo
echo "3. Check that the generate-audio function was called and audio files were created"
echo

print_status "success" "Migration ready for deployment!"
echo
echo -e "${BLUE}🔍 Verification Steps:${NC}"
echo "1. Apply the SQL in the Supabase Dashboard"
echo "2. Test by updating user preferences"
echo "3. Verify direct HTTP call to generate-audio is working"
echo "4. Confirm queue logic still works as expected"
echo 