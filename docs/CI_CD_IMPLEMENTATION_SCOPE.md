# OneAlarm CI/CD Implementation Scope Document

## 🎯 Project Overview

**Objective**: Implement a comprehensive CI/CD pipeline using GitHub Actions and Supabase with separate production and development environments, while maintaining the ability to continue development with AI assistance.

**Current State**: 
- Production Supabase project: `joyavvleaxqzksopnmjs`
- Local development with manual deployment
- External cron jobs via cron-job.org
- Fully operational production system
- ✅ **COMPLETED**: Hardcoded URL standardization

**Target State**:
- Automated CI/CD pipeline
- Separate dev/prod environments
- Zero-downtime deployments
- Maintained development workflow

---

## 📋 Scope Definition

### **In Scope**
1. **GitHub Repository Setup**
   - Push existing codebase to GitHub
   - Configure branch protection rules
   - Set up repository secrets

2. **CI/CD Pipeline Implementation**
   - Automated testing workflows
   - Deployment workflows for both environments
   - Database migration automation
   - Health check verification

3. **Environment Management**
   - Production environment (existing)
   - Development environment (new Supabase project)
   - Environment-specific configurations

4. **Cron Job Migration**
   - Migrate from cron-job.org to GitHub Actions
   - Maintain existing functionality
   - Enhanced monitoring and alerting

5. **Development Workflow Preservation**
   - Maintain ability to code with AI assistance
   - Preserve existing testing scripts
   - Keep local development capabilities

### **Out of Scope**
1. **Code Changes**: No modifications to existing application logic
2. **Database Schema Changes**: No structural database modifications
3. **Performance Optimizations**: No changes to current performance characteristics
4. **UI/UX Changes**: No frontend modifications
5. **Third-Party Service Changes**: No modifications to external API integrations

---

## 🏗️ Technical Architecture

### **Repository Structure**
```
onealarm/
├── .github/
│   └── workflows/
│       ├── ci.yml (Testing)
│       ├── deploy-dev.yml (Dev deployment)
│       ├── deploy-prod.yml (Production deployment)
│       ├── migrate-db.yml (Database migrations)
│       └── cron-jobs.yml (Scheduled tasks)
├── supabase/
│   ├── functions/ (Edge functions)
│   ├── migrations/ (Database migrations)
│   └── config/ (Environment configs)
├── scripts/ (Existing deployment scripts)
└── docs/ (Documentation)
```

### **Environment Configuration**
```
Production (main branch):
├── Supabase Project: joyavvleaxqzksopnmjs
├── Environment: production
├── API Keys: Production keys
└── Cron Schedule: Current schedule

Development (develop branch):
├── Supabase Project: onealarm-dev (new)
├── Environment: development
├── API Keys: Development keys
└── Cron Schedule: Reduced frequency
```

---

## ✅ **COMPLETED: Phase 1 - Critical Fixes**

### **Hardcoded URL Standardization (COMPLETED)**
**Objective**: Fix hardcoded URLs in scripts to enable multi-environment deployment

**Tasks Completed**:
1. **Centralized Configuration** ✅
   - Updated `scripts/config.sh` to be the single source of truth
   - Added environment variable support with backward compatibility
   - Standardized color definitions and utility functions

2. **Script Standardization** ✅
   - Updated `scripts/test-system.sh` to use centralized config
   - Updated `scripts/check-system-status.sh` to use centralized config
   - Updated `scripts/monitor-system.sh` to use centralized config
   - Updated `scripts/test-utils.sh` to use centralized config
   - Updated `scripts/diagnose-storage.sh` to use centralized config
   - Updated `scripts/check-recent-audio.sh` to use centralized config
   - Updated `scripts/create-test-user.sh` to use centralized config
   - Updated `scripts/create-test-alarm.sh` to use centralized config

3. **GitHub Workflow Updates** ✅
   - Updated `.github/workflows/daily-content.yml` to use environment variables
   - Replaced hardcoded URLs with `${{ secrets.SUPABASE_URL }}`

