# Branch Management Guide

## 🎯 Overview

This guide covers the management of Supabase branches for the OneAlarm project, including creation, switching, merging, and cleanup procedures.

## 🏗️ Branch Strategy

### **Branch Types**
```
main (Production)
├── Purpose: Live production environment
├── Deployments: Manual approval required
├── Cron Jobs: Full schedule enabled
└── Data: Production user data

develop (Staging)
├── Purpose: Integration testing
├── Deployments: Automated from develop branch
├── Cron Jobs: Reduced frequency
└── Data: Test data only

feature/* (Feature Development)
├── Purpose: Feature development and testing
├── Deployments: Automated from feature branches
├── Cron Jobs: Disabled
└── Data: Isolated test data
```

### **Branch Lifecycle**
```
Feature Branch → Develop Branch → Main Branch
     ↓              ↓              ↓
   Feature      Integration    Production
  Testing        Testing       Release
```

## 🔧 Branch Management Commands

### **Basic Operations**

#### **List Branches**
```bash
# List all branches
supabase branch list

# List with details
supabase branch list --verbose
```

#### **Create Branch**
```bash
# Create development branch
supabase branch create develop

# Create feature branch
supabase branch create feature/user-preferences

# Create hotfix branch
supabase branch create hotfix/critical-fix
```

#### **Switch Branch**
```bash
# Switch to development branch
supabase branch switch develop

# Switch to feature branch
supabase branch switch feature/new-feature

# Switch to main branch
supabase branch switch main
```

#### **Delete Branch**
```bash
# Delete feature branch
supabase branch delete feature/completed-feature

# Force delete (if needed)
supabase branch delete feature/completed-feature --force
```

### **Advanced Operations**

#### **Merge Branches**
```bash
# Merge feature branch to develop
supabase branch merge feature/new-feature develop

# Merge develop to main (production)
supabase branch merge develop main
```

#### **Reset Branch**
```bash
# Reset branch to match main
supabase branch reset feature/broken-feature main
```

## 📋 Development Workflow

### **Feature Development Process**

#### **1. Create Feature Branch**
```bash
# Create feature branch from develop
supabase branch switch develop
supabase branch create feature/new-feature
supabase branch switch feature/new-feature
```

#### **2. Develop and Test**
```bash
# Make changes to functions/migrations
# Test locally
supabase start
supabase db reset
supabase functions serve

# Deploy to feature branch
supabase db push
supabase functions deploy
```

#### **3. Merge to Develop**
```bash
# Switch to develop
supabase branch switch develop

# Merge feature branch
supabase branch merge feature/new-feature develop

# Test integration
./scripts/test-system.sh e2e $SERVICE_ROLE_KEY
```

#### **4. Deploy to Production**
```bash
# Switch to main
supabase branch switch main

# Merge develop to main
supabase branch merge develop main

# Verify production
./scripts/check-system-status.sh $SERVICE_ROLE_KEY
```

### **Hotfix Process**

#### **1. Create Hotfix Branch**
```bash
# Create hotfix from main
supabase branch switch main
supabase branch create hotfix/critical-fix
supabase branch switch hotfix/critical-fix
```

#### **2. Fix and Test**
```bash
# Make critical fix
# Test thoroughly
supabase db push
supabase functions deploy
./scripts/test-system.sh quick $SERVICE_ROLE_KEY
```

#### **3. Deploy Hotfix**
```bash
# Merge directly to main
supabase branch switch main
supabase branch merge hotfix/critical-fix main

# Also merge to develop
supabase branch switch develop
supabase branch merge hotfix/critical-fix develop
```

## 🔄 Environment Configuration

### **Branch-Specific URLs**
```bash
# Main branch
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co

# Development branch
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co/branches/develop

# Feature branch
SUPABASE_URL=https://joyavvleaxqzksopnmjs.supabase.co/branches/feature/new-feature
```

### **Environment Variables**
```bash
# Branch detection
SUPABASE_BRANCH=$(supabase branch list --output json | jq -r '.current')

# Dynamic URL construction
SUPABASE_BRANCH_URL="https://joyavvleaxqzksopnmjs.supabase.co"
if [ "$SUPABASE_BRANCH" != "main" ]; then
    SUPABASE_BRANCH_URL="${SUPABASE_BRANCH_URL}/branches/${SUPABASE_BRANCH}"
fi
```

