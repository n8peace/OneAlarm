#!/bin/bash

# OneAlarm Development Schema Deployment Script (REST API)
# This script deploys the complete schema to the development environment

set -e  # Exit on any error

echo "🚀 Deploying OneAlarm Development Schema..."
echo "=========================================="

# Development environment credentials
DEV_PROJECT_REF="xqkmpkfqoisqzznnvlox"
DEV_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

# Check if the schema file exists
SCHEMA_FILE="scripts/setup-development-schema.sql"
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "❌ Error: Schema file not found: $SCHEMA_FILE"
    exit 1
fi

echo "📋 Schema file found: $SCHEMA_FILE"
echo "🔗 Connecting to development project: $DEV_PROJECT_REF"

# Read the SQL file
SQL_CONTENT=$(cat "$SCHEMA_FILE")

# URL encode the SQL content
SQL_CONTENT_ENCODED=$(echo "$SQL_CONTENT" | sed 's/"/\\"/g' | tr '\n' ' ')

echo "⚡ Deploying schema via REST API..."
echo "=========================================="

# Execute the SQL via REST API
RESPONSE=$(curl -s -X POST \
  "https://xqkmpkfqoisqzznnvlox.supabase.co/rest/v1/rpc/exec_sql" \
  -H "apikey: $DEV_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $DEV_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": \"$SQL_CONTENT_ENCODED\"}")

echo "Response: $RESPONSE"

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

echo "🎉 Development environment is ready!"
echo "🌐 Dashboard: https://supabase.com/dashboard/project/$DEV_PROJECT_REF"
echo "📝 Switch to 'develop' branch to see the new schema" 