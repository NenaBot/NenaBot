# Submodule Automation

This repo tracks frontend and backend as git submodules.

Workflow file:

- [.github/workflows/update-submodules.yml](.github/workflows/update-submodules.yml)

## What It Does

1. Runs on schedule or manual trigger
2. Pulls latest submodule commits from tracked branch (fallback `main`)
3. Creates/updates a PR with new submodule pointers

## Required Setup

Add repository secret:

- `SUBMODULES_PAT`

Token needs access to:

- Parent repo `NenaBot/NenaBot`: `Contents (Read and write)`, `Pull requests (Read and write)`
- Submodule repos `NenaBot/nenabot-backend` and `NenaBot/nenabot-frontend`: `Contents (Read-only)`

Also ensure org SSO is authorized for this token if your organization requires SSO.

## Manual Fallback

```bash
git submodule update --init --recursive
git submodule foreach 'git fetch origin && git checkout main && git pull --ff-only origin main'
git add frontend backend
git commit -m "chore(submodules): update pointers"
git push
```
