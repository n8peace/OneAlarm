# Supabase GitHub Integration Guide

## Quick Reference

### How It Works
- **Supabase automatically deploys** when you push to `develop` or `main`
- **No manual deployment steps** needed
- **Preview environments** for testing
- **Production environment** for live app

### Your Workflow

#### 1. Make Changes
```bash
git checkout -b feature/my-change
# Make your changes
git add .
git commit -m "Add my change"
git push origin feature/my-change
```

#### 2. Test in Preview
```bash
git checkout develop
git merge feature/my-change
git push origin develop
# Supabase automatically deploys to preview environment
```

#### 3. Deploy to Production
```bash
git checkout main
git merge develop
git push origin main
# Supabase automatically deploys to production
```

### Accessing Environments

#### Preview Environment (develop branch)
- Check Supabase dashboard for preview URL
- Use this environment for testing before production
- Each push to `develop` updates this environment

#### Production Environment (main branch)
- Your live production environment
- Only updated when you push to `main`
- Use with caution

### What Happens Automatically

1. **Push to develop** → Supabase deploys to preview
2. **Push to main** → Supabase deploys to production
3. **Database migrations** → Applied automatically
4. **Edge Functions** → Deployed automatically
5. **Environment variables** → Managed in Supabase dashboard

### Monitoring Deployments

- **Supabase Dashboard** → Check deployment status
- **GitHub Actions** → Run tests and validation
- **Function Logs** → View in Supabase dashboard

### Best Practices

1. **Always test in develop first**
2. **Check Supabase dashboard** for deployment status
3. **Monitor function logs** after deployment
4. **Use meaningful commit messages**
5. **Keep changes small** for easier debugging

### Troubleshooting

#### Deployment Not Working?
- Check Supabase dashboard for errors
- Verify GitHub integration is enabled
- Check your Supabase plan limits

#### Functions Not Updating?
- Check function logs in Supabase dashboard
- Verify your code changes are pushed
- Check for syntax errors in functions

#### Database Issues?
- Check migration logs in Supabase dashboard
- Verify migration files are correct
- Check for constraint violations 