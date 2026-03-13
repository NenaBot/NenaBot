# Submodule Automation

This repo tracks frontend and backend as git submodules.

Workflow file:

- [.github/workflows/update-submodules.yml](.github/workflows/update-submodules.yml)

## What It Does

1. Runs on schedule or manual trigger
2. Pulls latest submodule commits from tracked branch (fallback `main`)
3. Creates/updates a PR with new submodule pointers

## Required Setup

If submodules are private, add repo secret:

- `SUBMODULES_PAT` with read access to submodule repos

If submodules are public, no extra secret is required.

## Manual Fallback

```bash
git submodule update --init --recursive
git submodule foreach 'git fetch origin && git checkout main && git pull --ff-only origin main'
git add frontend backend
git commit -m "chore(submodules): update pointers"
git push
```
