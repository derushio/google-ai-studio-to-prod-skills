---
name: security-hardening-gcp
description: Use when hardening GCP security for a deployed Gemini or AI application, configuring IAM least-privilege, Secret Manager, VPC, or reviewing GCP security posture
---

# Security Hardening for GCP

## Overview

Secure a Gemini API application deployed on GCP. Covers IAM least-privilege, Secret Manager, network security, and common attack surfaces specific to AI applications.

## When to Use

- User says "セキュリティ設定して", "secure my deployment", "harden GCP"
- After initial deployment, before going to production traffic
- Security review of an existing GCP deployment

## Security Checklist

| Area | Action | Priority |
|------|--------|----------|
| Secrets | API keys in Secret Manager, not env vars | Critical |
| IAM | Dedicated service account with minimal roles | Critical |
| Auth | Cloud Run `--no-allow-unauthenticated` for internal services | High |
| Network | VPC connector if accessing internal resources | High |
| Logging | Cloud Audit Logs enabled | Medium |
| Egress | Restrict outbound to Gemini API endpoints only | Medium |

## IAM — Least Privilege

### Dedicated Service Account

```bash
# Create SA
gcloud iam service-accounts create gemini-app-sa \
  --display-name="Gemini App Service Account"

# Grant only what's needed
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:gemini-app-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Deploy with dedicated SA
gcloud run deploy my-gemini-app \
  --service-account=gemini-app-sa@PROJECT_ID.iam.gserviceaccount.com
```

### Roles to Avoid

| Role | Why | Use Instead |
|------|-----|-------------|
| `roles/owner` | God mode | Specific roles |
| `roles/editor` | Too broad | Specific roles |
| `roles/secretmanager.admin` | Can create/delete secrets | `secretAccessor` |

## Secret Manager

```bash
# Create secret
echo -n "AIzaSy..." | gcloud secrets create gemini-api-key --data-file=-

# Grant access to SA
gcloud secrets add-iam-policy-binding gemini-api-key \
  --member="serviceAccount:gemini-app-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Reference in Cloud Run
gcloud run deploy my-gemini-app \
  --set-secrets="GEMINI_API_KEY=gemini-api-key:latest"
```

## AI-Specific Security

| Risk | Mitigation |
|------|------------|
| Prompt injection | Input validation + output sanitization |
| API key leakage | Secret Manager + key rotation |
| Cost explosion | Budget alerts + quota limits |
| Data exfiltration via prompts | Log and monitor all Gemini API calls |
| Model abuse | Rate limiting per user |

## Implementation Steps

1. **Create dedicated service account** with minimal roles
2. **Migrate all secrets to Secret Manager**
3. **Set budget alerts** — `gcloud billing budgets create`
4. **Enable Cloud Audit Logs** for the project
5. **Configure rate limiting** — Cloud Armor or application-level
6. **Set up Gemini API quota** — Limit requests/min in Cloud Console
7. **Review IAM** — Remove overly broad roles

## Common Mistakes

- **Using default compute SA** — Has `roles/editor` by default, way too broad
- **API key in Dockerfile ENV** — Baked into image layer, visible in registry
- **No budget alerts** — A prompt injection loop can burn through API quota fast
- **`--allow-unauthenticated` on internal services** — Only for public-facing endpoints
