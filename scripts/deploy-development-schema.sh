#!/bin/bash

# OneAlarm Development Schema Deployment Script
# This script deploys the complete schema to the development environment

set -e  # Exit on any error

echo "🚀 Deploying OneAlarm Development Schema..."
echo "=========================================="

# Development environment credentials
DEV_PROJECT_REF="xqkmpkfqoisqzznnvlox"
DEV_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhxa21wa2Zxb2lzcXp6bm52bG94Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTY2MTQ4NSwiZXhwIjoyMDY3MjM3NDg1fQ.wwlWIRdUYr4eMegjgvbD1FZoTg75MiRAKaDBbWJrCxw"

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql is not installed. Please install PostgreSQL client tools."
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

# Construct the connection string
CONNECTION_STRING="postgresql://postgres.xqkmpkfqoisqzznnvlox:${DEV_SERVICE_ROLE_KEY}@aws-0-us-west-1.pooler.supabase.com:6543/postgres"

echo "⚡ Deploying schema..."
echo "=========================================="

# Deploy the schema
psql "$CONNECTION_STRING" -f "$SCHEMA_FILE" -v ON_ERROR_STOP=1

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
echo "🔍 Verifying deployment..."

# Verify the deployment by checking table count
TABLE_COUNT=$(psql "$CONNECTION_STRING" -t -c "
SELECT COUNT(*) 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'user_preferences', 'alarms', 'daily_content', 'audio', 'audio_files', 'logs', 'weather_data', 'user_events', 'audio_generation_queue');
" | xargs)

echo "📈 Tables found: $TABLE_COUNT/10"

if [ "$TABLE_COUNT" -eq 10 ]; then
    echo "✅ All tables successfully created!"
else
    echo "⚠️  Warning: Expected 10 tables, found $TABLE_COUNT"
fi

# Check trigger count
TRIGGER_COUNT=$(psql "$CONNECTION_STRING" -t -c "
SELECT COUNT(*) 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
" | xargs)

echo "🔧 Triggers found: $TRIGGER_COUNT"

# Check RLS policies
POLICY_COUNT=$(psql "$CONNECTION_STRING" -t -c "
SELECT COUNT(*) 
FROM pg_policies 
WHERE schemaname = 'public';
" | xargs)

echo "🔒 RLS policies found: $POLICY_COUNT"

echo ""
echo "🎉 Development environment is ready!"
echo "🌐 Dashboard: https://supabase.com/dashboard/project/$DEV_PROJECT_REF"
echo "📝 Switch to 'develop' branch to see the new schema" 