**Files Modified**:
- `scripts/config.sh` - Enhanced with environment variable support
- `scripts/test-system.sh` - Standardized to use config.sh
- `scripts/check-system-status.sh` - Standardized to use config.sh
- `scripts/monitor-system.sh` - Standardized to use config.sh
- `scripts/test-utils.sh` - Standardized to use config.sh
- `scripts/diagnose-storage.sh` - Standardized to use config.sh
- `scripts/check-recent-audio.sh` - Standardized to use config.sh
- `scripts/create-test-user.sh` - Standardized to use config.sh
- `scripts/create-test-alarm.sh` - Standardized to use config.sh
- `.github/workflows/daily-content.yml` - Updated to use environment variables

**Benefits Achieved**:
- ✅ **Multi-environment Support**: Scripts now work with any Supabase project
- ✅ **CI/CD Ready**: No more hardcoded URLs blocking deployment
- ✅ **Maintainability**: Single source of truth for configuration
- ✅ **Backward Compatibility**: Existing scripts continue to work
- ✅ **Standardization**: Consistent error handling and logging

---

## 📅 Implementation Plan

### **Phase 1: Foundation Setup (2 hours)** ✅ **COMPLETED**
**Objective**: Establish GitHub repository and basic CI/CD structure

**Tasks**:
1. **Repository Creation** (30 minutes) ✅
   - Create GitHub repository
   - Push existing codebase
   - Configure .gitignore and README

2. **Secrets Configuration** (60 minutes)
   - Set up GitHub repository secrets
   - Configure environment-specific variables
   - Document secret management process

3. **Basic Workflow Setup** (30 minutes)
   - Create initial CI workflow
   - Set up basic deployment workflow
   - Configure branch protection rules

**Deliverables**:
- GitHub repository with codebase ✅
- Configured repository secrets
- Basic CI/CD workflows

### **Phase 2: Environment Setup (2 hours)** ✅ **COMPLETED**
**Objective**: Create and configure development environment

**Tasks**:
1. **Dev Environment Creation** (60 minutes)
   - Create new Supabase project
   - Copy production schema via migrations
   - Configure dev-specific settings

2. **Environment Configuration** (60 minutes)
   - Set up environment-specific variables
   - Configure dev API keys
   - Set up dev cron jobs (reduced frequency)

**Deliverables**:
- Development Supabase project
- Environment-specific configurations
- Dev environment documentation

### **Phase 3: Advanced CI/CD (2 hours)**
**Objective**: Implement comprehensive deployment and testing workflows

**Tasks**:
1. **Deployment Workflows** (60 minutes)
   - Production deployment workflow
   - Development deployment workflow
   - Database migration automation

2. **Testing and Validation** (60 minutes)
   - Automated testing workflows
   - Health check verification
   - Rollback capabilities

**Deliverables**:
- Complete CI/CD pipeline
- Automated testing framework
- Deployment validation system

### **Phase 4: Cron Migration (1 hour)**
**Objective**: Migrate scheduled tasks to GitHub Actions

**Tasks**:
1. **Cron Job Migration** (45 minutes)
   - Create GitHub Actions scheduled workflows
   - Migrate existing cron jobs
   - Configure monitoring and alerting

2. **Validation and Testing** (15 minutes)
   - Test migrated cron jobs
   - Verify functionality
   - Update documentation

**Deliverables**:
- Migrated cron jobs
- Enhanced monitoring
- Updated documentation

---

## 🔧 Technical Specifications

### **GitHub Actions Workflows**

#### **CI Workflow (.github/workflows/ci.yml)**
```yaml
Triggers: Push to any branch
Actions:
- Install dependencies
- Run linting
- Execute tests
- Validate database schema
- Security scanning
```

