#!/bin/bash

# Apply Users Foreign Key Fix Script
# Removes the foreign key constraint that requires users to exist in auth.users

set -e

# Source shared configuration
source ./scripts/config.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Apply Users Foreign Key Fix${NC}"
echo "====================================="
echo ""

# Check if service role key is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Service role key is required${NC}"
    echo ""
    echo "Usage: ./scripts/apply-users-foreign-key-fix.sh YOUR_SERVICE_ROLE_KEY"
    echo ""
    echo "This script will:"
    echo "1. Remove the foreign key constraint from users table"
    echo "2. Allow direct user creation without auth.users dependency"
    echo "3. Update related functions to handle the change"
    echo ""
    echo "To get your service role key:"
    echo "1. Go to ${SUPABASE_URL}/settings/api"
    echo "2. Copy the 'service_role' key (not the anon key)"
    exit 1
fi

SERVICE_ROLE_KEY="$1"

# Override for develop environment
SUPABASE_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"

echo -e "${CYAN}📋 Project:${NC} $SUPABASE_URL"
echo -e "${CYAN}🔧 Fix:${NC} Remove users table foreign key constraint"
echo ""

# Read the SQL file
SQL_CONTENT=$(cat ./scripts/fix-users-foreign-key.sql)

echo -e "${YELLOW}⚠️  Applying foreign key constraint fix...${NC}"

# Apply the SQL via REST API
RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"sql\": $(echo "$SQL_CONTENT" | jq -R -s .)}")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Foreign key constraint fix applied successfully${NC}"
    echo ""
    echo -e "${BLUE}📋 Changes made:${NC}"
    echo "• Removed foreign key constraint from users table"
    echo "• Updated id column to auto-generate UUIDs"
    echo "• Updated handle_new_user function"
    echo "• Updated sync_auth_to_public_user function"
    echo ""
    echo -e "${GREEN}🎉 Users can now be created directly without auth.users dependency${NC}"
else
    echo -e "${RED}❌ Failed to apply foreign key constraint fix${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Test user creation: ./scripts/create-test-user.sh $SERVICE_ROLE_KEY"
echo "2. Run e2e test: ./scripts/test-system-develop.sh e2e $SERVICE_ROLE_KEY"
echo "3. Check system status: ./scripts/check-system-status.sh $SERVICE_ROLE_KEY" 