#!/bin/bash
set -euo pipefail

# ============================================================
# Deploy Firestore rules and indexes only
# ============================================================
# Usage: bash firebase-deploy.sh --project PROJECT_ID

PROJECT_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT_ID="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  echo "Usage: bash firebase-deploy.sh --project PROJECT_ID"
  exit 1
fi

echo "=== Deploying Firestore configuration ==="
echo "Project: $PROJECT_ID"
echo ""

firebase deploy --only firestore:rules --project "$PROJECT_ID"
firebase deploy --only firestore:indexes --project "$PROJECT_ID"

echo ""
echo "=== Firestore deploy complete ==="
