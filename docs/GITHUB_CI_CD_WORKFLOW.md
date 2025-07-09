# GitHub CI/CD Workflow Documentation

## Overview

This document describes the complete CI/CD pipeline for OneAlarm by SunriseAI, implementing a **GitHub → develop → main** workflow with Supabase GitHub integration for automatic deployments.

## Workflow Architecture

```
Feature Branch → Develop → Main
     ↓            ↓        ↓
   Feature CI   Supabase  Supabase
   (Testing)    (Preview) (Production)
```

## Branch Strategy

### 1. Feature Branches (`feature/*`)
- **Purpose**: Development of new features, bug fixes, and improvements
- **Workflow**: `feature-ci.yml`
- **Triggers**: Push to feature branch, PR to develop
- **Actions**: 
  - Code validation and linting
  - Unit tests
  - Security checks
  - Configuration validation

### 2. Develop Branch
- **Purpose**: Preview environment for testing and integration
- **Workflow**: `deploy-dev.yml` (validation only)
- **Supabase Integration**: Automatic preview deployment
- **Triggers**: Push to develop branch
- **Actions**:
  - Environment variable validation
  - Health checks
  - Integration tests
  - **Supabase automatically deploys to preview environment**

### 3. Main Branch
- **Purpose**: Production environment
- **Workflow**: `deploy-prod.yml` (validation only)
- **Supabase Integration**: Automatic production deployment
- **Triggers**: Push to main branch
- **Actions**:
  - Environment variable validation
  - Production health checks
  - **Supabase automatically deploys to production environment**

## Supabase GitHub Integration

### How It Works
- **Supabase watches your GitHub repository** for branch changes
- **Automatic deployments** happen when you push to `develop` or `main`
- **Preview environments** are created for each branch automatically
- **No manual deployment steps** needed in GitHub Actions

### Environment Mapping
- `develop` branch → Preview environment (for testing)
- `main` branch → Production environment
- Feature branches → Individual preview environments (if configured)

## Workflow Files

### 1. `feature-ci.yml`
**Purpose**: Validate feature branches before merging to develop

**Triggers**:
- Push to `feature/*` branches
- Pull requests to `develop`

**Validation Steps**:
- Node.js dependency installation
- Code linting (if configured)
- Unit tests (if configured)
- Environment configuration validation
- Supabase configuration validation
- Security checks (API key detection)

### 2. `ci.yml`
**Purpose**: General CI for main and develop branches

**Triggers**:
- Push to `main`, `develop`, `feature/*`
- Pull requests to `main`, `develop`

**Validation Steps**:
- Basic environment validation
- Configuration checks
- Security validation

### 3. `deploy-dev.yml`
**Purpose**: Validate development environment (no deployment)

**Triggers**:
- Push to `develop` branch
- Manual workflow dispatch

**Steps**:
- Environment variable validation
- Health checks
- Integration tests
- **No Supabase deployment (handled automatically)**

### 4. `deploy-prod.yml`
**Purpose**: Validate production environment (no deployment)

**Triggers**:
- Push to `main` branch
- Manual workflow dispatch

**Steps**:
- Environment variable validation
- Production health checks
- **No Supabase deployment (handled automatically)**

### 5. `promote-to-production.yml`
**Purpose**: Promote code from develop to main

**Triggers**:
- Manual workflow dispatch only

**Promotion Steps**:
- Validate promotion readiness
- Check for uncommitted changes
- Run production validation tests
- Merge develop into main
- **Supabase automatically deploys to production**

## Environment Configuration

### Required Secrets

#### Development Environment
- `SUPABASE_URL_DEV`
- `SUPABASE_SERVICE_ROLE_KEY_DEV`
- `OPENAI_API_KEY_DEV`
- `NEWSAPI_KEY_DEV`
- `SPORTSDB_API_KEY_DEV`
- `RAPIDAPI_KEY_DEV`
- `ABSTRACT_API_KEY_DEV`
- `SUPABASE_DEV_PROJECT_REF`
- `SUPABASE_ACCESS_TOKEN`

#### Production Environment
- `SUPABASE_URL_PROD`
- `SUPABASE_SERVICE_ROLE_KEY_PROD`
- `OPENAI_API_KEY_PROD`
- `NEWSAPI_KEY_PROD`
- `SPORTSDB_API_KEY_PROD`
- `RAPIDAPI_KEY_PROD`
- `ABSTRACT_API_KEY_PROD`
- `SUPABASE_PROD_PROJECT_REF`
- `SUPABASE_ACCESS_TOKEN`

## Usage Instructions

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "Add new feature"

# Push to trigger CI
git push origin feature/new-feature

# Create PR to develop when ready
```

### 2. Development Testing
```bash
# Merge feature branch to develop
git checkout develop
git merge feature/new-feature
git push origin develop

# Supabase automatically deploys to preview environment
# Check Supabase dashboard for preview URL
```

### 3. Production Deployment
```bash
# Merge develop to main
git checkout main
git merge develop
git push origin main

# Supabase automatically deploys to production
```

### 4. Manual Production Promotion
1. Go to GitHub Actions tab
2. Select "Promote to Production" workflow
3. Click "Run workflow"
4. Fill in:
   - Confirm promotion: `true`
   - Release notes: Description of changes
   - Skip tests: `false` (recommended)
5. Click "Run workflow"

## Branch Protection Rules

### Develop Branch
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Require pull request reviews
- Restrict pushes that create files larger than 100MB

### Main Branch
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Require pull request reviews from code owners
- Restrict direct pushes (only via promotion workflow)
- Require linear history

## Monitoring and Alerts

### Health Checks
- Daily content function availability
- Generate alarm audio function availability
- Database connectivity
- API endpoint responses

### Notifications
- Deployment success/failure notifications
- Health check failures
- Security violations
- Environment variable issues

## Troubleshooting

### Common Issues

1. **Environment Variable Missing**
   - Check GitHub repository secrets
   - Verify secret names match workflow expectations

2. **Supabase Deployment Issues**
   - Check Supabase dashboard for deployment status
   - Verify GitHub integration is properly configured
   - Check Supabase project limits

3. **Health Check Failures**
   - Verify function endpoints are accessible
   - Check authentication tokens
   - Review function logs in Supabase dashboard

### Rollback Procedures

1. **Development Rollback**
   - Revert develop branch to previous commit
   - Push to trigger redeployment

2. **Production Rollback**
   - Use promotion workflow with previous commit
   - Or manually revert main branch
   - Supabase automatically redeploys

## Best Practices

1. **Always test in develop first**
2. **Use meaningful commit messages**
3. **Include release notes for production promotions**
4. **Monitor health checks after deployments**
5. **Keep feature branches small and focused**
6. **Review code before merging to develop**
7. **Test thoroughly before promoting to production**
8. **Use Supabase dashboard to monitor deployments**

## Security Considerations

1. **No API keys in code**
2. **Use environment variables for secrets**
3. **Regular security scans**
4. **Access control via GitHub environments**
5. **Audit trail for all deployments**

## Future Enhancements

1. **Automated testing expansion**
2. **Performance monitoring integration**
3. **Slack/email notifications**
4. **Automated rollback on health check failures**
5. **Database migration automation**
6. **Blue-green deployment strategy** 