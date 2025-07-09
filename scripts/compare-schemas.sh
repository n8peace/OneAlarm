#!/bin/bash

# Compare database schemas between main and develop environments
# This script extracts schema information from both environments and provides a detailed comparison

set -e

# Source configuration
source ./scripts/config.sh

# Development environment URLs and keys
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
    
    if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
        missing_vars+=("SUPABASE_SERVICE_ROLE_KEY")
    fi
    
    if [ -z "$DEVELOP_SERVICE_KEY" ]; then
        missing_vars+=("DEVELOP_SERVICE_KEY")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo -e "  - ${YELLOW}$var${NC}"
        done
        echo ""
        log_info "Please set these variables in your .env file or environment:"
        echo "  SUPABASE_SERVICE_ROLE_KEY=your-main-service-role-key"
        echo "  DEVELOP_SERVICE_KEY=your-develop-service-role-key"
        return 1
    fi
    
    return 0
}

# Function to execute SQL and get results
execute_sql() {
    local url="$1"
    local service_key="$2"
    local sql_query="$3"
    
    curl -s -X POST "${url}/rest/v1/rpc/exec_sql" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${service_key}" \
        -d "{\"sql\": \"${sql_query}\"}" | jq -r '.result // .'
}

# Function to extract schema information
extract_schema() {
    local url="$1"
    local service_key="$2"
    local env_name="$3"
    local output_dir="$4"
    
    log_step "Extracting schema from ${env_name} environment..."
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # SQL queries to extract schema information
    local queries=(
        "tables:SELECT schemaname, tablename, tableowner FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"
        "columns:SELECT t.table_name, c.column_name, c.data_type, c.is_nullable, c.column_default, c.character_maximum_length, c.numeric_precision, c.numeric_scale FROM information_schema.tables t JOIN information_schema.columns c ON t.table_name = c.table_name WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE' AND c.table_schema = 'public' ORDER BY t.table_name, c.ordinal_position;"
        "foreign_keys:SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table_name, ccu.column_name AS foreign_column_name FROM information_schema.table_constraints AS tc JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public' ORDER BY tc.table_name, kcu.column_name;"
        "indexes:SELECT schemaname, tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;"
        "constraints:SELECT tc.table_name, tc.constraint_name, tc.constraint_type, kcu.column_name, cc.check_clause FROM information_schema.table_constraints tc LEFT JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name WHERE tc.table_schema = 'public' ORDER BY tc.table_name, tc.constraint_name;"
    )
    
    for query_info in "${queries[@]}"; do
        IFS=':' read -r query_type sql_query <<< "$query_info"
        log_info "Extracting ${query_type} from ${env_name}..."
        
        local result
        result=$(execute_sql "$url" "$service_key" "$sql_query")
        
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            echo "$result" > "${output_dir}/${env_name}_${query_type}.json"
            log_success "Extracted ${query_type} from ${env_name}"
        else
            log_error "Failed to extract ${query_type} from ${env_name}"
            echo "[]" > "${output_dir}/${env_name}_${query_type}.json"
        fi
    done
}

# Function to compare schemas
compare_schemas() {
    local main_dir="$1"
    local develop_dir="$2"
    
    log_step "Comparing schemas..."
    
    echo "=========================================="
    echo "SCHEMA COMPARISON: MAIN vs DEVELOP"
    echo "=========================================="
    echo ""
    
    # Compare tables
    compare_tables "$main_dir" "$develop_dir"
    
    # Compare columns
    compare_columns "$main_dir" "$develop_dir"
    
    # Compare foreign keys
    compare_foreign_keys "$main_dir" "$develop_dir"
    
    # Compare indexes
    compare_indexes "$main_dir" "$develop_dir"
    
    # Compare constraints
    compare_constraints "$main_dir" "$develop_dir"
}

# Function to compare tables
compare_tables() {
    local main_dir="$1"
    local develop_dir="$2"
    
    echo "📋 TABLE COMPARISON"
    echo "=================="
    
    local main_tables=$(jq -r '.[] | .tablename' "${main_dir}/main_tables.json" 2>/dev/null | sort)
    local develop_tables=$(jq -r '.[] | .tablename' "${develop_dir}/develop_tables.json" 2>/dev/null | sort)
    
    # Find missing tables
    local missing_in_develop=$(comm -23 <(echo "$main_tables") <(echo "$develop_tables"))
    local missing_in_main=$(comm -13 <(echo "$main_tables") <(echo "$develop_tables"))
    
    if [ -n "$missing_in_develop" ]; then
        echo -e "${RED}❌ Tables missing in DEVELOP:${NC}"
        echo "$missing_in_develop" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -n "$missing_in_main" ]; then
        echo -e "${YELLOW}⚠️  Tables extra in DEVELOP:${NC}"
        echo "$missing_in_main" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -z "$missing_in_develop" ] && [ -z "$missing_in_main" ]; then
        echo -e "${GREEN}✅ All tables match between environments${NC}"
    fi
    echo ""
}

