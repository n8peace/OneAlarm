#!/bin/bash

# Compare and Sync Triggers between Main and Develop
# This script helps identify differences and create a sync migration

set -e

echo "=== Trigger Comparison and Sync Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Extract triggers from both environments${NC}"
echo ""

echo "To extract triggers from MAIN environment:"
echo "1. Go to your MAIN Supabase project SQL editor"
echo "2. Run the contents of: scripts/extract-main-triggers.sql"
echo "3. Save the output to: scripts/main-triggers-output.sql"
echo ""

echo "To extract triggers from DEVELOP environment:"
echo "1. Go to your DEVELOP Supabase project SQL editor"
echo "2. Run the contents of: scripts/extract-develop-triggers.sql"
echo "3. Save the output to: scripts/develop-triggers-output.sql"
echo ""

echo -e "${YELLOW}Step 2: After extracting, run this script again to compare${NC}"
echo ""

# Check if output files exist
if [ -f "scripts/main-triggers-output.sql" ] && [ -f "scripts/develop-triggers-output.sql" ]; then
    echo -e "${GREEN}Found trigger output files. Proceeding with comparison...${NC}"
    echo ""
    
    echo -e "${YELLOW}Step 3: Creating comparison and sync migration${NC}"
    echo ""
    
    # Create timestamp for migration
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    MIGRATION_FILE="supabase/migrations/${TIMESTAMP}_sync_triggers_main_to_develop.sql"
    
    echo "Creating migration file: $MIGRATION_FILE"
    echo ""
    
    # Create the migration file
    cat > "$MIGRATION_FILE" << 'EOF'
-- Sync Triggers from Main to Develop
-- This migration makes develop triggers match main exactly

-- Drop existing triggers first
DROP TRIGGER IF EXISTS on_preferences_updated ON user_preferences;
DROP TRIGGER IF EXISTS on_preferences_inserted ON user_preferences;

-- Drop existing function
DROP FUNCTION IF EXISTS trigger_audio_generation() CASCADE;

-- TODO: Replace this with the exact function definition from main
-- Copy the function definition from main-triggers-output.sql here
CREATE OR REPLACE FUNCTION trigger_audio_generation()
RETURNS TRIGGER AS $$
-- TODO: Replace with exact main function body
BEGIN
  -- This is a placeholder - replace with actual main function
  RAISE NOTICE 'TODO: Replace with main function definition';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers with exact main definitions
-- TODO: Replace with exact trigger definitions from main
CREATE TRIGGER on_preferences_updated
    AFTER UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

CREATE TRIGGER on_preferences_inserted
    AFTER INSERT ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION trigger_audio_generation();

-- Log the sync
INSERT INTO logs (event_type, meta)
VALUES (
  'trigger_sync',
  jsonb_build_object(
    'action', 'sync_triggers_main_to_develop',
    'source', 'main_environment',
    'target', 'develop_environment',
    'timestamp', NOW(),
    'note', 'TODO: Verify this matches main exactly'
  )
);
EOF

    echo -e "${GREEN}Created migration template: $MIGRATION_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Compare the output files manually:"
    echo "   diff scripts/main-triggers-output.sql scripts/develop-triggers-output.sql"
    echo ""
    echo "2. Update the migration file with the exact main function definition"
    echo "3. Apply the migration to develop environment"
    echo ""
    
    # Show a simple diff if possible
    echo -e "${YELLOW}Quick comparison (function names only):${NC}"
    echo ""
    
    echo "Main triggers:"
    grep -E "(trigger_name|function_name)" scripts/main-triggers-output.sql || echo "No trigger info found"
    echo ""
    
    echo "Develop triggers:"
    grep -E "(trigger_name|function_name)" scripts/develop-triggers-output.sql || echo "No trigger info found"
    echo ""
    
else
    echo -e "${RED}Trigger output files not found.${NC}"
    echo ""
    echo "Please run the extraction scripts first:"
    echo "1. scripts/extract-main-triggers.sql in MAIN environment"
    echo "2. scripts/extract-develop-triggers.sql in DEVELOP environment"
    echo ""
    echo "Then run this script again."
fi

echo -e "${GREEN}Script completed.${NC}" 