#### **Development Deployment (.github/workflows/deploy-dev.yml)**
```yaml
Triggers: Push to develop branch
Actions:
- Deploy to dev Supabase project
- Run integration tests
- Verify health checks
- Send deployment notifications
```

#### **Production Deployment (.github/workflows/deploy-prod.yml)**
```yaml
Triggers: Push to main branch
Actions:
- Deploy to production Supabase project
- Run production tests
- Verify health checks
- Send deployment notifications
- Update deployment status
```

#### **Database Migration (.github/workflows/migrate-db.yml)**
```yaml
Triggers: Manual or on migration file changes
Actions:
- Apply database migrations
- Validate schema changes
- Run migration tests
- Update migration status
```

#### **Cron Jobs (.github/workflows/cron-jobs.yml)**
```yaml
Triggers: Scheduled (current cron schedule)
Actions:
- Execute daily-content function
- Execute audio generation processing
- Monitor execution status
- Send failure alerts
```

### **Environment Variables**

#### **Production Secrets**
```
SUPABASE_URL_PROD
SUPABASE_ANON_KEY_PROD
SUPABASE_SERVICE_ROLE_KEY_PROD
OPENAI_API_KEY_PROD
NEWSAPI_KEY_PROD
SPORTSDB_API_KEY_PROD
RAPIDAPI_KEY_PROD
ABSTRACT_API_KEY_PROD
SENDGRID_API_KEY_PROD
ALERT_EMAIL_PROD
```

#### **Development Secrets**
```
SUPABASE_URL_DEV
SUPABASE_ANON_KEY_DEV
SUPABASE_SERVICE_ROLE_KEY_DEV
OPENAI_API_KEY_DEV
NEWSAPI_KEY_DEV
SPORTSDB_API_KEY_DEV
RAPIDAPI_KEY_DEV
ABSTRACT_API_KEY_DEV
SENDGRID_API_KEY_DEV
ALERT_EMAIL_DEV
```

---

## 🚀 Deployment Strategy

### **Zero-Downtime Deployment**
- **Supabase Edge Functions**: Support instant deployment
- **Database Migrations**: Backward-compatible changes only
- **Rollback Capability**: Previous function versions remain available
- **Health Checks**: Post-deployment validation

### **Environment Promotion**
```
Feature Branch → Develop Branch → Main Branch
     ↓              ↓              ↓
   Local Dev    Dev Environment  Production
```

### **Safety Measures**
- **Branch Protection**: Require PR reviews for main branch
- **Automated Testing**: All changes must pass tests
- **Health Checks**: Verify deployment success
- **Rollback Plan**: Quick rollback to previous version

---

## 📊 Monitoring and Alerting

### **Deployment Monitoring**
- **Success/Failure Notifications**: Email/Slack alerts
- **Health Check Verification**: Post-deployment validation
- **Performance Monitoring**: Execution time tracking
- **Error Tracking**: Detailed error logging

### **Cron Job Monitoring**
- **Execution Status**: Success/failure tracking
- **Performance Metrics**: Execution time monitoring
- **Failure Alerts**: Immediate notification on failures
- **Retry Logic**: Automatic retry on failures

---

## 🔒 Security Considerations

### **Secret Management**
- **GitHub Secrets**: All API keys stored securely
- **Environment Isolation**: Separate keys for dev/prod
- **Access Control**: Limited access to production secrets
- **Rotation Policy**: Regular key rotation schedule

### **Access Control**
- **Branch Protection**: Require reviews for main branch
- **Deployment Permissions**: Limited to authorized users
- **Environment Access**: Separate access for dev/prod
- **Audit Logging**: Track all deployment activities

---

## 📈 Success Metrics

### **Deployment Metrics**
- **Deployment Time**: < 5 minutes per environment
- **Success Rate**: > 99% successful deployments
- **Rollback Time**: < 2 minutes for emergency rollback
- **Zero Downtime**: 100% uptime during deployments

