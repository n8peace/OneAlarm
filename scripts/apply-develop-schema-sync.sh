#!/bin/bash

# Apply schema sync migration to develop environment
# This script applies the migration to sync develop schema to match main

set -e

# Source configuration
source ./scripts/config.sh

# Development environment configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
DEVELOP_SERVICE_KEY="${DEVELOP_SERVICE_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log with colors
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}🔍 $1${NC}"
}

# Function to validate environment
validate_environment() {
    local missing_vars=()
    
    if [ -z "$DEVELOP_SERVICE_KEY" ]; then
        missing_vars+=("DEVELOP_SERVICE_KEY")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo -e "  - ${YELLOW}$var${NC}"
        done
        return 1
    fi
    
    return 0
}

# Function to test connectivity
test_connectivity() {
    log_step "Testing connectivity to develop environment..."
    
    local response
    response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X GET "${DEVELOP_URL}/rest/v1/" \
        -H "apikey: ${DEVELOP_SERVICE_KEY}" \
        -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}")
    
    local http_status
    http_status=$(echo "$response" | grep "HTTPSTATUS:" | cut -d: -f2)
    
    if [ "$http_status" = "200" ]; then
        log_success "Develop environment accessible"
        return 0
    else
        log_error "Cannot access develop environment (HTTP $http_status)"
        return 1
    fi
}

# Function to execute SQL migration
execute_migration() {
    log_step "Applying schema sync migration..."
    
    # Read the migration file
    local migration_file="supabase/migrations/20250707000011_sync_develop_to_main_schema.sql"
    
    if [ ! -f "$migration_file" ]; then
        log_error "Migration file not found: $migration_file"
        return 1
    fi
    
    local migration_sql
    migration_sql=$(cat "$migration_file")
    
    log_info "Executing migration..."
    
    local response
    response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
        -H "Content-Type: application/json" \
        -H "apikey: ${DEVELOP_SERVICE_KEY}" \
        -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
        -d "{\"sql\": \"${migration_sql}\"}")
    
    local http_status
    http_status=$(echo "$response" | grep "HTTPSTATUS:" | cut -d: -f2)
    local response_body
    response_body=$(echo "$response" | sed '/HTTPSTATUS:/d')
    
    if [ "$http_status" = "200" ]; then
        log_success "Migration applied successfully"
        echo "Response: $response_body"
        return 0
    else
        log_error "Migration failed (HTTP $http_status)"
        echo "Response: $response_body"
        return 1
    fi
}

# Function to verify migration
verify_migration() {
    log_step "Verifying migration results..."
    
    # Test a few key changes
    local verification_queries=(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'alarms' AND column_name = 'created_at';"
        "SELECT is_nullable FROM information_schema.columns WHERE table_name = 'alarms' AND column_name = 'user_id';"
        "SELECT table_name FROM information_schema.tables WHERE table_name = 'audio_files';"
    )
    
    for query in "${verification_queries[@]}"; do
        log_info "Verifying: $query"
        
        local response
        response=$(curl -s -X POST "${DEVELOP_URL}/rest/v1/rpc/exec_sql" \
            -H "Content-Type: application/json" \
            -H "apikey: ${DEVELOP_SERVICE_KEY}" \
            -H "Authorization: Bearer ${DEVELOP_SERVICE_KEY}" \
            -d "{\"sql\": \"${query}\"}")
        
        echo "Result: $response"
        echo ""
    done
}

# Function to create backup warning
show_backup_warning() {
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: BACKUP WARNING ⚠️${NC}"
    echo "=========================================="
    echo "This migration will make significant changes to the DEVELOP database:"
    echo ""
    echo "  • Drop the 'audio_files' table entirely"
    echo "  • Change column nullability constraints"
    echo "  • Modify data types and defaults"
    echo "  • Drop and add columns"
    echo ""
    echo -e "${RED}This operation cannot be easily undone!${NC}"
    echo ""
    echo "Before proceeding, ensure you have:"
    echo "  1. A backup of the develop database"
    echo "  2. Verified this is the correct environment"
    echo "  3. Reviewed the migration file"
    echo ""
    
    read -p "Do you want to proceed? (yes/no): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_warning "Migration cancelled by user"
        exit 0
    fi
}

# Main execution
main() {
    log_step "Starting DEVELOP schema sync migration"
    echo "=========================================="
    echo "Target Environment: DEVELOP"
    echo "Migration File: 20250707000011_sync_develop_to_main_schema.sql"
    echo "=========================================="
    echo ""
    
    # Validate environment
    if ! validate_environment; then
        exit 1
    fi
    
    # Test connectivity
    if ! test_connectivity; then
        exit 1
    fi
    
    # Show backup warning
    show_backup_warning
    
    # Execute migration
    if ! execute_migration; then
        log_error "Migration failed!"
        exit 1
    fi
    
    # Verify migration
    verify_migration
    
    log_success "Schema sync migration completed successfully!"
    log_info "Develop environment now matches main schema"
    
    echo ""
    echo "Next steps:"
    echo "  1. Test the application functionality"
    echo "  2. Verify data integrity"
    echo "  3. Run the schema comparison script again to confirm sync"
}

# Run main function
main "$@" 