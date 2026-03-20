---
name: ci-cd-github-actions
description: Use when setting up CI/CD pipelines with GitHub Actions for a Gemini or Google AI application, automating tests, builds, and deployments on push or PR
---

# CI/CD with GitHub Actions

## Overview

Set up GitHub Actions workflows for automated testing, building, and deploying Gemini API applications. Covers CI (lint + test on PR) and CD (deploy on merge to main).

## When to Use

- User says "CI/CD設定して", "add GitHub Actions", "automate deployment"
- After initial deployment is working and user wants automation
- User wants PR checks before merging

## Quick Reference

### Workflow Files

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci.yml` | PR, push to main | Lint + Test |
| `.github/workflows/deploy.yml` | Push to main | Deploy to Cloud Run / Vercel / Railway |

## CI Workflow Template

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5  # or setup-node@v4
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install -r requirements.txt -r requirements-dev.txt

      - name: Lint
        run: ruff check .

      - name: Test
        run: pytest tests/
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
```

## CD Workflow Template (Cloud Run)

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

      - uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: my-gemini-app
          region: asia-northeast1
          source: .
```

## Implementation Steps

1. **Create `.github/workflows/` directory**
2. **Add CI workflow** — Lint + test on every PR
3. **Add CD workflow** — Deploy on merge to main
4. **Configure secrets** — `GEMINI_API_KEY`, GCP credentials (Workload Identity Federation)
5. **Set up Workload Identity Federation** — Keyless auth from GitHub to GCP
6. **Test with a PR** — Verify CI runs, merge, verify deploy

## Common Mistakes

- **Using service account keys** — Use Workload Identity Federation instead (keyless, more secure)
- **No test job** — Always run tests before deploying
- **Secrets in workflow file** — Use GitHub Secrets, never hardcode
- **Missing `permissions`** — WIF requires `id-token: write` permission
- **Running CI on every branch push** — Scope to `pull_request` and `push: branches: [main]`
