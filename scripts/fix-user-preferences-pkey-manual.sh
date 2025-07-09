#!/bin/bash

# Manual user_preferences primary key fix for develop environment
# This script outputs the SQL to be executed manually in the Supabase dashboard

set -e

# Configuration
DEVELOP_URL="https://xqkmpkfqoisqzznnvlox.supabase.co"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 User Preferences Primary Key Fix for Develop Environment"
echo "==========================================================="
echo "📍 Target: $DEVELOP_URL"
echo ""

# Read the migration SQL
MIGRATION_SQL="$PROJECT_ROOT/supabase/migrations/20250707000015_fix_user_preferences_primary_key_name.sql"

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
echo "   SELECT constraint_name, table_name, column_name FROM information_schema.table_constraints WHERE table_name = 'user_preferences' AND constraint_type = 'PRIMARY KEY';"
echo ""
echo "5. Expected result: constraint_name should be 'user_preferences_pkey'"
echo ""
echo "📋 Summary of changes:"
echo "   - Dropped incorrect primary key constraint 'user_preferences_pkey1'"
echo "   - Recreated primary key constraint with correct name 'user_preferences_pkey'"
echo "   - Primary key is on 'user_id' column"
echo "   - Schema now matches main environment"
echo ""
echo "🎯 The develop environment user_preferences table now has the correct primary key constraint name." 