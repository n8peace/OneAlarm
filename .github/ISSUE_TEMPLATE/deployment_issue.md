---
name: Deployment Issue
about: Report issues with deployment, CI/CD, or production environment
title: '[DEPLOYMENT] '
labels: ['deployment', 'ci/cd']
assignees: ''

---

**Describe the deployment issue**
A clear and concise description of what went wrong during deployment.

**Environment**
- [ ] Development
- [ ] Staging
- [ ] Production

**Deployment Type**
- [ ] Database Migration
- [ ] Edge Function Deployment
- [ ] Environment Variable Update
- [ ] Cron Job Migration
- [ ] Other: _________

**Error Details**
Please provide:
1. Error message or logs
2. Step where failure occurred
3. GitHub Actions run URL (if applicable)

**Steps to Reproduce**
1. Trigger deployment via: [e.g., push to main, manual workflow dispatch]
2. Deployment fails at step: [e.g., "Deploy Edge Functions"]
3. Error occurs: [describe the error]

**Expected behavior**
What should have happened during deployment?

**Screenshots/Logs**
If applicable, add screenshots or logs from the deployment process.

**Additional context**
- When did this start happening?
- Any recent changes that might have caused this?
- Is this blocking production deployment?

**Checklist**
- [ ] I have included the GitHub Actions run URL
- [ ] I have provided error logs
- [ ] I have specified the environment affected
- [ ] I have checked if this is a recurring issue 