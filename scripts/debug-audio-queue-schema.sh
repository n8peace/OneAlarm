#!/bin/bash

# Debug script to investigate audio_generation_queue schema issues
# This script will help identify what's requesting the updated_at column

set -e

# Source shared configuration
source ./scripts/config.sh

# Develop environment variables
SUPABASE_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

echo -e "${BLUE}🔍 Debug: Audio Generation Queue Schema Investigation${NC}"
echo "====================================="
echo ""

# Function to check table schema
check_table_schema() {
    local table_name="$1"
    echo -e "${YELLOW}📋 Checking schema for table: $table_name${NC}"
    
    SCHEMA_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/$table_name?select=*&limit=0" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -w "\n%{http_code}")
    
    HTTP_STATUS=$(echo "$SCHEMA_RESPONSE" | tail -n 1)
    SCHEMA_BODY=$(echo "$SCHEMA_RESPONSE" | sed '$d')
    
    echo "HTTP Status: $HTTP_STATUS"
    echo "Response: $SCHEMA_BODY"
    echo ""
}

# Function to check database triggers
check_triggers() {
    echo -e "${YELLOW}🔧 Checking database triggers${NC}"
    
    TRIGGERS_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "query": "SELECT trigger_name, event_manipulation, event_object_table, action_statement FROM information_schema.triggers WHERE event_object_table IN ('\''alarms'\'', '\''audio_generation_queue'\'') ORDER BY trigger_name;"
        }' \
        -w "\n%{http_code}")
    
    HTTP_STATUS=$(echo "$TRIGGERS_RESPONSE" | tail -n 1)
    TRIGGERS_BODY=$(echo "$TRIGGERS_RESPONSE" | sed '$d')
    
    echo "HTTP Status: $HTTP_STATUS"
    echo "Triggers: $TRIGGERS_BODY"
    echo ""
}

# Function to check table columns
check_table_columns() {
    local table_name="$1"
    echo -e "${YELLOW}📊 Checking columns for table: $table_name${NC}"
    
    COLUMNS_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"query\": \"SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = '$table_name' ORDER BY ordinal_position;\"
        }" \
        -w "\n%{http_code}")
    
    HTTP_STATUS=$(echo "$COLUMNS_RESPONSE" | tail -n 1)
    COLUMNS_BODY=$(echo "$COLUMNS_RESPONSE" | sed '$d')
    
    echo "HTTP Status: $HTTP_STATUS"
    echo "Columns: $COLUMNS_BODY"
    echo ""
}

# Function to test alarm creation with detailed error
test_alarm_creation() {
    echo -e "${YELLOW}🧪 Testing alarm creation with detailed error capture${NC}"
    
    # Create a test user first
    USER_DATA='{
        "email": "debug-test@example.com",
        "onboarding_done": true,
        "subscription_status": "trialing"
    }'
    
    USER_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/users" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$USER_DATA")
    
    USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id // empty' 2>/dev/null || echo "")
    
    if [ -n "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
        echo "Created test user: $USER_ID"
        
        # Try to create an alarm and capture the full error
        ALARM_DATA="{
            \"user_id\": \"$USER_ID\",
            \"alarm_date\": \"$(date +%Y-%m-%d)\",
            \"alarm_time_local\": \"$(date +%H:%M:%S)\",
            \"alarm_timezone\": \"America/New_York\",
            \"timezone_at_creation\": \"America/New_York\",
            \"active\": true
        }"
        
        echo "Attempting alarm creation with data: $ALARM_DATA"
        
        ALARM_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/alarms" \
            -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
            -H "apikey: $SERVICE_ROLE_KEY" \
            -H "Content-Type: application/json" \
            -H "Prefer: return=representation" \
            -d "$ALARM_DATA" \
            -w "\n%{http_code}")
        
        HTTP_STATUS=$(echo "$ALARM_RESPONSE" | tail -n 1)
        ALARM_BODY=$(echo "$ALARM_RESPONSE" | sed '$d')
        
        echo "Alarm creation HTTP Status: $HTTP_STATUS"
        echo "Alarm creation Response: $ALARM_BODY"
        echo ""
        
        if [ "$HTTP_STATUS" != "201" ] && [ "$HTTP_STATUS" != "200" ]; then
            echo -e "${RED}❌ Alarm creation failed${NC}"
            echo "This confirms the issue is with alarm creation triggering something that expects updated_at column"
        else
            echo -e "${GREEN}✅ Alarm creation succeeded${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to create test user${NC}"
    fi
}

# Function to check recent migrations
check_migrations() {
    echo -e "${YELLOW}📝 Checking recent migrations${NC}"
    
    MIGRATIONS_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "apikey: $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "query": "SELECT version, name, executed_at FROM supabase_migrations.schema_migrations ORDER BY executed_at DESC LIMIT 10;"
        }' \
        -w "\n%{http_code}")
    
    HTTP_STATUS=$(echo "$MIGRATIONS_RESPONSE" | tail -n 1)
    MIGRATIONS_BODY=$(echo "$MIGRATIONS_RESPONSE" | sed '$d')
    
    echo "HTTP Status: $HTTP_STATUS"
    echo "Recent migrations: $MIGRATIONS_BODY"
    echo ""
}

# Main execution
echo -e "${BLUE}🔍 Starting investigation...${NC}"
echo ""

# Step 1: Check audio_generation_queue table schema
check_table_schema "audio_generation_queue"

# Step 2: Check audio_generation_queue table columns
check_table_columns "audio_generation_queue"

# Step 3: Check alarms table columns
check_table_columns "alarms"

# Step 4: Check database triggers
check_triggers

# Step 5: Check recent migrations
check_migrations

# Step 6: Test alarm creation
test_alarm_creation

echo -e "${BLUE}🔍 Investigation complete!${NC}"
echo "Check the output above to identify what's requesting the updated_at column." 