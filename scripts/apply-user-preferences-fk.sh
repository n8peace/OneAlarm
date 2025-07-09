#!/bin/bash

# Apply User Preferences Foreign Key Migration Script
# Adds missing foreign key constraint to match main environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Apply User Preferences Foreign Key Migration${NC}"
echo "====================================="
echo ""

# Check if service role key is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo ""
    echo "Usage: ./scripts/apply-user-preferences-fk.sh YOUR_SERVICE_ROLE_KEY"
    echo ""
    echo "This script will:"
    echo "1. Add foreign key constraint to user_preferences table"
    echo "2. Match the main environment schema exactly"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to https://xqkmpkfqoisqzznnvlox.supabase.co/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
fi

SERVICE_ROLE_KEY="$1"
SUPABASE_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"

echo -e "${CYAN}📋 Project:${NC} $SUPABASE_URL"
echo -e "${CYAN}🔧 Migration:${NC} Add user_preferences foreign key constraint"
echo ""

# Read the SQL file
SQL_CONTENT=$(cat ./scripts/add-user-preferences-foreign-key.sql)

echo -e "${YELLOW}⚠️  Applying user preferences foreign key migration...${NC}"

# Apply the SQL via REST API
RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"sql\": $(echo "$SQL_CONTENT" | jq -R -s .)}")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ User preferences foreign key migration applied successfully${NC}"
    echo ""
    echo -e "${BLUE}📋 Changes made:${NC}"
    echo "• Added foreign key constraint to user_preferences table"
    echo "• user_preferences.user_id now references users.id"
    echo "• Matches main environment schema exactly"
    echo ""
    echo -e "${GREEN}🎉 Develop environment now matches main schema${NC}"
else
    echo -e "${RED}❌ Failed to apply user preferences foreign key migration${NC}"
    echo "Response: $RESPONSE"
    echo ""
    echo -e "${YELLOW}⚠️  Since exec_sql is not available, please apply manually:${NC}"
    echo ""
    echo "1. Go to: https://supabase.com/dashboard/project/xqkmpkfqoisqzznnvlox"
    echo "2. Navigate to SQL Editor"
    echo "3. Copy and paste the contents of scripts/add-user-preferences-foreign-key.sql"
    echo "4. Click Run"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Test user preferences creation"
echo "2. Run e2e test: ./scripts/test-system-develop.sh e2e $SERVICE_ROLE_KEY"
echo "3. Check system status: ./scripts/check-system-status.sh $SERVICE_ROLE_KEY" 