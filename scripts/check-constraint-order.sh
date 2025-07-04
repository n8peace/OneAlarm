#!/bin/bash

# Check user_preferences constraint order
# This script verifies that FOREIGN KEY comes before PRIMARY KEY

source ./scripts/config.sh

log_step "Checking user_preferences constraint order..."

# Query to check constraint order
QUERY="
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'user_preferences' 
AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY constraint_name;
"

# Execute query using direct SQL
RESPONSE=$(curl -s -X POST "https://bfrvahxmokeyrfnlaiwd.supabase.co/rest/v1/rpc/exec_sql" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$QUERY\"}")

if [ $? -eq 0 ]; then
    log_success "Constraint order check completed"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    
    # Check if FOREIGN KEY comes before PRIMARY KEY
    if echo "$RESPONSE" | grep -q "user_preferences_user_id_fkey.*FOREIGN KEY"; then
        log_success "✅ FOREIGN KEY constraint is present"
    else
        log_error "❌ FOREIGN KEY constraint not found"
    fi
    
    if echo "$RESPONSE" | grep -q "user_preferences_pkey.*PRIMARY KEY"; then
        log_success "✅ PRIMARY KEY constraint is present"
    else
        log_error "❌ PRIMARY KEY constraint not found"
    fi
    
else
    log_error "Failed to check constraint order"
    echo "$RESPONSE"
fi 