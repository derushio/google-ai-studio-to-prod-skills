---
name: cloud-run-deploy
description: Use when deploying a Gemini or Google AI application to Google Cloud Run, containerizing a Python/Node.js app for serverless deployment, or setting up Cloud Run with Secret Manager and IAM
---

# Cloud Run Deploy

## Overview

Deploy a Gemini API application to Google Cloud Run with production-ready configuration. Cloud Run is the default choice for serverless deployment of AI Studio prototypes — pay-per-request, auto-scaling, and minimal ops.

## When to Use

- User wants to deploy to production on GCP
- User says "Cloud Runにデプロイして", "deploy to Cloud Run", "make this production-ready"
- App uses Gemini API and needs a hosting solution
- User needs serverless deployment with auto-scaling

**When NOT to use:** If user specifically wants Vercel/Railway → use `vercel-railway-deploy`.

## Quick Reference

| Step | Command |
|------|---------|
| Auth | `gcloud auth login` |
| Set project | `gcloud config set project PROJECT_ID` |
| Enable APIs | `gcloud services enable run.googleapis.com secretmanager.googleapis.com` |
| Store secret | `echo -n "KEY" \| gcloud secrets create gemini-api-key --data-file=-` |
| Deploy | `gcloud run deploy SERVICE --source . --region asia-northeast1` |

## Implementation Steps

1. **Verify prerequisites** — `gcloud` CLI installed, project selected, billing enabled
2. **Enable required APIs** — Cloud Run, Secret Manager, Artifact Registry
3. **Store API key in Secret Manager** — Never pass as plain env var
4. **Generate Dockerfile** from templates (see `templates/`)
5. **Generate `.dockerignore`**
6. **Add health check endpoint** — `GET /health` returning 200
7. **Deploy with `gcloud run deploy`** — Set region, memory, concurrency
8. **Configure IAM** — Grant Secret Manager access to Cloud Run service account
9. **Verify deployment** — Curl the service URL

## Architecture

| Layer | Component | Role |
|-------|-----------|------|
| Client | Browser / API consumer | リクエスト送信 |
| Compute | **Cloud Run** (auto-scaling) | アプリケーション実行 |
| AI | Gemini API | モデル推論 |
| Secrets | Secret Manager | API Key 管理 |

> **Flow:** Client → Cloud Run → Gemini API / Cloud Run ← Secret Manager

## Common Mistakes

- **API key as plain env var** — Use Secret Manager, not `--set-env-vars`
- **No health check** — Cloud Run needs `/health` endpoint for readiness probes
- **Default service account** — Create a dedicated SA with minimal permissions
- **Wrong region** — Use `asia-northeast1` for Japan-based users
- **No `.dockerignore`** — Uploading `node_modules/` or `.venv/` bloats the image
- **Missing `--allow-unauthenticated`** — Needed for public APIs; omit for internal services