# Function to compare columns
compare_columns() {
    local main_dir="$1"
    local develop_dir="$2"
    
    echo "📊 COLUMN COMPARISON"
    echo "==================="
    
    # Get all unique table names from both environments
    local all_tables=$(jq -r '.[] | .tablename' "${main_dir}/main_tables.json" "${develop_dir}/develop_tables.json" 2>/dev/null | sort -u)
    
    for table in $all_tables; do
        local main_columns=$(jq -r ".[] | select(.table_name == \"$table\") | \"\\(.column_name):\\(.data_type):\\(.is_nullable):\\(.column_default // \"NULL\")\"" "${main_dir}/main_columns.json" 2>/dev/null | sort)
        local develop_columns=$(jq -r ".[] | select(.table_name == \"$table\") | \"\\(.column_name):\\(.data_type):\\(.is_nullable):\\(.column_default // \"NULL\")\"" "${develop_dir}/develop_columns.json" 2>/dev/null | sort)
        
        # Find differences
        local missing_in_develop=$(comm -23 <(echo "$main_columns") <(echo "$develop_columns"))
        local missing_in_main=$(comm -13 <(echo "$main_columns") <(echo "$develop_columns"))
        
        if [ -n "$missing_in_develop" ] || [ -n "$missing_in_main" ]; then
            echo -e "${YELLOW}Table: $table${NC}"
            
            if [ -n "$missing_in_develop" ]; then
                echo -e "  ${RED}Missing in DEVELOP:${NC}"
                echo "$missing_in_develop" | sed 's/^/    - /'
            fi
            
            if [ -n "$missing_in_main" ]; then
                echo -e "  ${BLUE}Extra in DEVELOP:${NC}"
                echo "$missing_in_main" | sed 's/^/    - /'
            fi
            echo ""
        fi
    done
    
    # Check for tables that exist in one environment but not the other
    local main_only_tables=$(comm -23 <(jq -r '.[] | .tablename' "${main_dir}/main_tables.json" 2>/dev/null | sort) <(jq -r '.[] | .tablename' "${develop_dir}/develop_tables.json" 2>/dev/null | sort))
    local develop_only_tables=$(comm -13 <(jq -r '.[] | .tablename' "${main_dir}/main_tables.json" 2>/dev/null | sort) <(jq -r '.[] | .tablename' "${develop_dir}/develop_tables.json" 2>/dev/null | sort))
    
    if [ -n "$main_only_tables" ]; then
        echo -e "${RED}Tables only in MAIN (no column comparison possible):${NC}"
        echo "$main_only_tables" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -n "$develop_only_tables" ]; then
        echo -e "${BLUE}Tables only in DEVELOP (no column comparison possible):${NC}"
        echo "$develop_only_tables" | sed 's/^/  - /'
        echo ""
    fi
}