## 🧪 Testing Strategy

### **Branch-Specific Testing**

#### **Feature Branch Testing**
```bash
# Quick functionality test
./scripts/test-system.sh quick $SERVICE_ROLE_KEY

# Feature-specific tests
./scripts/test-system.sh audio $SERVICE_ROLE_KEY
```

#### **Develop Branch Testing**
```bash
# Full integration test
./scripts/test-system.sh e2e $SERVICE_ROLE_KEY

# Load testing
./scripts/test-system.sh load $SERVICE_ROLE_KEY
```

#### **Main Branch Testing**
```bash
# Production health check
./scripts/check-system-status.sh $SERVICE_ROLE_KEY

# Full system validation
./scripts/test-system.sh e2e $SERVICE_ROLE_KEY
```

## 🧹 Branch Cleanup

### **Automated Cleanup**

#### **Feature Branch Cleanup**
```bash
# List completed feature branches
supabase branch list | grep "feature/"

# Delete completed features
for branch in $(supabase branch list | grep "feature/" | awk '{print $1}'); do
    if [ "$branch" != "feature/current-feature" ]; then
        supabase branch delete "$branch"
    fi
done
```

#### **Hotfix Branch Cleanup**
```bash
# Delete merged hotfix branches
for branch in $(supabase branch list | grep "hotfix/" | awk '{print $1}'); do
    supabase branch delete "$branch"
done
```

### **Manual Cleanup Checklist**
- [ ] Feature branch merged to develop
- [ ] Feature branch tested in develop
- [ ] Feature branch merged to main
- [ ] Feature branch deleted
- [ ] Documentation updated

## 🚨 Troubleshooting

### **Common Issues**

#### **Branch Switch Fails**
```bash
# Check current branch
supabase branch list

# Force switch if needed
supabase branch switch main --force
```

#### **Merge Conflicts**
```bash
# Reset branch to clean state
supabase branch reset feature/conflicted-feature develop

# Re-apply changes
supabase db push
supabase functions deploy
```

#### **Branch Not Found**
```bash
# Refresh branch list
supabase branch list --refresh

# Check remote branches
supabase branch list --remote
```

### **Recovery Procedures**

#### **Corrupted Branch**
```bash
# Create backup
supabase branch create backup/corrupted-branch

# Reset to main
supabase branch reset corrupted-branch main

# Re-apply changes manually
```

#### **Lost Changes**
```bash
# Check branch history
supabase branch list --verbose

# Restore from backup
supabase branch switch backup/feature-backup
supabase branch create feature/restored-feature
```

## 📊 Monitoring and Metrics

### **Branch Health Metrics**
- **Active Branches**: Number of active feature branches
- **Merge Frequency**: How often branches are merged
- **Cleanup Rate**: How quickly branches are deleted
- **Conflict Rate**: Frequency of merge conflicts

### **Performance Metrics**
- **Deployment Time**: Time from merge to deployment
- **Test Coverage**: Percentage of branches with tests
- **Success Rate**: Percentage of successful deployments

## 🔒 Security Considerations

### **Branch Access Control**
- **Main Branch**: Restricted access, manual approval required
- **Develop Branch**: Team access, automated deployment
- **Feature Branches**: Developer access, automated deployment

### **Data Protection**
- **Production Data**: Never copied to feature branches
- **Test Data**: Isolated per branch
- **Sensitive Data**: Masked in non-production branches

## 📚 Best Practices

### **Branch Naming**
- **Feature Branches**: `feature/descriptive-name`
- **Hotfix Branches**: `hotfix/issue-description`
- **Release Branches**: `release/version-number`

### **Commit Messages**
- **Format**: `type(scope): description`
- **Examples**:
  - `feat(audio): add new TTS voice option`
  - `fix(alarms): resolve timezone calculation bug`
  - `docs(api): update function documentation`

### **Testing Requirements**
- **Feature Branches**: Quick tests required
- **Develop Branch**: Full integration tests required
- **Main Branch**: Production validation required

---

**Last Updated**: January 2025  
**Version**: 1.0  
**Next Review**: February 2025 