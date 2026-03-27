# Google AI Studio to Production Skills

Claude Code skills for taking Google AI Studio prototypes to production-ready deployments.

## Overview

Google AI Studio is great for rapid prototyping with Gemini models. But moving from "it works in the playground" to "it runs reliably in production" requires infrastructure, CI/CD, monitoring, and security — all of which these skills automate.

## Skills

| Skill | Description | Trigger Examples |
|-------|-------------|------------------|
| **[analyze-and-document](skills/analyze-and-document/)** | **プロジェクト分析 → CLAUDE.md 生成（最初にやるべきこと）** | **"プロジェクト分析して", "CLAUDE.md作って", "analyze this project"** |
| [export-from-ai-studio](skills/export-from-ai-studio/) | Extract and structure code from AI Studio exports | "AI Studioからコード持ってきて", "export my AI Studio project" |
| [repo-initializer-google](skills/repo-initializer-google/) | Initialize a GitHub repo with Google Cloud best practices | "リポジトリ作って", "set up a new repo for my Gemini app" |
| **[graduate-from-ai-studio](skills/graduate-from-ai-studio/)** | **All-in-one: Dockerfile + IaC + CI/CD + Firebase config generation** | **"AI Studioから卒業", "make this independently deployable"** |
| [cloud-run-deploy](skills/cloud-run-deploy/) | Deploy to Google Cloud Run with production-ready config | "Cloud Runにデプロイして", "deploy this to Cloud Run" |
| [vercel-railway-deploy](skills/vercel-railway-deploy/) | Deploy to Vercel or Railway | "Vercelにデプロイ", "deploy to Railway" |
| [ci-cd-github-actions](skills/ci-cd-github-actions/) | Set up GitHub Actions CI/CD pipelines | "CI/CD設定して", "add GitHub Actions" |
| [monitoring-sentry-datadog](skills/monitoring-sentry-datadog/) | Add monitoring with Sentry and/or Datadog | "監視入れて", "add error tracking", "set up monitoring" |
| [security-hardening-gcp](skills/security-hardening-gcp/) | Harden GCP security (IAM, Secret Manager, etc.) | "セキュリティ設定して", "secure my GCP deployment" |

## Typical Workflow

```
AI Studio prototype
    ↓
0. analyze-and-document        — ★ まず最初に！プロジェクト全体分析 → CLAUDE.md 生成
    ↓
1. export-from-ai-studio       — コードを抽出・整形
    ↓
2. repo-initializer-google     — GitHub リポ作成 + 初期構成
    ↓
3. graduate-from-ai-studio     — 一括卒業 (Dockerfile + IaC + CI/CD + Firebase)
    ↓                              Terraform / Pulumi / CLI スクリプトから選択
    ↓                              GitHub Actions 自動デプロイ構築
    ↓
4. monitoring-sentry-datadog   — 監視・アラート設定
    ↓
5. security-hardening-gcp      — セキュリティ強化
```

> **Note:** `graduate-from-ai-studio` は `cloud-run-deploy` と `ci-cd-github-actions` の機能を統合しています。個別のスキルは単体でも利用可能です。

## Documentation

- [AI Studio が生成するプロジェクトの構造](docs/ai-studio-project-anatomy.md) — スキルが前提とする共通パターン
- [graduate スキルの設計判断](docs/graduate-skill-design-decisions.md) — 設計時の判断理由の記録

## Installation

### Via `npx skills` CLI (recommended)

```bash
# Install all skills
npx skills add takuro/google-ai-studio-to-prod-skills

# Install a specific skill only
npx skills add takuro/google-ai-studio-to-prod-skills --skill graduate-from-ai-studio

# For Claude Code specifically
npx skills add takuro/google-ai-studio-to-prod-skills -a claude-code -y
```

### Via Claude Code `/install` command

```
/install takuro/google-ai-studio-to-prod-skills
```

### Manual (clone and reference locally)

```bash
git clone https://github.com/takuro/google-ai-studio-to-prod-skills.git
```

## Requirements

- Claude Code CLI
- Google Cloud SDK (`gcloud`) — for GCP-related skills
- GitHub CLI (`gh`) — for repo initialization and CI/CD
- Node.js 18+ or Python 3.11+ — depending on your AI Studio export

## License

See [LICENSE](LICENSE) for details.
