#!/bin/bash

# Apply Missing Fields Migration Script
# Adds missing fields to weather_data and alarms tables to match main environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Apply Missing Fields Migration${NC}"
echo "====================================="
echo ""

# Check if service role key is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo ""
    echo "Usage: ./scripts/apply-missing-fields.sh YOUR_SERVICE_ROLE_KEY"
    echo ""
    echo "This script will:"
    echo "1. Add current_temp, high_temp, low_temp to weather_data table"
    echo "2. Add timezone_at_creation to alarms table"
    echo "3. Update existing records with default values"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to https://xqkmpkfqoisqzznnvlox.supabase.co/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
fi

SERVICE_ROLE_KEY="$1"
SUPABASE_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"

echo -e "${CYAN}📋 Project:${NC} $SUPABASE_URL"
echo -e "${CYAN}🔧 Migration:${NC} Add missing fields to match main environment"
echo ""

# Read the SQL file
SQL_CONTENT=$(cat ./scripts/add-missing-fields.sql)

echo -e "${YELLOW}⚠️  Applying missing fields migration...${NC}"

# Apply the SQL via REST API
RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"sql\": $(echo "$SQL_CONTENT" | jq -R -s .)}")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Missing fields migration applied successfully${NC}"
    echo ""
    echo -e "${BLUE}📋 Changes made:${NC}"
    echo "• Added current_temp, high_temp, low_temp to weather_data table"
    echo "• Added timezone_at_creation to alarms table"
    echo "• Updated existing records with default values"
    echo ""
    echo -e "${GREEN}🎉 Develop environment now matches main schema${NC}"
else
    echo -e "${RED}❌ Failed to apply missing fields migration${NC}"
    echo "Response: $RESPONSE"
    echo ""
    echo -e "${YELLOW}⚠️  Since exec_sql is not available, please apply manually:${NC}"
    echo ""
    echo "1. Go to: https://supabase.com/dashboard/project/xqkmpkfqoisqzznnvlox"
    echo "2. Navigate to SQL Editor"
    echo "3. Copy and paste the contents of scripts/add-missing-fields.sql"
    echo "4. Click Run"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Test user creation: ./scripts/create-test-user.sh $SERVICE_ROLE_KEY"
echo "2. Run e2e test: ./scripts/test-system-develop.sh e2e $SERVICE_ROLE_KEY"
echo "3. Check system status: ./scripts/check-system-status.sh $SERVICE_ROLE_KEY" 