# Function to compare foreign keys
compare_foreign_keys() {
    local main_dir="$1"
    local develop_dir="$2"
    
    echo "🔗 FOREIGN KEY COMPARISON"
    echo "========================"
    
    local main_fks=$(jq -r '.[] | "\(.table_name):\(.column_name):\(.foreign_table_name):\(.foreign_column_name)"' "${main_dir}/main_foreign_keys.json" 2>/dev/null | sort)
    local develop_fks=$(jq -r '.[] | "\(.table_name):\(.column_name):\(.foreign_table_name):\(.foreign_column_name)"' "${develop_dir}/develop_foreign_keys.json" 2>/dev/null | sort)
    
    local missing_in_develop=$(comm -23 <(echo "$main_fks") <(echo "$develop_fks"))
    local missing_in_main=$(comm -13 <(echo "$main_fks") <(echo "$develop_fks"))
    
    if [ -n "$missing_in_develop" ]; then
        echo -e "${RED}❌ Foreign keys missing in DEVELOP:${NC}"
        echo "$missing_in_develop" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -n "$missing_in_main" ]; then
        echo -e "${YELLOW}⚠️  Foreign keys extra in DEVELOP:${NC}"
        echo "$missing_in_main" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -z "$missing_in_develop" ] && [ -z "$missing_in_main" ]; then
        echo -e "${GREEN}✅ All foreign keys match between environments${NC}"
    fi
    echo ""
}

# Function to compare indexes
compare_indexes() {
    local main_dir="$1"
    local develop_dir="$2"
    
    echo "📈 INDEX COMPARISON"
    echo "=================="
    
    local main_indexes=$(jq -r '.[] | "\(.tablename):\(.indexname)"' "${main_dir}/main_indexes.json" 2>/dev/null | sort)
    local develop_indexes=$(jq -r '.[] | "\(.tablename):\(.indexname)"' "${develop_dir}/develop_indexes.json" 2>/dev/null | sort)
    
    local missing_in_develop=$(comm -23 <(echo "$main_indexes") <(echo "$develop_indexes"))
    local missing_in_main=$(comm -13 <(echo "$main_indexes") <(echo "$develop_indexes"))
    
    if [ -n "$missing_in_develop" ]; then
        echo -e "${RED}❌ Indexes missing in DEVELOP:${NC}"
        echo "$missing_in_develop" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -n "$missing_in_main" ]; then
        echo -e "${YELLOW}⚠️  Indexes extra in DEVELOP:${NC}"
        echo "$missing_in_main" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -z "$missing_in_develop" ] && [ -z "$missing_in_main" ]; then
        echo -e "${GREEN}✅ All indexes match between environments${NC}"
    fi
    echo ""
}

# Function to compare constraints
compare_constraints() {
    local main_dir="$1"
    local develop_dir="$2"
    
    echo "🔒 CONSTRAINT COMPARISON"
    echo "======================="
    
    local main_constraints=$(jq -r '.[] | "\(.table_name):\(.constraint_name):\(.constraint_type)"' "${main_dir}/main_constraints.json" 2>/dev/null | sort)
    local develop_constraints=$(jq -r '.[] | "\(.table_name):\(.constraint_name):\(.constraint_type)"' "${develop_dir}/develop_constraints.json" 2>/dev/null | sort)
    
    local missing_in_develop=$(comm -23 <(echo "$main_constraints") <(echo "$develop_constraints"))
    local missing_in_main=$(comm -13 <(echo "$main_constraints") <(echo "$develop_constraints"))
    
    if [ -n "$missing_in_develop" ]; then
        echo -e "${RED}❌ Constraints missing in DEVELOP:${NC}"
        echo "$missing_in_develop" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -n "$missing_in_main" ]; then
        echo -e "${YELLOW}⚠️  Constraints extra in DEVELOP:${NC}"
        echo "$missing_in_main" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -z "$missing_in_develop" ] && [ -z "$missing_in_main" ]; then
        echo -e "${GREEN}✅ All constraints match between environments${NC}"
    fi
    echo ""
}

