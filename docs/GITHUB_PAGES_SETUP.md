# GitHub Pages Setup Instructions

## Overview

GitHub Pages is configured to serve documentation from the `/docs` folder on the `main` branch.

## Activation Steps

1. Go to repository settings: https://github.com/vpavlov-me/BabySounds/settings/pages

2. Under "Build and deployment":
   - **Source**: Deploy from a branch
   - **Branch**: `main`
   - **Folder**: `/docs`

3. Click "Save"

4. Wait 1-2 minutes for deployment

5. Pages will be available at:
   - **Base URL**: https://vpavlov-me.github.io/BabySounds/
   - **Privacy Policy**: https://vpavlov-me.github.io/BabySounds/privacy-policy
   - **Terms of Service**: https://vpavlov-me.github.io/BabySounds/terms-of-service

## Published Documentation

Once activated, the following pages will be public:

### Legal Documents (Required for App Store)
- **Privacy Policy**: `/docs/privacy-policy.md`
  - COPPA, GDPR, CCPA compliance
  - Children's privacy protection
  - WHO hearing safety info

- **Terms of Service**: `/docs/terms-of-service.md`
  - Subscription terms
  - Age requirements
  - Hearing safety disclaimers
  - Liability limitations

### Technical Documentation
- **Architecture Guide**: `/docs/ARCHITECTURE.md`
  - System design
  - Audio engine details
  - Safety features

- **Setup Guide**: `/docs/SETUP.md`
  - Development environment
  - Build instructions
  - Testing procedures

- **Git Workflow**: `/docs/GIT_WORKFLOW.md`
  - Branching strategy
  - Commit conventions
  - PR process

### Landing Page
- **Index**: `/docs/index.md`
  - Documentation hub
  - Quick links

## Jekyll Configuration

The site uses Jekyll with the Minimal theme:
- Theme: `jekyll-theme-minimal`
- Title: "Baby Sounds Documentation"
- Description: "Official documentation for Baby Sounds iOS app"
- Config: `/docs/_config.yml`

## Verification

After activation, verify:
1. Base URL loads index page
2. Privacy policy accessible (required for App Store)
3. Terms accessible (required for App Store)
4. Navigation links work
5. Markdown rendering correct

## App Store Integration

Add these URLs to App Store Connect:
- **Privacy Policy URL**: https://vpavlov-me.github.io/BabySounds/privacy-policy
- **Terms of Use URL**: https://vpavlov-me.github.io/BabySounds/terms-of-service

## Updating Documentation

To update published docs:
1. Edit files in `/docs/` folder
2. Commit and push to `main` branch
3. GitHub Pages auto-deploys in ~1 minute
4. No build step required (Jekyll automatic)

## Custom Domain (Optional)

To use custom domain:
1. Add `CNAME` file with domain to `/docs/`
2. Configure DNS with your provider
3. Update repository settings

Example CNAME content:
```
docs.babysounds.app
```

## Troubleshooting

If pages don't load:
1. Check Settings → Pages shows "Your site is live at..."
2. Verify branch is `main` and folder is `/docs`
3. Wait 5 minutes for DNS propagation
4. Check for build errors in Actions tab
5. Ensure `_config.yml` is valid YAML

## Status

- ✅ Documentation files created
- ✅ Jekyll configuration ready
- ✅ Privacy policy complete
- ✅ Terms of service complete
- ⏳ **Requires manual activation in repository settings**

## Next Steps

1. **Activate GitHub Pages** (manual step in repo settings)
2. **Verify URLs** load correctly
3. **Add URLs to App Store Connect** submission
4. **Test all navigation links**

---

**Note**: This setup allows public access to legal documents as required by Apple App Store review process while keeping source code and development docs organized.
