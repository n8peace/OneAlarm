# Database Management Guide

This guide covers best practices for managing the OneAlarm database schema, migrations, and preventing sync issues.

## 🎯 Overview

The OneAlarm database uses Supabase with PostgreSQL and follows a migration-based schema management approach. This guide ensures safe database operations and prevents data loss.

## 📋 Pre-Operation Checklist

**Before making ANY database changes, always:**

1. **Check migration status**
   ```bash
   supabase migration list
   ```

2. **Verify database connectivity**
   ```bash
   curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY"
   ```

3. **Check function status**
   ```bash
   supabase functions list
   ```

4. **Review current schema**
   ```bash
   # Check what tables exist
   curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY" | jq '.paths | keys'
   ```

## 🔧 Migration Management

### Understanding Migration Status

**Healthy Status:**
```
Local          | Remote         | Time (UTC)          
----------------|----------------|---------------------
20241201000000 | 20241201000000 | 2024-12-01 00:00:00 
```

**Problematic Status:**
```
Local          | Remote | Time (UTC)          
----------------|--------|---------------------
20241201000000 |        | 2024-12-01 00:00:00 
```

### Safe Migration Operations

**Adding New Migrations:**
```bash
# 1. Create new migration
supabase migration new add_new_feature

# 2. Edit the migration file
# 3. Test locally (if Docker is available)
# 4. Push to remote
supabase db push
```

**Fixing Migration Tracking:**
```bash
# If migrations show as "Local" but not "Remote"
# First, check if the schema actually exists
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY"

# If schema exists, mark migrations as applied
supabase migration repair --status applied <migration_id>

# If schema doesn't exist, mark as reverted
supabase migration repair --status reverted <migration_id>
```

### 🚨 Critical Safety Rules

1. **NEVER run `supabase db push` if migration tracking is out of sync**
2. **ALWAYS verify the current database state before making changes**
3. **BACKUP important data before major schema changes**
4. **TEST migrations in a development environment first**

## 📊 Database Schema Verification

### Checking Current Schema

**List all tables:**
```bash
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" | jq '.paths | keys'
```

**Check specific table structure:**
```bash
# Check users table
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/users?limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

### Schema Validation Scripts

**Quick schema check:**
```bash
#!/bin/bash
# scripts/validate-schema.sh

source .env

echo "🔍 Checking database schema..."

# Check if tables exist
TABLES=$(curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" | jq -r '.paths | keys[]' | grep -v '^/rpc/')

echo "📋 Found tables:"
echo "$TABLES"

# Check migration status
echo ""
echo "📊 Migration status:"
supabase migration list
```

## 🔄 Common Operations

### Safe Schema Updates

**Adding a new column:**
```sql
-- In migration file
ALTER TABLE users ADD COLUMN new_field TEXT;
```

**Adding a new table:**
```sql
-- In migration file
CREATE TABLE new_table (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Adding indexes:**
```sql
-- In migration file
CREATE INDEX idx_users_email ON users(email);
```

### Data Operations

**Safe data updates:**
```sql
-- Always use WHERE clauses
UPDATE users SET status = 'active' WHERE status = 'pending';

-- Use transactions for multiple operations
BEGIN;
UPDATE table1 SET field1 = 'value1';
UPDATE table2 SET field2 = 'value2';
COMMIT;
```

## 🛡️ Security Best Practices

### Row Level Security (RLS)

**Always enable RLS on user data tables:**
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio ENABLE ROW LEVEL SECURITY;
```

**Create proper policies:**
```sql
-- Users can only access their own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid() = id);

-- Service role has full access
CREATE POLICY "Service role full access" ON users
    FOR ALL USING (auth.role() = 'service_role');
```

### API Key Management

**Use environment variables:**
```bash
# .env file
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

**Never commit API keys to version control:**
```bash
# .gitignore
.env
.env.local
.env.production
```

## 📈 Monitoring and Maintenance

### Regular Health Checks

**Daily checks:**
```bash
# Check function status
supabase functions list

# Check migration status
supabase migration list

# Verify database connectivity
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" \
  -H "apikey: $SUPABASE_ANON_KEY" > /dev/null && echo "✅ Database accessible" || echo "❌ Database error"
```

**Weekly checks:**
```bash
# Check for orphaned data
# Review function logs
# Verify RLS policies
# Check storage usage
```

### Performance Monitoring

**Monitor slow queries:**
```sql
-- Check for slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

**Check table sizes:**
```sql
-- Monitor table growth
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY tablename, attname;
```

## 🚨 Emergency Procedures

### Database Recovery

**If migration tracking is completely broken:**
```bash
# 1. Stop all operations
# 2. Document current state
curl -s "https://joyavvleaxqzksopnmjs.supabase.co/rest/v1/" \
  -H "apikey: $SUPABASE_ANON_KEY" > current_schema.json

# 3. Reset migration tracking (if necessary)
supabase migration reset

# 4. Recreate migration history
# 5. Test thoroughly before resuming operations
```

### Data Backup

**Before major changes:**
```bash
# Export critical data
pg_dump $DATABASE_URL --table=users --table=user_preferences > backup_$(date +%Y%m%d).sql

# Or use Supabase dashboard backup feature
```

## 📚 Resources

- [Supabase CLI Documentation](https://supabase.com/docs/guides/cli)
- [PostgreSQL Migration Best Practices](https://www.postgresql.org/docs/current/ddl.html)
- [Supabase Database Management](https://supabase.com/docs/guides/database)

## ✅ Checklist for New Developers

- [ ] Read this guide completely
- [ ] Understand migration tracking
- [ ] Know how to check database status
- [ ] Understand RLS policies
- [ ] Know emergency procedures
- [ ] Test operations in development first

---

**Remember: When in doubt, ask for help before making database changes!** 