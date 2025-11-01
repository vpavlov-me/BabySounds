---
layout: default
title: Git Workflow
---

# Git Workflow for BabySounds

This document describes the git branching strategy and workflow for the BabySounds project.

## Branch Strategy

### Until v1.0 Release (Current Phase)

**Work directly in `main` branch**

During the sprint to v1.0, we work directly in main for:
- Speed and simplicity
- Quick iterations
- Fewer merge conflicts
- Direct visibility of progress

**Rules for main branch work**:
- ✅ Commit frequently with clear messages
- ✅ Test before committing
- ✅ Keep commits atomic and focused
- ✅ Use conventional commit format
- ❌ No broken builds in main
- ❌ No work-in-progress commits

### After v1.0 Release (Future)

**Feature branch workflow with `develop` branch**

```
main (production)
  ↑
  │ (release merge)
  │
develop (integration)
  ↑
  │ (feature merge via PR)
  │
feature/branch-name
```

## Branch Types

### `main`
- **Purpose**: Production-ready code
- **Protection**: Protected after v1.0
- **Deployment**: Deploys to App Store
- **Until v1.0**: Active development branch
- **After v1.0**: Only receives merges from `develop` via PR

### `develop`
- **Purpose**: Integration branch for features
- **Protection**: Requires PR review after v1.0
- **Usage**: Exists but inactive until v1.0
- **After v1.0**: All feature branches merge here first

### `feature/*`
- **Purpose**: New features and enhancements
- **Naming**: `feature/issue-number-description`
- **Examples**:
  - `feature/42-custom-mixes`
  - `feature/15-analytics-integration`
- **Lifecycle**: Created from `develop`, merged back to `develop`
- **Usage**: After v1.0 only

### `fix/*`
- **Purpose**: Bug fixes
- **Naming**: `fix/issue-number-description`
- **Examples**:
  - `fix/38-volume-calculation`
  - `fix/45-crash-on-launch`
- **Lifecycle**: Created from `develop`, merged back to `develop`
- **Usage**: After v1.0 only

### `hotfix/*`
- **Purpose**: Critical production fixes
- **Naming**: `hotfix/issue-number-description`
- **Examples**: `hotfix/99-crash-on-purchase`
- **Lifecycle**: Created from `main`, merged to both `main` AND `develop`
- **Usage**: After v1.0 only, for urgent fixes

### `release/*`
- **Purpose**: Release preparation
- **Naming**: `release/version-number`
- **Examples**: `release/1.1.0`
- **Lifecycle**: Created from `develop`, merged to `main` and `develop`
- **Usage**: After v1.0 only

## Workflow Phases

### Phase 1: Pre-v1.0 (CURRENT)

**Timeline**: Now until App Store submission

**Active Branch**: `main`

**Workflow**:
```bash
# Work directly in main
git checkout main
git pull origin main

# Make changes
# Test changes
# Commit with clear messages
git add .
git commit -m "feat: add new feature"

# Push to main
git push origin main
```

**Commit Message Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting)
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance

**Examples**:
```bash
git commit -m "feat(audio): implement buffer scheduling for playback"
git commit -m "fix(volume): correct WHO decibel calculation"
git commit -m "docs: update README with new features"
git commit -m "test: add unit tests for AudioEngineManager"
```

### Phase 2: Post-v1.0 (FUTURE)

**Timeline**: After App Store approval

**Active Branches**: `main` (production), `develop` (integration)

**Workflow for New Features**:

```bash
# 1. Update develop
git checkout develop
git pull origin develop

# 2. Create feature branch from develop
git checkout -b feature/42-custom-mixes

# 3. Work on feature
# ... make changes ...
# ... test thoroughly ...

# 4. Commit frequently
git add .
git commit -m "feat: add multi-track mixing UI"

# 5. Push feature branch
git push origin feature/42-custom-mixes

# 6. Create Pull Request on GitHub
# develop ← feature/42-custom-mixes

# 7. After review and approval, merge via GitHub
# (squash merge or regular merge)

# 8. Delete feature branch
git branch -d feature/42-custom-mixes
git push origin --delete feature/42-custom-mixes

# 9. Update local develop
git checkout develop
git pull origin develop
```

**Workflow for Bug Fixes**:

Same as features, but use `fix/` prefix:
```bash
git checkout develop
git checkout -b fix/38-volume-calculation
# ... fix bug ...
git push origin fix/38-volume-calculation
# Create PR: develop ← fix/38-volume-calculation
```

**Workflow for Hotfixes** (critical production bugs):

```bash
# 1. Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/99-crash-on-purchase

# 2. Fix critical bug
# ... make fix ...
# ... test thoroughly ...

# 3. Commit and push
git commit -m "hotfix: prevent crash in purchase flow"
git push origin hotfix/99-crash-on-purchase

# 4. Create PR to main
# main ← hotfix/99-crash-on-purchase

# 5. After merge to main, also merge to develop
git checkout develop
git pull origin develop
git merge hotfix/99-crash-on-purchase
git push origin develop

# 6. Delete hotfix branch
git branch -d hotfix/99-crash-on-purchase
git push origin --delete hotfix/99-crash-on-purchase
```

**Workflow for Releases**:

```bash
# 1. Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/1.1.0

# 2. Prepare release
# - Update version numbers
# - Update CHANGELOG.md
# - Final testing
# - Bug fixes only (no new features)

# 3. Commit release prep
git commit -m "chore: prepare release 1.1.0"
git push origin release/1.1.0

# 4. Create PR to main
# main ← release/1.1.0

# 5. After merge to main, tag release
git checkout main
git pull origin main
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin v1.1.0

# 6. Merge back to develop
git checkout develop
git merge main
git push origin develop

# 7. Delete release branch
git branch -d release/1.1.0
git push origin --delete release/1.1.0
```

## Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Type
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, no code change)
- `refactor`: Code refactoring (no functional changes)
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system changes
- `ci`: CI configuration changes
- `chore`: Other changes (dependencies, etc.)
- `revert`: Revert a previous commit

### Scope (optional)
- `audio`: Audio system
- `ui`: User interface
- `premium`: Subscription/premium features
- `safety`: Safety features (volume, parent gate)
- `schedule`: Sleep schedules
- `settings`: App settings
- `store`: StoreKit/purchases

### Subject
- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end
- Maximum 50 characters

### Body (optional)
- Explain what and why (not how)
- Wrap at 72 characters
- Separate from subject with blank line

### Footer (optional)
- Reference issues: `Closes #42` or `Fixes #38`
- Breaking changes: `BREAKING CHANGE: description`

### Examples

**Good commit messages**:
```
feat(audio): add multi-track buffer scheduling

Implement AVAudioEngine buffer scheduling for up to 4 simultaneous
audio tracks with individual volume control and fade effects.

Closes #7
```

```
fix(volume): correct WHO volume limit calculation

Previous implementation used incorrect logarithmic scale. Updated to
use proper decibel conversion per WHO guidelines.

Fixes #38
```

```
docs: add architecture guide and setup instructions

Created comprehensive technical documentation including:
- System architecture overview
- Development setup guide
- Audio system design details
```

**Bad commit messages**:
```
✗ "Fixed bug"                    (no context)
✗ "WIP"                          (work in progress, not complete)
✗ "More changes"                 (vague)
✗ "Updated files"                (not specific)
✗ "asdfasdf"                     (meaningless)
```

## Pull Request Guidelines (Post-v1.0)

### Creating a PR

1. **Title**: Clear, descriptive title
   - Format: `[Type] Brief description`
   - Example: `[Feature] Add custom sound mixes UI`

2. **Description**: Use PR template
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [x] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Related Issues
   Closes #42

   ## Testing
   - Tested on iPhone 15 Pro simulator
   - All unit tests pass
   - Manual testing completed

   ## Screenshots (if applicable)
   [Add screenshots]

   ## Checklist
   - [x] Code builds without warnings
   - [x] Tests pass
   - [x] Documentation updated
   - [x] Follows style guide
   ```

3. **Labels**: Add appropriate labels
4. **Assignees**: Assign yourself
5. **Reviewers**: Request review from maintainers
6. **Milestone**: Link to milestone (v1.1, v2.0, etc.)

### Reviewing a PR

**As a reviewer**:
- Check code quality and style
- Test functionality
- Review test coverage
- Check documentation
- Approve or request changes

**As PR author**:
- Address all feedback
- Push fixes to same branch
- Re-request review after changes
- Don't force-push (preserves review history)

### Merging a PR

**Merge strategies**:
- **Squash and merge**: For feature branches (clean history)
- **Regular merge**: For release branches (preserve commits)
- **Rebase and merge**: Rarely used

**After merge**:
- Delete feature branch
- Update local branches
- Close related issues

## Branch Protection Rules (Post-v1.0)

### `main` branch

Will be protected with:
- ✅ Require pull request reviews (1 approval)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Require conversation resolution
- ❌ Allow force pushes: disabled
- ❌ Allow deletions: disabled

### `develop` branch

Will be protected with:
- ✅ Require pull request reviews (1 approval)
- ✅ Require status checks to pass
- ❌ Allow force pushes: disabled

## Keeping Branches Updated

### Update main

```bash
git checkout main
git pull origin main
```

### Update develop

```bash
git checkout develop
git pull origin develop
```

### Update feature branch with latest develop

```bash
# Option 1: Merge (preserves history)
git checkout feature/my-feature
git merge develop

# Option 2: Rebase (cleaner history)
git checkout feature/my-feature
git rebase develop
```

## Resolving Conflicts

```bash
# 1. Update your branch
git checkout feature/my-feature
git pull origin develop

# 2. Resolve conflicts in editor
# (Xcode will show conflict markers)

# 3. Mark as resolved
git add <conflicted-files>

# 4. Complete merge
git commit -m "merge: resolve conflicts with develop"

# 5. Push
git push origin feature/my-feature
```

## Common Commands

### Check status
```bash
git status
git branch
git log --oneline -10
```

### Switch branches
```bash
git checkout main
git checkout develop
git checkout -b feature/new-feature  # create and switch
```

### Update branches
```bash
git pull origin main
git pull origin develop
```

### Clean up
```bash
# Delete local branch
git branch -d feature/old-feature

# Delete remote branch
git push origin --delete feature/old-feature

# Clean up tracking branches
git fetch --prune
```

### Undo changes
```bash
# Discard uncommitted changes
git restore <file>
git restore .

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

## Quick Reference

### Current Phase (Pre-v1.0)
```bash
# Daily workflow
git checkout main
git pull origin main
# ... make changes ...
git add .
git commit -m "feat: description"
git push origin main
```

### Future Phase (Post-v1.0)
```bash
# New feature workflow
git checkout develop
git pull origin develop
git checkout -b feature/42-description
# ... make changes ...
git commit -m "feat: description"
git push origin feature/42-description
# Create PR on GitHub
```

## Questions?

- Check [CONTRIBUTING.md](../CONTRIBUTING.md)
- Ask in [GitHub Discussions](https://github.com/vpavlov-me/BabySounds/discussions)
- Create an issue

---

**Current Status**: Pre-v1.0 - Working in `main` branch

**After v1.0**: Will switch to feature branch workflow with `develop`

[Back to Documentation](index)
