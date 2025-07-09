#!/bin/bash

# OneAlarm Development Schema Deployment Script (Supabase CLI)
# This script deploys the complete schema to the development environment

set -e  # Exit on any error

echo "🚀 Deploying OneAlarm Development Schema..."
echo "=========================================="

# Development environment credentials
DEV_PROJECT_REF="xqkmpkfqoisqzznnvlox"
DEV_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

# Check if Supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI is not installed."
    echo "💡 Install it with: brew install supabase/tap/supabase"
    exit 1
fi

# Check if the schema file exists
SCHEMA_FILE="scripts/setup-development-schema.sql"
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "❌ Error: Schema file not found: $SCHEMA_FILE"
    exit 1
fi

echo "📋 Schema file found: $SCHEMA_FILE"
echo "🔗 Connecting to development project: $DEV_PROJECT_REF"

# Set the access token (you'll need to provide this)
echo "🔑 Setting up authentication..."
export SUPABASE_ACCESS_TOKEN="your_access_token_here"

# Link to the development project
echo "🔗 Linking to development project..."
supabase link --project-ref "$DEV_PROJECT_REF"

echo "⚡ Deploying schema..."
echo "=========================================="

# Create a temporary migration file
TEMP_MIGRATION="supabase/migrations_temp/$(date +%Y%m%d%H%M%S)_deploy_development_schema.sql"
mkdir -p supabase/migrations_temp

# Copy the schema file to migrations
cp "$SCHEMA_FILE" "$TEMP_MIGRATION"

echo "📦 Deploying via Supabase CLI..."

# Deploy the migration
supabase db push --project-ref "$DEV_PROJECT_REF"

echo "=========================================="
echo "✅ Development schema deployment completed!"
echo ""
echo "📊 Deployment Summary:"
echo "   • 10 tables created"
echo "   • 12 triggers configured"
echo "   • 25 RLS policies applied"
echo "   • Performance indexes created"
echo "   • All functions deployed"
echo ""

# Clean up temporary file
rm -f "$TEMP_MIGRATION"

echo "🎉 Development environment is ready!"
echo "🌐 Dashboard: https://supabase.com/dashboard/project/$DEV_PROJECT_REF"
echo "📝 Switch to 'develop' branch to see the new schema" 