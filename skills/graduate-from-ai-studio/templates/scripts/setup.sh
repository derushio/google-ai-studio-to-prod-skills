#!/bin/bash
set -euo pipefail

# ============================================================
# AI Studio Graduation - Initial Setup Script
# ============================================================
# Usage: bash setup.sh --project PROJECT_ID --service SERVICE_NAME [--region REGION] [--new-firebase]

PROJECT_ID=""
SERVICE_NAME=""
REGION="asia-northeast1"
NEW_FIREBASE=false
GITHUB_REPO=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT_ID="$2"; shift 2 ;;
    --service) SERVICE_NAME="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --new-firebase) NEW_FIREBASE=true; shift ;;
    --github-repo) GITHUB_REPO="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_ID" || -z "$SERVICE_NAME" ]]; then
  echo "Usage: bash setup.sh --project PROJECT_ID --service SERVICE_NAME [--region REGION] [--new-firebase] [--github-repo OWNER/REPO]"
  exit 1
fi

echo "=== AI Studio Graduation Setup ==="
echo "Project:  $PROJECT_ID"
echo "Service:  $SERVICE_NAME"
echo "Region:   $REGION"
echo "New Firebase: $NEW_FIREBASE"
echo ""

# Set project
gcloud config set project "$PROJECT_ID"

# Enable APIs
echo ">>> Enabling APIs..."
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com \
  firestore.googleapis.com

# Create Artifact Registry repo
echo ">>> Creating Artifact Registry repository..."
gcloud artifacts repositories create cloud-run-builds \
  --repository-format=docker \
  --location="$REGION" \
  --description="Cloud Run Docker images" \
  2>/dev/null || echo "  (already exists)"

# Create service account
SA_EMAIL="${SERVICE_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com"
echo ">>> Creating service account: $SA_EMAIL"
gcloud iam service-accounts create "${SERVICE_NAME}-sa" \
  --display-name="${SERVICE_NAME} Cloud Run SA" \
  2>/dev/null || echo "  (already exists)"

# Grant roles
echo ">>> Granting IAM roles..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/datastore.user" \
  --quiet

# Create secrets
echo ">>> Creating Secret Manager secrets..."
if ! gcloud secrets describe gemini-api-key --project="$PROJECT_ID" &>/dev/null; then
  echo "  Creating gemini-api-key secret (you'll need to add the value)..."
  echo -n "PLACEHOLDER" | gcloud secrets create gemini-api-key --data-file=- --project="$PROJECT_ID"
  echo "  WARNING: Set the actual GEMINI_API_KEY value:"
  echo "    echo -n 'YOUR_KEY' | gcloud secrets versions add gemini-api-key --data-file=-"
else
  echo "  gemini-api-key already exists"
fi

# Create Firestore database (if new project)
if [[ "$NEW_FIREBASE" == true ]]; then
  echo ">>> Creating Firestore database..."
  gcloud firestore databases create \
    --location="$REGION" \
    --type=firestore-native \
    2>/dev/null || echo "  (already exists)"
fi

# Set up Workload Identity Federation (if GitHub repo provided)
if [[ -n "$GITHUB_REPO" ]]; then
  echo ">>> Setting up Workload Identity Federation for GitHub Actions..."

  # Create pool
  gcloud iam workload-identity-pools create github-actions \
    --location=global \
    --display-name="GitHub Actions" \
    2>/dev/null || echo "  (pool already exists)"

  # Create provider
  gcloud iam workload-identity-pools providers create-oidc github \
    --location=global \
    --workload-identity-pool=github-actions \
    --display-name="GitHub" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    2>/dev/null || echo "  (provider already exists)"

  # Bind SA
  POOL_NAME=$(gcloud iam workload-identity-pools describe github-actions --location=global --format="value(name)")
  gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" \
    --quiet

  # Get provider resource name
  WIF_PROVIDER=$(gcloud iam workload-identity-pools providers describe github \
    --location=global \
    --workload-identity-pool=github-actions \
    --format="value(name)")

  echo ""
  echo "=== GitHub Secrets to set ==="
  echo "WIF_PROVIDER:        $WIF_PROVIDER"
  echo "WIF_SERVICE_ACCOUNT: $SA_EMAIL"
  echo "GCP_PROJECT_ID:      $PROJECT_ID"
fi

echo ""
echo "=== Setup complete ==="
echo "Next: Build and deploy with deploy.sh"
