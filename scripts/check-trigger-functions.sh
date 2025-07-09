#!/bin/bash

# Check trigger_audio_generation function in both environments
# This script connects to both databases and extracts the actual function definitions

echo "=== CHECKING TRIGGER FUNCTIONS IN BOTH ENVIRONMENTS ==="
echo

# Main environment (joyavvleaxqzksopnmjs)
echo "🔍 MAIN ENVIRONMENT (joyavvleaxqzksopnmjs)"
echo "=========================================="

# Check if we can connect to main
echo "Checking main environment function definition..."
echo "SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'trigger_audio_generation';" | \
psql "postgresql://postgres:[YOUR_MAIN_PASSWORD]@db.joyavvleaxqzksopnmjs.supabase.co:5432/postgres" 2>/dev/null || \
echo "❌ Cannot connect to main environment (need password)"

echo

# Develop environment (xqkmpkfqoisqzznnvlox)
echo "🔍 DEVELOP ENVIRONMENT (xqkmpkfqoisqzznnvlox)"
echo "============================================="

# Check if we can connect to develop
echo "Checking develop environment function definition..."
echo "SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'trigger_audio_generation';" | \
psql "postgresql://postgres:[YOUR_DEVELOP_PASSWORD]@db.xqkmpkfqoisqzznnvlox.supabase.co:5432/postgres" 2>/dev/null || \
echo "❌ Cannot connect to develop environment (need password)"

echo

echo "=== ALTERNATIVE: CHECK TRIGGERS ==="
echo

# Check triggers instead
echo "🔍 MAIN ENVIRONMENT TRIGGERS"
echo "SELECT trigger_name, event_manipulation, action_statement FROM information_schema.triggers WHERE trigger_name LIKE '%preferences%';" | \
psql "postgresql://postgres:[YOUR_MAIN_PASSWORD]@db.joyavvleaxqzksopnmjs.supabase.co:5432/postgres" 2>/dev/null || \
echo "❌ Cannot connect to main environment"

echo

echo "🔍 DEVELOP ENVIRONMENT TRIGGERS"
echo "SELECT trigger_name, event_manipulation, action_statement FROM information_schema.triggers WHERE trigger_name LIKE '%preferences%';" | \
psql "postgresql://postgres:[YOUR_DEVELOP_PASSWORD]@db.xqkmpkfqoisqzznnvlox.supabase.co:5432/postgres" 2>/dev/null || \
echo "❌ Cannot connect to develop environment"

echo
echo "=== NOTE ==="
echo "To use this script, replace [YOUR_MAIN_PASSWORD] and [YOUR_DEVELOP_PASSWORD] with actual database passwords" 