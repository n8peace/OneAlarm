# Environment Setup Guide

## 🌍 Environment Configuration

OneAlarm now supports multiple environments with branch-based deployment:

### **Environments**

#### **Production**
- **Project**: `joyavvleaxqzksopnmjs`
- **URL**: `https://joyavvleaxqzksopnmjs.supabase.co`
- **Branch**: `main`
- **Purpose**: Live production environment

#### **Development**
- **Project**: `xqkmpkfqoisqzznnvlox`
- **URL**: `https://xqkmpkfqoisqzznnvlox.supabase.co`
- **Branch**: `develop`
- **Purpose**: Development and testing environment

---

## 🔧 Configuration Files

### **Environment Files**
- `env.production` - Production environment configuration
- `env.development` - Development environment configuration
- `.env` - Current active environment (auto-generated)

### **Scripts**
- `scripts/config.sh` - Shared configuration and utilities
- `scripts/switch-env.sh` - Environment switcher

---

## 🚀 Quick Start

### **1. Switch to Development Environment**
```bash
./scripts/switch-env.sh development
```

### **2. Switch to Production Environment**
```bash
./scripts/switch-env.sh production
```

### **3. Check Current Environment**
```bash
source scripts/config.sh
show_environment_info
```

---

## 📋 Required Configuration

### **For Each Environment, You Need:**

#### **Supabase Configuration**
- `SUPABASE_URL` - Base URL for the project
- `SUPABASE_ANON_KEY` - Anonymous key for client access
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for admin access
- `SUPABASE_PROJECT_REF` - Project reference ID
- `SUPABASE_BRANCH` - Branch name (main/develop)

#### **API Keys**
- `OPENAI_API_KEY` - OpenAI API key
- `NEWSAPI_KEY` - News API key
- `SPORTSDB_API_KEY` - Sports DB API key
- `RAPIDAPI_KEY` - RapidAPI key
- `ABSTRACT_API_KEY` - Abstract API key

---

## 🔑 Getting API Keys

### **Supabase Keys**
1. Go to your Supabase project dashboard
2. Navigate to Settings → API
3. Copy the required keys

### **External API Keys**
- **OpenAI**: https://platform.openai.com/api-keys
- **News API**: https://newsapi.org/account
- **Sports DB**: https://www.thesportsdb.com/api.php
- **RapidAPI**: https://rapidapi.com/
- **Abstract API**: https://www.abstractapi.com/

---

## 🌐 GitHub Secrets

For CI/CD to work, add these secrets to your GitHub repository:

### **Development Secrets**
```
SUPABASE_URL_DEV=https://xqkmpkfqoisqzznnvlox.supabase.co
SUPABASE_DEV_PROJECT_REF=xqkmpkfqoisqzznnvlox
SUPABASE_SERVICE_ROLE_KEY_DEV=your_dev_service_role_key
OPENAI_API_KEY_DEV=your_dev_openai_key
NEWSAPI_KEY_DEV=your_dev_newsapi_key
SPORTSDB_API_KEY_DEV=your_dev_sportsdb_key
RAPIDAPI_KEY_DEV=your_dev_rapidapi_key
ABSTRACT_API_KEY_DEV=your_dev_abstract_key
```

### **Production Secrets**
```
SUPABASE_URL_PROD=https://joyavvleaxqzksopnmjs.supabase.co
SUPABASE_PROD_PROJECT_REF=joyavvleaxqzksopnmjs
SUPABASE_SERVICE_ROLE_KEY_PROD=your_prod_service_role_key
OPENAI_API_KEY_PROD=your_prod_openai_key
NEWSAPI_KEY_PROD=your_prod_newsapi_key
SPORTSDB_API_KEY_PROD=your_prod_sportsdb_key
RAPIDAPI_KEY_PROD=your_prod_rapidapi_key
ABSTRACT_API_KEY_PROD=your_prod_abstract_key
```

### **Shared Secrets**
```
SUPABASE_ACCESS_TOKEN=your_supabase_access_token
```

---

## 🔄 Branch URLs

When working with branches, use these URLs:

### **Development Branch**
```
https://xqkmpkfqoisqzznnvlox.supabase.co/branches/develop
```

### **Production Branch**
```
https://joyavvleaxqzksopnmjs.supabase.co/branches/main
```

---

## 🛠️ Troubleshooting

### **Common Issues**

#### **1. Environment Not Switching**
- Check that `env.development` and `env.production` files exist
- Verify file permissions on `scripts/switch-env.sh`

#### **2. Missing API Keys**
- Update the environment files with your actual API keys
- Check that keys are valid and have proper permissions

#### **3. Branch Access Issues**
- Verify that preview branching is enabled in Supabase
- Check that GitHub integration is properly configured

### **Validation Commands**
```bash
# Check environment configuration
source scripts/config.sh
validate_environment

# Test function access
curl -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
     "$(get_function_url daily-content)"
```

---

## 📚 Related Documentation

- [Branch-Based CI/CD Implementation Plan](BRANCH_BASED_CI_CD_IMPLEMENTATION_PLAN.md)
- [Phase 2 CI/CD Setup](PHASE_2_CI_CD_SETUP.md)
- [Connecting to Supabase](CONNECTING_TO_SUPABASE.md) 