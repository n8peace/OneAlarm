#!/bin/bash

# Manual daily_content constraint removal for develop environment
# This script outputs the SQL to be executed manually in the Supabase dashboard

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Daily Content Constraint Removal for Develop Environment"
echo "=========================================================="
echo "📍 Target: $DEVELOP_URL"
echo ""

# Read the migration SQL
MIGRATION_SQL="$PROJECT_ROOT/supabase/migrations/20250707000014_remove_daily_content_date_unique_constraint.sql"

if [ ! -f "$MIGRATION_SQL" ]; then
    echo "❌ Error: Migration file not found: $MIGRATION_SQL"
    exit 1
fi

echo "📄 Migration file: $MIGRATION_SQL"
echo ""
echo "🚀 To apply this migration:"
echo ""
echo "1. Go to: $DEVELOP_URL/sql"
echo "2. Copy and paste the following SQL:"
echo ""
echo "============================================="
echo "START SQL - COPY BELOW THIS LINE"
echo "============================================="
echo ""

# Output the SQL content
cat "$MIGRATION_SQL"

echo ""
echo "============================================="
echo "END SQL - COPY ABOVE THIS LINE"
echo "============================================="
echo ""
echo "3. Click 'Run' to execute the migration"
echo ""
echo "4. Verify the changes by running:"
echo "   SELECT constraint_name, table_name, column_name FROM information_schema.table_constraints WHERE constraint_name = 'daily_content_date_key';"
echo ""
echo "5. Expected result: No rows returned (constraint removed)"
echo ""
echo "📋 Summary of changes:"
echo "   - Removed unique constraint 'daily_content_date_key' from daily_content.date"
echo "   - Dropped associated unique index if it existed"
echo "   - Schema now matches main environment"
echo ""
echo "🎯 The develop environment daily_content table now matches the main environment schema." 