### **Development Metrics**
- **Build Time**: < 3 minutes for CI pipeline
- **Test Coverage**: Maintain current test coverage
- **Development Velocity**: No impact on development speed
- **Error Rate**: < 1% deployment failures

---

## 🛠️ Development Workflow Preservation

### **Local Development**
- **Unchanged Workflow**: Continue coding with AI assistance
- **Local Testing**: Maintain existing test scripts
- **Manual Deployment**: Keep ability to deploy manually
- **Environment Switching**: Easy switching between dev/prod

### **AI Collaboration**
- **Code Review**: AI can review CI/CD changes
- **Testing Assistance**: AI can help with test creation
- **Debugging Support**: AI can assist with deployment issues
- **Documentation**: AI can help maintain documentation

---

## ⚠️ Risks and Mitigation

### **High-Risk Items**
1. **API Key Migration**: Risk of key exposure
   - **Mitigation**: Use GitHub secrets, rotate keys after migration

2. **Cron Job Disruption**: Risk of missed scheduled tasks
   - **Mitigation**: Parallel migration, maintain existing cron jobs during transition

3. **Database Migration Issues**: Risk of schema conflicts
   - **Mitigation**: Test migrations in dev environment first

### **Medium-Risk Items**
1. **Environment Configuration**: Risk of misconfiguration
   - **Mitigation**: Comprehensive testing, documentation

2. **Deployment Failures**: Risk of broken deployments
   - **Mitigation**: Automated testing, rollback capabilities

### **Low-Risk Items**
1. **Performance Impact**: Minimal impact expected
2. **Cost Increase**: Minimal additional costs
3. **Learning Curve**: Team familiar with GitHub Actions

---

## 📋 Acceptance Criteria

### **Functional Requirements**
- [ ] All existing functionality preserved
- [ ] Automated deployment to both environments
- [ ] Zero-downtime deployments
- [ ] Automated testing before deployment
- [ ] Health check verification
- [ ] Cron job migration completed
- [ ] Rollback capabilities functional

### **Non-Functional Requirements**
- [ ] Deployment time < 5 minutes
- [ ] Success rate > 99%
- [ ] Zero impact on development workflow
- [ ] Comprehensive monitoring and alerting
- [ ] Security best practices implemented
- [ ] Documentation updated

### **Development Workflow**
- [ ] AI collaboration capability maintained
- [ ] Local development workflow unchanged
- [ ] Testing capabilities preserved
- [ ] Manual deployment option available

---

## ⏱️ Timeline Summary

**Total Implementation Time**: 7 hours
- **Phase 1**: 2 hours (Foundation) ✅ **COMPLETED**
- **Phase 2**: 2 hours (Environments) ✅ **COMPLETED**
- **Phase 3**: 2 hours (Advanced CI/CD)
- **Phase 4**: 1 hour (Cron Migration)

**Critical Path**: 5 hours (Phases 1-3)
**Optional Enhancements**: 2 hours (Phase 4 + additional features)

**Go-Live Readiness**: After Phase 3 completion
**Full Feature Set**: After Phase 4 completion

---

## 📞 Next Steps

1. **Approval**: Review and approve this scope document
2. **Repository Setup**: Begin Phase 2 implementation
3. **Environment Creation**: Set up development environment
4. **Pipeline Implementation**: Deploy CI/CD workflows
5. **Testing and Validation**: Verify all functionality
6. **Documentation**: Update all relevant documentation
7. **Training**: Team familiarization with new workflow

**Ready to proceed with Phase 2 implementation when approved.**

---

## 📚 Related Documents

- [Current System Architecture](README.md)
- [Database Schema](docs/DATABASE_SCHEMA.md)
- [Deployment Guide](docs/CONNECTING_TO_SUPABASE.md)
- [Scaling Roadmap](docs/SCALING_ROADMAP.md)
- [System Limits](docs/SYSTEM_LIMITS.md)

---

**Document Version**: 2.0  
**Last Updated**: January 2025  
**Status**: Phase 1 Complete - Ready for Phase 2 