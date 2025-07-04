#!/bin/bash

# OneAlarm Develop Branch Setup Script
# This script sets up the develop branch in Supabase and deploys the schema

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEV_PROJECT_REF="xqkmpkfqoisqzznnvlox"
BRANCH_NAME="develop"

echo -e "${BLUE}🚀 OneAlarm Develop Branch Setup${NC}"
echo "=================================="

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI is not installed${NC}"
    echo "Please install it first: https://supabase.com/docs/reference/cli"
    exit 1
fi

# Check if logged in
echo -e "${YELLOW}🔍 Checking Supabase CLI authentication...${NC}"
if ! supabase projects list &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Supabase CLI${NC}"
    echo "Please run: supabase login"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI is authenticated${NC}"

# Link to development project
echo -e "${YELLOW}🔗 Linking to development project: $DEV_PROJECT_REF${NC}"
supabase link --project-ref $DEV_PROJECT_REF

# Check if develop branch exists
echo -e "${YELLOW}🔍 Checking if develop branch exists...${NC}"
if supabase branches list --experimental | grep -q "$BRANCH_NAME"; then
    echo -e "${GREEN}✅ Develop branch exists, switching to it${NC}"
    supabase branch switch $BRANCH_NAME
else
    echo -e "${YELLOW}🆕 Develop branch doesn't exist, creating it${NC}"
    supabase branch create $BRANCH_NAME
    supabase branch switch $BRANCH_NAME
fi

# Deploy database schema
echo -e "${YELLOW}🗄️ Deploying database schema to develop branch...${NC}"
if [ -d "supabase/migrations" ] && [ "$(ls -A supabase/migrations)" ]; then
    echo -e "${BLUE}📦 Found migrations, deploying...${NC}"
    supabase db push --linked
    echo -e "${GREEN}✅ Database schema deployed successfully${NC}"
else
    echo -e "${YELLOW}ℹ️ No migrations found, skipping database deployment${NC}"
fi

# Deploy Edge Functions
echo -e "${YELLOW}⚡ Deploying Edge Functions to develop branch...${NC}"
supabase functions deploy --project-ref $DEV_PROJECT_REF --branch $BRANCH_NAME
echo -e "${GREEN}✅ Edge Functions deployed successfully${NC}"

# Set environment variables
echo -e "${YELLOW}🔧 Setting environment variables for develop branch...${NC}"
echo "Note: You'll need to set the actual secret values in Supabase dashboard"
echo "or via GitHub Actions workflow"

# Health check
echo -e "${YELLOW}🏥 Running health checks...${NC}"
DEV_URL="https://$DEV_PROJECT_REF.supabase.co/branches/$BRANCH_NAME"

echo -e "${BLUE}🔗 Testing develop branch URL: $DEV_URL${NC}"

# Test daily-content function
echo -e "${BLUE}Testing daily-content function...${NC}"
response=$(curl -s -w "\n%{http_code}" -X GET $DEV_URL/functions/v1/daily-content)

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ daily-content function is healthy${NC}"
else
    echo -e "${YELLOW}⚠️ daily-content function health check returned HTTP $http_code${NC}"
    echo "Response: $(echo "$response" | head -n -1)"
fi

# Test generate-alarm-audio function
echo -e "${BLUE}Testing generate-alarm-audio function...${NC}"
response=$(curl -s -w "\n%{http_code}" -X GET $DEV_URL/functions/v1/generate-alarm-audio)

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ generate-alarm-audio function is healthy${NC}"
else
    echo -e "${YELLOW}⚠️ generate-alarm-audio function health check returned HTTP $http_code${NC}"
    echo "Response: $(echo "$response" | head -n -1)"
fi

echo -e "${GREEN}🎉 Develop branch setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Set up GitHub secrets (see docs/GITHUB_SECRETS_SETUP.md)"
echo "2. Test the 'Test Environment Secrets' workflow"
echo "3. Run the 'Deploy to Branch' workflow targeting develop"
echo "4. Validate both environments are operational"
echo ""
echo -e "${BLUE}Develop branch URL:${NC} $DEV_URL" 