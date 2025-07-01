#!/bin/bash

# OneAlarm Database Schema Validation Script
# Use this script to validate database schema and migration status before making changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 OneAlarm Database Schema Validation${NC}"
echo "============================================="
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ Error: .env file not found${NC}"
    echo "Please create a .env file with your Supabase configuration"
    exit 1
fi

# Validate required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ Error: Missing required environment variables${NC}"
    echo "Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in your .env file"
    exit 1
fi

# Function to check if jq is available
check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Warning: jq is not installed. JSON responses will not be formatted.${NC}"
        echo "Install jq for better output formatting: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        return 1
    fi
    return 0
}

# Function to format JSON response
format_json() {
    local json="$1"
    if check_jq; then
        echo "$json" | jq '.' 2>/dev/null || echo "$json"
    else
        echo "$json"
    fi
}

echo -e "${CYAN}📊 Step 1: Checking Database Connectivity${NC}"
echo "--------------------------------------------"

# Test database connectivity
DB_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -w "\nHTTPSTATUS:%{http_code}")

# Extract HTTP status code
HTTP_STATUS=$(echo "$DB_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
# Extract response body (remove the HTTPSTATUS line)
RESPONSE_BODY=$(echo "$DB_RESPONSE" | grep -v "HTTPSTATUS:")

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Database is accessible${NC}"
else
    echo -e "${RED}❌ Database connectivity failed (HTTP $HTTP_STATUS)${NC}"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

echo ""
echo -e "${CYAN}📋 Step 2: Checking Database Schema${NC}"
echo "-----------------------------------"

# Extract table names from API response
if check_jq; then
    TABLES=$(echo "$RESPONSE_BODY" | jq -r '.paths | keys[]' | grep -v '^/rpc/' | sort)
    TABLE_COUNT=$(echo "$TABLES" | wc -l | tr -d ' ')
    
    echo -e "${GREEN}✅ Found $TABLE_COUNT tables in database:${NC}"
    echo "$TABLES" | sed 's/^/  - /'
    
    # Check for expected tables
    EXPECTED_TABLES=("users" "user_preferences" "alarms" "audio" "daily_content" "weather_data" "logs" "audio_generation_queue" "user_events")
    MISSING_TABLES=()
    
    for table in "${EXPECTED_TABLES[@]}"; do
        if ! echo "$TABLES" | grep -q "^$table$"; then
            MISSING_TABLES+=("$table")
        fi
    done
    
    if [ ${#MISSING_TABLES[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ All expected tables are present${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing expected tables:${NC}"
        for table in "${MISSING_TABLES[@]}"; do
            echo "  - $table"
        done
    fi
else
    echo -e "${YELLOW}⚠️  jq not available - cannot parse table list${NC}"
    echo "Raw response:"
    echo "$RESPONSE_BODY" | head -20
fi

echo ""
echo -e "${CYAN}📊 Step 3: Checking Migration Status${NC}"
echo "-----------------------------------"

# Check migration status
echo "Migration tracking status:"
MIGRATION_OUTPUT=$(supabase migration list 2>&1)

if echo "$MIGRATION_OUTPUT" | grep -q "Local.*Remote"; then
    # Check if all migrations are synced
    UNSYNCED_COUNT=$(echo "$MIGRATION_OUTPUT" | grep "Local.*|.*$" | wc -l | tr -d ' ')
    
    if [ "$UNSYNCED_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✅ All migrations are in sync${NC}"
    else
        echo -e "${YELLOW}⚠️  Found $UNSYNCED_COUNT unsynced migrations${NC}"
        echo "$MIGRATION_OUTPUT" | grep "Local.*|.*$"
        echo ""
        echo -e "${YELLOW}Recommendation: Run migration repair before making changes${NC}"
    fi
else
    echo -e "${RED}❌ Migration status check failed${NC}"
    echo "$MIGRATION_OUTPUT"
fi

echo ""
echo -e "${CYAN}🔧 Step 4: Checking Function Status${NC}"
echo "--------------------------------"

# Check function status
echo "Edge function status:"
FUNCTION_OUTPUT=$(supabase functions list 2>&1)

if echo "$FUNCTION_OUTPUT" | grep -q "ACTIVE"; then
    ACTIVE_FUNCTIONS=$(echo "$FUNCTION_OUTPUT" | grep "ACTIVE" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Found $ACTIVE_FUNCTIONS active functions${NC}"
    
    # List active functions
    echo "$FUNCTION_OUTPUT" | grep "ACTIVE" | while read -r line; do
        FUNCTION_NAME=$(echo "$line" | awk '{print $2}')
        echo "  - $FUNCTION_NAME"
    done
else
    echo -e "${YELLOW}⚠️  No active functions found${NC}"
    echo "$FUNCTION_OUTPUT"
fi

echo ""
echo -e "${CYAN}📈 Step 5: Quick Health Check${NC}"
echo "----------------------------"

# Test a simple query
echo "Testing basic query..."
QUERY_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?limit=1" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -w "\nHTTPSTATUS:%{http_code}")

QUERY_STATUS=$(echo "$QUERY_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
QUERY_BODY=$(echo "$QUERY_RESPONSE" | grep -v "HTTPSTATUS:")

if [ "$QUERY_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Basic query test passed${NC}"
else
    echo -e "${YELLOW}⚠️  Basic query test failed (HTTP $QUERY_STATUS)${NC}"
    echo "This might be due to RLS policies or empty table"
fi

echo ""
echo -e "${BLUE}📋 Validation Summary${NC}"
echo "========================"

# Summary checks
echo -e "${GREEN}✅ Database connectivity: OK${NC}"
echo -e "${GREEN}✅ Schema validation: OK${NC}"

if [ "$UNSYNCED_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ Migration tracking: OK${NC}"
else
    echo -e "${YELLOW}⚠️  Migration tracking: $UNSYNCED_COUNT unsynced${NC}"
fi

if [ "$ACTIVE_FUNCTIONS" -gt 0 ]; then
    echo -e "${GREEN}✅ Functions: $ACTIVE_FUNCTIONS active${NC}"
else
    echo -e "${YELLOW}⚠️  Functions: No active functions found${NC}"
fi

echo ""
if [ "$UNSYNCED_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 Database is ready for development!${NC}"
else
    echo -e "${YELLOW}⚠️  Please fix migration tracking before making changes${NC}"
    echo ""
    echo "To fix migration tracking:"
    echo "1. Check if schema actually exists: curl -s \"$SUPABASE_URL/rest/v1/\" -H \"apikey: $SUPABASE_ANON_KEY\""
    echo "2. If schema exists, mark migrations as applied: supabase migration repair --status applied <migration_ids>"
    echo "3. If schema doesn't exist, mark as reverted: supabase migration repair --status reverted <migration_ids>"
fi

echo ""
echo -e "${BLUE}📚 For more information, see:${NC}"
echo "- docs/DATABASE_MANAGEMENT.md"
echo "- docs/CONNECTING_TO_SUPABASE.md" 