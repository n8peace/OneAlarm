# GitHub Secrets Setup Guide

## Overview
This document provides the complete list of GitHub secrets required for the OneAlarm CI/CD workflow to function properly across both development and production environments.

## Required Secrets

### Supabase Configuration

#### Production Environment
- `SUPABASE_URL_PROD`: `https://joyavvleaxqzksopnmjs.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY_PROD`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpveWF2dmxlYXhxemtzb3BubWpzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDE5MDc2NSwiZXhwIjoyMDY1NzY2NzY1fQ.6Mf8KFY_9hXriVbYe1kZpKd4c_4m-3j2y6r_Ds4i4og`
- `SUPABASE_PROD_PROJECT_REF`: `joyavvleaxqzksopnmjs`

#### Development Environment
- `SUPABASE_URL_DEV`: `https://xqkmpkfqoisqzznnvlox.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY_DEV`: `[Get from Supabase Dashboard]`
- `SUPABASE_DEV_PROJECT_REF`: `xqkmpkfqoisqzznnvlox`

#### Global Supabase
- `SUPABASE_ACCESS_TOKEN`: `[Get from Supabase CLI: supabase login]`

### API Keys

#### Production Environment
- `OPENAI_API_KEY_PROD`: `[Your production OpenAI API key]`
- `NEWSAPI_KEY_PROD`: `[Your production NewsAPI key]`
- `SPORTSDB_API_KEY_PROD`: `[Your production SportsDB API key]`
- `RAPIDAPI_KEY_PROD`: `[Your production RapidAPI key]`
- `ABSTRACT_API_KEY_PROD`: `[Your production Abstract API key]`

#### Development Environment
- `OPENAI_API_KEY_DEV`: `[Your development OpenAI API key]`
- `NEWSAPI_KEY_DEV`: `[Your development NewsAPI key]`
- `SPORTSDB_API_KEY_DEV`: `[Your development SportsDB API key]`
- `RAPIDAPI_KEY_DEV`: `[Your development RapidAPI key]`
- `ABSTRACT_API_KEY_DEV`: `[Your development Abstract API key]`

## Setup Instructions

### 1. Access GitHub Secrets
1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret" for each secret

### 2. Add Each Secret
For each secret listed above:
1. Name: Use the exact name shown (e.g., `SUPABASE_URL_PROD`)
2. Value: Use the corresponding value
3. Click "Add secret"

### 3. Verify Secrets
After adding all secrets, you can test them using the GitHub Actions workflow:
1. Go to Actions tab
2. Run the "Test Environment Secrets" workflow manually
3. Verify all secrets are accessible

## Environment-Specific Configuration

### Production (main branch)
- Uses `_PROD` suffixed secrets
- Deploys to `joyavvleaxqzksopnmjs` project
- Uses `main` branch in Supabase

### Development (develop branch)
- Uses `_DEV` suffixed secrets
- Deploys to `xqkmpkfqoisqzznnvlox` project
- Uses `develop` branch in Supabase

## Security Notes

1. **Never commit secrets to the repository**
2. **Use different API keys for dev/prod environments**
3. **Rotate secrets regularly**
4. **Monitor secret usage in GitHub Actions logs**

## Troubleshooting

### Common Issues
1. **Secret not found**: Ensure exact name matching (case-sensitive)
2. **Access denied**: Verify Supabase access token is valid
3. **Branch deployment fails**: Check if target branch exists in Supabase

### Validation Commands
```bash
# Test Supabase CLI access
supabase login
supabase projects list

# Test environment-specific access
supabase link --project-ref [PROJECT_REF]
supabase branches list --experimental
```

## Next Steps

After setting up all secrets:
1. Test the "Test Environment Secrets" workflow
2. Create the develop branch in Supabase
3. Run the "Deploy to Branch" workflow targeting develop
4. Validate both environments are operational 