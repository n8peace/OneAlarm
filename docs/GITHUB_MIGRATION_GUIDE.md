# GitHub Migration Guide

This guide walks you through migrating the OneAlarm project to GitHub for CI/CD implementation.

## 📋 **Prerequisites**

Before starting the migration, ensure you have:

- [ ] GitHub account with appropriate permissions
- [ ] GitHub CLI installed and authenticated (`gh auth login`)
- [ ] Supabase CLI installed (`npm install -g supabase@latest`)
- [ ] Access to both development and production Supabase projects
- [ ] All API keys and environment variables ready

## 🚀 **Step 1: Create GitHub Repository**

### Option A: Using GitHub CLI (Recommended)

```bash
# Create the repository
gh repo create OneAlarm --public --description "AI-powered alarm clock with personalized content"

# Clone the repository
git clone https://github.com/YOUR_USERNAME/OneAlarm.git
cd OneAlarm
```

### Option B: Using GitHub Web Interface

1. Go to [GitHub](https://github.com)
2. Click "New repository"
3. Name: `OneAlarm`
4. Description: `AI-powered alarm clock with personalized content`
5. Make it Public
6. Don't initialize with README (we'll push our existing code)
7. Click "Create repository"

## 🔧 **Step 2: Initialize Local Repository**

```bash
# Navigate to your project directory
cd "OneAlarm by SunriseAI"

# Initialize Git (if not already done)
git init

# Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/OneAlarm.git

# Create and switch to main branch
git checkout -b main
```

## 📦 **Step 3: Prepare Code for Migration**

The following files have been created/updated for CI/CD readiness:

### GitHub Workflows
- `.github/workflows/ci.yml` - Continuous Integration
- `.github/workflows/deploy-dev.yml` - Development Deployment
- `.github/workflows/deploy-prod.yml` - Production Deployment
- `.github/workflows/daily-content.yml` - Daily Content Generation
- `.github/workflows/cron-migration.yml` - Cron Job Migration

### Templates and Configuration
- `.github/ISSUE_TEMPLATE/` - Issue templates for bugs, features, and deployment issues
- `.github/pull_request_template.md` - PR template
- `.github/CODEOWNERS` - Code ownership rules
- `.github/dependabot.yml` - Automated dependency updates

### Scripts
- `scripts/setup-github-env.sh` - Automated GitHub environment setup

## 🔐 **Step 4: Set Up GitHub Environments**

### Automated Setup (Recommended)

```bash
# Run the automated setup script
./scripts/setup-github-env.sh
```

This script will:
- Create development and production environments
- Prompt for environment variables
- Set up GitHub secrets
- Create initial commit and push

### Manual Setup

If you prefer manual setup:

1. **Create Environments**
   - Go to Repository Settings > Environments
   - Create "development" environment
   - Create "production" environment
   - Set protection rules requiring your review

2. **Set Environment Secrets**
   - For each environment, add the following secrets:

#### Development Environment Secrets
```
SUPABASE_URL_DEV=https://your-dev-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY_DEV=your-dev-service-role-key
SUPABASE_DEV_PROJECT_REF=your-dev-project-ref
OPENAI_API_KEY_DEV=your-dev-openai-key
NEWSAPI_KEY_DEV=your-dev-newsapi-key
SPORTSDB_API_KEY_DEV=your-dev-sportsdb-key
RAPIDAPI_KEY_DEV=your-dev-rapidapi-key
ABSTRACT_API_KEY_DEV=your-dev-abstract-key
```

#### Production Environment Secrets
```
SUPABASE_URL_PROD=https://your-prod-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY_PROD=your-prod-service-role-key
SUPABASE_PROD_PROJECT_REF=your-prod-project-ref
OPENAI_API_KEY_PROD=your-prod-openai-key
NEWSAPI_KEY_PROD=your-prod-newsapi-key
SPORTSDB_API_KEY_PROD=your-prod-sportsdb-key
RAPIDAPI_KEY_PROD=your-prod-rapidapi-key
ABSTRACT_API_KEY_PROD=your-prod-abstract-key
```

## 📤 **Step 5: Push Code to GitHub**