# Function to generate summary report
generate_summary() {
    local main_dir="$1"
    local develop_dir="$2"
    
    echo "=========================================="
    echo "SUMMARY REPORT"
    echo "=========================================="
    
    local main_table_count=$(jq '. | length' "${main_dir}/main_tables.json" 2>/dev/null || echo "0")
    local develop_table_count=$(jq '. | length' "${develop_dir}/develop_tables.json" 2>/dev/null || echo "0")
    
    local main_column_count=$(jq '. | length' "${main_dir}/main_columns.json" 2>/dev/null || echo "0")
    local develop_column_count=$(jq '. | length' "${develop_dir}/develop_columns.json" 2>/dev/null || echo "0")
    
    local main_fk_count=$(jq '. | length' "${main_dir}/main_foreign_keys.json" 2>/dev/null || echo "0")
    local develop_fk_count=$(jq '. | length' "${develop_dir}/develop_foreign_keys.json" 2>/dev/null || echo "0")
    
    local main_index_count=$(jq '. | length' "${main_dir}/main_indexes.json" 2>/dev/null || echo "0")
    local develop_index_count=$(jq '. | length' "${develop_dir}/develop_indexes.json" 2>/dev/null || echo "0")
    
    local main_constraint_count=$(jq '. | length' "${main_dir}/main_constraints.json" 2>/dev/null || echo "0")
    local develop_constraint_count=$(jq '. | length' "${develop_dir}/develop_constraints.json" 2>/dev/null || echo "0")
    
    echo "MAIN Environment:"
    echo "  - Tables: $main_table_count"
    echo "  - Columns: $main_column_count"
    echo "  - Foreign Keys: $main_fk_count"
    echo "  - Indexes: $main_index_count"
    echo "  - Constraints: $main_constraint_count"
    echo ""
    
    echo "DEVELOP Environment:"
    echo "  - Tables: $develop_table_count"
    echo "  - Columns: $develop_column_count"
    echo "  - Foreign Keys: $develop_fk_count"
    echo "  - Indexes: $develop_index_count"
    echo "  - Constraints: $develop_constraint_count"
    echo ""
    
    # Calculate differences
    local table_diff=$((main_table_count - develop_table_count))
    local column_diff=$((main_column_count - develop_column_count))
    local fk_diff=$((main_fk_count - develop_fk_count))
    local index_diff=$((main_index_count - develop_index_count))
    local constraint_diff=$((main_constraint_count - develop_constraint_count))
    
    if [ $table_diff -ne 0 ] || [ $column_diff -ne 0 ] || [ $fk_diff -ne 0 ] || [ $index_diff -ne 0 ] || [ $constraint_diff -ne 0 ]; then
        echo -e "${YELLOW}DIFFERENCES DETECTED:${NC}"
        [ $table_diff -ne 0 ] && echo "  - Tables: $table_diff"
        [ $column_diff -ne 0 ] && echo "  - Columns: $column_diff"
        [ $fk_diff -ne 0 ] && echo "  - Foreign Keys: $fk_diff"
        [ $index_diff -ne 0 ] && echo "  - Indexes: $index_diff"
        [ $constraint_diff -ne 0 ] && echo "  - Constraints: $constraint_diff"
    else
        echo -e "${GREEN}✅ No differences detected in schema counts${NC}"
    fi
}

# Main execution
main() {
    log_step "Starting schema comparison between MAIN and DEVELOP environments"
    
    # Validate environment
    if ! validate_environment; then
        exit 1
    fi
    
    # Create temporary directories for schema dumps
    local temp_dir=$(mktemp -d)
    local main_dir="${temp_dir}/main"
    local develop_dir="${temp_dir}/develop"
    
    log_info "Using temporary directory: $temp_dir"
    
    # Extract schemas
    extract_schema "$SUPABASE_URL" "$SUPABASE_SERVICE_ROLE_KEY" "main" "$main_dir"
    extract_schema "$DEVELOP_URL" "$DEVELOP_SERVICE_KEY" "develop" "$develop_dir"
    
    # Compare schemas
    compare_schemas "$main_dir" "$develop_dir"
    
    # Generate summary
    generate_summary "$main_dir" "$develop_dir"
    
    log_success "Schema comparison completed!"
    log_info "Schema dumps saved in: $temp_dir"
    log_info "You can review the detailed JSON files for more information"
    
    echo ""
    echo "Files generated:"
    echo "  $main_dir/main_*.json"
    echo "  $develop_dir/develop_*.json"
}

# Run main function
main "$@" 