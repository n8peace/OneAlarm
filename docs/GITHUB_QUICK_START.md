# GitHub Quick Start Guide

This guide helps you quickly connect to the OneAlarm GitHub repository in new chat sessions.

## 🚀 **Repository Information**

- **Repository**: [n8peace/OneAlarm](https://github.com/n8peace/OneAlarm)
- **Description**: AI-powered alarm clock with personalized content generation
- **Status**: ✅ CI/CD Ready with GitHub Actions
- **Environment**: Development configured, Production pending

## 📋 **Quick Connection Commands**

### **Clone the Repository**
```bash
git clone https://github.com/n8peace/OneAlarm.git
cd OneAlarm
```

### **Check Current Status**
```bash
git status
git branch
git remote -v
```

### **Update from Remote**
```bash
git pull origin main
```

## 🔧 **Environment Setup**

### **Required Environment Variables**
The project uses environment variables for configuration. Key files:
- `scripts/config.sh` - Main configuration file
- `.env` - Local environment variables (not in version control)

### **Development Environment**
Currently configured in GitHub with these secrets:
- `SUPABASE_URL_DEV`
- `SUPABASE_SERVICE_ROLE_KEY_DEV`
- `SUPABASE_DEV_PROJECT_REF`
- `OPENAI_API_KEY_DEV`
- `NEWSAPI_KEY_DEV`
- `SPORTSDB_API_KEY_DEV`
- `RAPIDAPI_KEY_DEV`
- `ABSTRACT_API_KEY_DEV`

## 🏗️ **Project Structure**

```
OneAlarm/
├── .github/workflows/          # CI/CD workflows
│   ├── ci.yml                  # Continuous Integration
│   ├── deploy-dev.yml          # Development deployment
│   ├── deploy-prod.yml         # Production deployment
│   ├── daily-content.yml       # Daily content generation
│   └── cron-migration.yml      # Cron job migration
├── supabase/                   # Supabase configuration
│   ├── functions/              # Edge functions
│   └── migrations/             # Database migrations
├── scripts/                    # Utility scripts
│   ├── config.sh               # Configuration management
│   └── setup-github-env.sh     # GitHub environment setup
└── docs/                       # Documentation
```

## 🔄 **CI/CD Workflows**

### **Available Workflows**
1. **CI** - Runs on every push/PR (testing, validation)
2. **Deploy to Development** - Runs on `develop` branch push
3. **Deploy to Production** - Runs on `main` branch push
4. **Daily Content** - Manual trigger for content generation
5. **Cron Migration** - Scheduled cron job migration

### **Workflow Status**
- ✅ **CI Pipeline** - Working (validates code, checks for issues)
- ✅ **Development Deployment** - Ready (requires environment secrets)
- 🔄 **Production Deployment** - Pending (needs production environment setup)

## 🛠️ **Common Commands**

### **Development**
```bash
# Test the system
./scripts/test-system.sh

# Check system status
./scripts/check-system-status.sh

# Monitor system
./scripts/monitor-system.sh

# Create test user
./scripts/create-test-user.sh

# Create test alarm
./scripts/create-test-alarm.sh
```

### **Deployment**
```bash
# Deploy to development (via GitHub Actions)
git checkout -b develop
git push -u origin develop

# Deploy to production (via GitHub Actions)
git push origin main
```

### **Database**
```bash
# Push database migrations
supabase db push

# Deploy edge functions
supabase functions deploy
```

## 🔐 **Authentication**

### **GitHub CLI**
```bash
# Check authentication
gh auth status

# Login if needed
gh auth login
```

### **Supabase CLI**
```bash
# Install Supabase CLI
curl -fsSL https://supabase.com/install.sh | sh

# Link to project
supabase link --project-ref YOUR_PROJECT_REF
```

## 📊 **Monitoring**

### **GitHub Actions**
- **URL**: https://github.com/n8peace/OneAlarm/actions
- **Status**: Monitor workflow runs and deployments

### **Supabase Dashboard**
- **Development**: [Supabase Dashboard](https://supabase.com/dashboard)
- **Functions**: Monitor edge function logs
- **Database**: Check migrations and data

## 🚨 **Troubleshooting**

### **Common Issues**
1. **CI Failures**: Check Actions tab for specific error messages
2. **Deployment Issues**: Verify environment secrets are set
3. **Database Errors**: Check Supabase dashboard for migration status
4. **Function Errors**: Review edge function logs in Supabase

### **Quick Fixes**
```bash
# Reset local changes
git reset --hard HEAD
git pull origin main

# Clear npm cache (if needed)
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## 📚 **Key Documentation Files**

- `docs/GITHUB_MIGRATION_GUIDE.md` - Complete migration guide
- `docs/CI_CD_IMPLEMENTATION_SCOPE.md` - CI/CD implementation details
- `docs/DATABASE_SCHEMA.md` - Database structure
- `README.md` - Project overview

## 🎯 **Next Steps**

1. **Production Environment**: Set up production Supabase project and GitHub secrets
2. **Cron Migration**: Disable Supabase cron jobs, enable GitHub Actions cron
3. **Monitoring**: Set up alerts and notifications
4. **Testing**: Run end-to-end tests in production environment

---

## 💡 **Pro Tips**

- Always check the **Actions** tab before making changes
- Use **feature branches** for new development
- **Test in development** before deploying to production
- Monitor **Supabase logs** for function errors
- Keep **environment secrets** up to date

---

**Repository**: https://github.com/n8peace/OneAlarm  
**Actions**: https://github.com/n8peace/OneAlarm/actions  
**Issues**: https://github.com/n8peace/OneAlarm/issues 