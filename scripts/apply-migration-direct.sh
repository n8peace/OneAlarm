#!/bin/bash

# Direct migration application script
# This script applies the migration directly using the service role key

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

echo -e "${BLUE}🔧 Applying Migration Directly${NC}"
echo "================================="
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

print_status "info" "Applying migration..."

# Read the migration SQL
MIGRATION_SQL=$(cat supabase/migrations/20250706000006_fix_develop_user_preferences_trigger.sql)

# Since we can't execute SQL directly via REST API, we'll use the Supabase CLI
# First, let's check if we can use the CLI
if command -v supabase &> /dev/null; then
    print_status "info" "Using Supabase CLI to apply migration..."
    
    # Create a temporary migration file
    TEMP_MIGRATION="temp_migration_$(date +%s).sql"
    echo "$MIGRATION_SQL" > "$TEMP_MIGRATION"
    
    # Try to apply using CLI (this might not work without proper linking)
    print_status "warning" "Supabase CLI found but may not be properly linked to develop project"
    print_status "info" "Attempting to apply migration via CLI..."
    
    # Set environment variables for the CLI
    export SUPABASE_URL="$DEVELOP_URL"
    export SUPABASE_SERVICE_ROLE_KEY="$DEVELOP_SERVICE_KEY"
    
    # Try to apply the migration
    if supabase db push --local; then
        print_status "success" "Migration applied via CLI"
    else
        print_status "warning" "CLI method failed, trying alternative approach..."
        
        # Alternative: Use the SQL editor via API (if available)
        print_status "info" "CLI method not available. Please apply manually:"
        echo
        echo -e "${YELLOW}📋 Manual Application Required:${NC}"
        echo "1. Go to: https://xqkmpkfqoisqzznnvlox.supabase.co/sql"
        echo "2. Copy the contents of: scripts/apply-develop-migration-sql.sql"
        echo "3. Paste and run the SQL"
        echo
        print_status "info" "Migration SQL content:"
        echo "----------------------------------------"
        cat scripts/apply-develop-migration-sql.sql
        echo "----------------------------------------"
    fi
    
    # Clean up
    rm -f "$TEMP_MIGRATION"
    
else
    print_status "info" "Supabase CLI not found. Please apply manually:"
    echo
    echo -e "${YELLOW}📋 Manual Application Required:${NC}"
    echo "1. Go to: https://xqkmpkfqoisqzznnvlox.supabase.co/sql"
    echo "2. Copy the contents of: scripts/apply-develop-migration-sql.sql"
    echo "3. Paste and run the SQL"
    echo
    print_status "info" "Migration SQL content:"
    echo "----------------------------------------"
    cat scripts/apply-develop-migration-sql.sql
    echo "----------------------------------------"
fi

echo
print_status "info" "Migration application complete!"
echo
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Verify the migration was applied successfully"
echo "2. Test by updating a user preference"
echo "3. Check that queue items are created"
echo 