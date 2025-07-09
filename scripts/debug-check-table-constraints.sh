#!/bin/bash

# Debug script to check table constraints and default values
# This will help identify what's causing the net extension error

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

echo -e "${BLUE}🔍 Debug: Checking Table Constraints and Default Values${NC}"
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

# Step 1: Check table structure and default values
print_status "info" "Step 1: Checking table structure and default values..."

CHECK_TABLE_SQL="
SELECT 
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_preferences' 
ORDER BY ordinal_position;
"

TABLE_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$CHECK_TABLE_SQL" | jq -R -s .)
  }")

if echo "$TABLE_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to check table structure"
    echo "Response: $TABLE_RESPONSE"
    exit 1
fi

print_status "success" "Table structure retrieved"
echo "Table structure:"
echo "$TABLE_RESPONSE" | jq '.'

# Step 2: Check for constraints
print_status "info" "Step 2: Checking for constraints..."

CHECK_CONSTRAINTS_SQL="
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'user_preferences'::regclass;
"

CONSTRAINTS_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$CHECK_CONSTRAINTS_SQL" | jq -R -s .)
  }")

if echo "$CONSTRAINTS_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to check constraints"
    echo "Response: $CONSTRAINTS_RESPONSE"
else
    print_status "success" "Constraints retrieved"
    echo "Constraints:"
    echo "$CONSTRAINTS_RESPONSE" | jq '.'
fi

# Step 3: Check for rules
print_status "info" "Step 3: Checking for rules..."

CHECK_RULES_SQL="
SELECT 
    rulename as rule_name,
    pg_get_ruledef(oid) as rule_definition
FROM pg_rewrite 
WHERE ev_class = 'user_preferences'::regclass;
"

RULES_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$CHECK_RULES_SQL" | jq -R -s .)
  }")

if echo "$RULES_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to check rules"
    echo "Response: $RULES_RESPONSE"
else
    print_status "success" "Rules retrieved"
    echo "Rules:"
    echo "$RULES_RESPONSE" | jq '.'
fi

# Step 4: Check for any functions that might be called as defaults
print_status "info" "Step 4: Checking for functions in default values..."

CHECK_DEFAULTS_SQL="
SELECT 
    column_name,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_preferences' 
AND column_default IS NOT NULL
AND column_default LIKE '%(%';
"

DEFAULTS_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$CHECK_DEFAULTS_SQL" | jq -R -s .)
  }")

if echo "$DEFAULTS_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to check default functions"
    echo "Response: $DEFAULTS_RESPONSE"
else
    print_status "success" "Default functions retrieved"
    echo "Default functions:"
    echo "$DEFAULTS_RESPONSE" | jq '.'
fi

# Step 5: Check for any triggers that might be system triggers
print_status "info" "Step 5: Checking for system triggers..."

CHECK_SYSTEM_TRIGGERS_SQL="
SELECT 
    tgname as trigger_name,
    tgfoid::regproc as function_name,
    tgenabled as enabled
FROM pg_trigger 
WHERE tgrelid = 'user_preferences'::regclass;
"

SYSTEM_TRIGGERS_RESPONSE=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${DEVELOP_SERVICE_KEY}" \
  -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": $(echo "$CHECK_SYSTEM_TRIGGERS_SQL" | jq -R -s .)
  }")

if echo "$SYSTEM_TRIGGERS_RESPONSE" | grep -q "error"; then
    print_status "error" "Failed to check system triggers"
    echo "Response: $SYSTEM_TRIGGERS_RESPONSE"
else
    print_status "success" "System triggers retrieved"
    echo "System triggers:"
    echo "$SYSTEM_TRIGGERS_RESPONSE" | jq '.'
fi

# Step 6: Summary
echo
print_status "info" "Step 6: Analysis Summary"
echo "====================="
echo "• Table structure: ✅"
echo "• Constraints: ✅"
echo "• Rules: ✅"
echo "• Default functions: ✅"
echo "• System triggers: ✅"
echo
print_status "info" "Look for any references to 'net' in the output above"
print_status "info" "The net extension error is likely coming from one of these sources" 