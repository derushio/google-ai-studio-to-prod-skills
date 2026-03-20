#!/bin/bash
set -euo pipefail

# ============================================================
# AI Studio Graduation - Deploy Script
# ============================================================
# Usage: bash deploy.sh --project PROJECT_ID --service SERVICE_NAME [--region REGION] [--tag TAG]

PROJECT_ID=""
SERVICE_NAME=""
REGION="asia-northeast1"
TAG="latest"
REPO_NAME="cloud-run-builds"

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT_ID="$2"; shift 2 ;;
    --service) SERVICE_NAME="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_ID" || -z "$SERVICE_NAME" ]]; then
  echo "Usage: bash deploy.sh --project PROJECT_ID --service SERVICE_NAME [--region REGION] [--tag TAG]"
  exit 1
fi

SA_EMAIL="${SERVICE_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:${TAG}"

echo "=== Deploying ${SERVICE_NAME} ==="
echo "Image: $IMAGE"
echo ""

# Configure Docker auth
echo ">>> Configuring Docker for Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

# Build
echo ">>> Building Docker image..."
docker build -t "$IMAGE" .

# Push
echo ">>> Pushing to Artifact Registry..."
docker push "$IMAGE"

# Deploy to Cloud Run
echo ">>> Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --image="$IMAGE" \
  --region="$REGION" \
  --service-account="$SA_EMAIL" \
  --set-secrets="GEMINI_API_KEY=gemini-api-key:latest" \
  --allow-unauthenticated \
  --quiet

# Deploy Firebase rules and indexes
echo ">>> Deploying Firestore rules and indexes..."
firebase deploy --only firestore --project "$PROJECT_ID"

# Get URL
URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)")
echo ""
echo "=== Deploy complete ==="
echo "URL: $URL"