```bash
# Add all files
git add .

# Create initial commit
git commit -m "feat: Initial CI/CD setup

- Add GitHub Actions workflows for CI, deployment, and cron jobs
- Add issue and PR templates
- Add CODEOWNERS and Dependabot configuration
- Standardize environment configuration
- Remove hardcoded URLs from scripts"

# Push to GitHub
git push -u origin main
```

## 🧪 **Step 6: Test CI/CD Pipeline**

### Test CI Workflow
1. Make a small change to any file
2. Commit and push
3. Check GitHub Actions tab to verify CI passes

### Test Development Deployment
1. Create a new branch: `git checkout -b develop`
2. Make changes and push: `git push -u origin develop`
3. Verify development deployment workflow runs

### Test Manual Workflows
1. Go to Actions tab
2. Select "Deploy to Development" or "Deploy to Production"
3. Click "Run workflow" to test manual deployment

## 🔄 **Step 7: Migrate Cron Jobs**

### Disable Supabase Cron Jobs
1. Go to Supabase Dashboard > Database > Functions
2. Disable the following cron jobs:
   - `daily-content-generation`
   - `cleanup-audio-files`
   - `check-triggers`

### Enable GitHub Actions Cron
The cron jobs are now handled by:
- `.github/workflows/cron-migration.yml` - Daily content at 2 AM UTC
- `.github/workflows/daily-content.yml` - Manual triggers

## 📊 **Step 8: Monitor and Verify**

### Check Deployment Status
- Monitor GitHub Actions for successful deployments
- Verify functions are accessible in both environments
- Test health checks manually

### Verify Environment Variables
```bash
# Test development environment
curl -X GET https://your-dev-project.supabase.co/functions/v1/daily-content \
  -H "Authorization: Bearer your-dev-service-role-key"

# Test production environment
curl -X GET https://your-prod-project.supabase.co/functions/v1/daily-content \
  -H "Authorization: Bearer your-prod-service-role-key"
```

## 🔧 **Step 9: Configure Branch Protection**

1. Go to Repository Settings > Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date
   - Include administrators

3. Add rule for `develop` branch:
   - Require pull request reviews
   - Require status checks to pass

## 📈 **Step 10: Set Up Monitoring**

### GitHub Actions Monitoring
- Enable notifications for workflow failures
- Set up email/Slack notifications for deployments

### Supabase Monitoring
- Monitor function logs in Supabase Dashboard
- Set up alerts for function failures
- Monitor database performance

## 🚨 **Troubleshooting**

### Common Issues

#### Environment Variables Not Set
```bash
# Check if secrets are set
gh secret list --env development
gh secret list --env production
```

#### Deployment Failures
1. Check GitHub Actions logs
2. Verify Supabase project references
3. Ensure API keys are valid
4. Check function permissions

#### Cron Job Issues
1. Verify cron schedule in workflow file
2. Check function endpoints are accessible
3. Monitor function logs in Supabase

### Rollback Procedure
1. Revert to previous commit: `git revert HEAD`
2. Push changes: `git push origin main`
3. Manual rollback in Supabase if needed

## 📚 **Additional Resources**

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Supabase CLI Documentation](https://supabase.com/docs/reference/cli)
- [Environment Variables Best Practices](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## ✅ **Migration Checklist**

- [ ] GitHub repository created
- [ ] Local repository initialized and connected
- [ ] All CI/CD files committed
- [ ] GitHub environments created
- [ ] Environment secrets configured
- [ ] Initial code push completed
- [ ] CI workflow tested
- [ ] Development deployment tested
- [ ] Production deployment tested
- [ ] Cron jobs migrated
- [ ] Branch protection configured
- [ ] Monitoring set up
- [ ] Team access configured
- [ ] Documentation updated

## 🎉 **Migration Complete!**

Your OneAlarm project is now fully migrated to GitHub with comprehensive CI/CD capabilities. The system includes:

- ✅ Automated testing and validation
- ✅ Multi-environment deployment
- ✅ Automated cron job migration
- ✅ Security and monitoring
- ✅ Issue and PR templates
- ✅ Automated dependency updates

The project is now ready for collaborative development and production deployment! 