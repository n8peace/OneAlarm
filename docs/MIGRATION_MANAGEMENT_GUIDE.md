# Migration Management Guide

## 🎯 Overview

This guide provides comprehensive instructions for managing database migrations in the OneAlarm system, including CI/CD integration and automated deployment workflows.

## 📋 Migration Lifecycle

### **1. Development Phase**
- Create migrations locally
- Test against development environment
- Validate schema changes
- Update TypeScript types

### **2. CI/CD Integration**
- Automated migration validation
- Environment-specific deployments
- Rollback capabilities
- Health check verification

### **3. Production Deployment**
- Zero-downtime migrations
- Backup verification
- Performance monitoring
- Rollback procedures

## 🔧 Migration Commands

### **Local Development**
```bash
# Create new migration
supabase migration new migration_name

# Apply migrations locally
supabase db push

# Reset local database
supabase db reset

# Check migration status
supabase migration list
```

### **CI/CD Workflow**
```bash
# Automated migration deployment
supabase db push --linked

# Validate migration status
supabase migration list

# Health check post-migration
curl -s "https://project.supabase.co/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY"
```

## 🚀 CI/CD Migration Strategy

### **Environment-Specific Deployments**

#### **Development Environment**
```yaml
# .github/workflows/migrate-db.yml
name: Database Migration
on:
  push:
    branches: [develop]
    paths: ['supabase/migrations/**']

jobs:
  migrate-dev:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Dev
        run: |
          supabase link --project-ref ${{ secrets.SUPABASE_DEV_PROJECT_REF }}
          supabase db push
          supabase functions deploy
```

#### **Production Environment**
```yaml
# .github/workflows/migrate-prod.yml
name: Production Migration
on:
  push:
    branches: [main]
    paths: ['supabase/migrations/**']

jobs:
  migrate-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Production
        run: |
          supabase link --project-ref ${{ secrets.SUPABASE_PROD_PROJECT_REF }}
          supabase db push
          supabase functions deploy
```

### **Migration Validation**

#### **Pre-Migration Checks**
```bash
# Validate migration syntax
supabase db lint

# Check for breaking changes
supabase db diff

# Verify environment variables
./scripts/validate-schema.sh
```

#### **Post-Migration Verification**
```bash
# Health check
curl -s "https://project.supabase.co/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY"

# Function deployment verification
supabase functions list

# Database connectivity test
./scripts/test-database-insert.sh
```

## 🔒 Security Considerations

### **Environment Variables**
- **Development**: Use dev-specific API keys
- **Production**: Use production API keys
- **Secrets Management**: Store in GitHub Secrets
- **Access Control**: Limit production access

### **Migration Safety**
- **Backup Before Migration**: Always backup production data
- **Rollback Plan**: Maintain rollback procedures
- **Testing**: Test migrations in dev environment first
- **Monitoring**: Monitor migration execution

## 📊 Migration Tracking

### **Status Monitoring**
```sql
-- Check migration status
SELECT * FROM supabase_migrations.schema_migrations 
ORDER BY version DESC;

-- Verify table existence
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

### **Health Checks**
```bash
# Database connectivity
./scripts/validate-schema.sh

# Function health
curl -s "https://project.supabase.co/functions/v1/generate-audio"

# API endpoints
curl -s "https://project.supabase.co/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY"
```

## ⚠️ Common Issues and Solutions

### **Migration Sync Issues**
```bash
# If migrations are out of sync
supabase migration repair --status applied <migration_id>

# Reset migration tracking
supabase migration repair --status reverted <migration_id>
```

### **Environment Variable Issues**
```bash
# Verify environment variables
supabase secrets list

# Set missing variables
supabase secrets set VARIABLE_NAME=value
```

### **Function Deployment Issues**
```bash
# Redeploy specific function
supabase functions deploy function_name

# Check function logs
supabase functions logs function_name
```

## 🔄 Rollback Procedures

### **Database Rollback**
```bash
# Revert to previous migration
supabase migration repair --status reverted <migration_id>

# Restore from backup
pg_restore -h host -U user -d database backup.sql
```

### **Function Rollback**
```bash
# Deploy previous function version
supabase functions deploy function_name --version <version>

# Check function versions
supabase functions list --version
```

## 📈 Best Practices

### **Migration Development**
1. **Test Locally**: Always test migrations locally first
2. **Small Changes**: Keep migrations small and focused
3. **Backward Compatibility**: Ensure backward compatibility
4. **Documentation**: Document complex migrations

### **CI/CD Integration**
1. **Automated Testing**: Include migration tests in CI/CD
2. **Environment Isolation**: Separate dev/prod environments
3. **Monitoring**: Monitor migration execution
4. **Rollback Ready**: Always have rollback procedures

### **Production Deployment**
1. **Backup First**: Always backup before migration
2. **Low Traffic**: Deploy during low traffic periods
3. **Health Checks**: Verify system health post-migration
4. **Monitoring**: Monitor system performance

## 🛠️ Tools and Scripts

### **Validation Scripts**
- `scripts/validate-schema.sh`: Pre-migration validation
- `scripts/test-database-insert.sh`: Database connectivity test
- `scripts/check-system-status.sh`: System health check

### **Monitoring Scripts**
- `scripts/monitor-system.sh`: System monitoring
- `scripts/check-recent-audio.sh`: Audio generation monitoring
- `scripts/check-system-status.sh`: Overall system status

## 📚 Related Documentation

- [Database Schema](DATABASE_SCHEMA.md)
- [Database Management](DATABASE_MANAGEMENT.md)
- [CI/CD Implementation](../CI_CD_IMPLEMENTATION_SCOPE.md)
- [System Limits](docs/SYSTEM_LIMITS.md)

---

**Last Updated**: January 2025  
**Version**: 2.0  
**Status**: CI/CD Ready 