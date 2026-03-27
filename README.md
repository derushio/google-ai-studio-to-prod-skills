# Google AI Studio to Production Skills

Google AI Studio のプロトタイプを本番環境に持っていくための Claude Code スキル集。

## Overview

Google AI Studio は Gemini モデルを使った高速プロトタイピングに最適ですが、「プレイグラウンドで動く」から「本番で安定稼働する」までには、プロジェクト分析・コード整形・インフラ構築・CI/CD・監視・セキュリティが必要です。これらをスキルで自動化します。

## Skills

### ワンパスマイグレーション

| Skill | Description | Trigger Examples |
|-------|-------------|------------------|
| **[migrate-wizard](skills/migrate-wizard/)** | 全ステップをワンパスで実行するウィザード。自動検出 → 一括質問 → 順次実行 | "本番に移行して", "migrate to production", "ワンパスでマイグレーション" |

> **初めての方はこれだけで OK。** 完了済みステップは自動スキップ、途中参加も可能です。v1 は Cloud Run のみ対応。

### 初期セットアップ（Step 0）

| Skill | Description | Trigger Examples |
|-------|-------------|------------------|
| **[analyze-and-document](skills/analyze-and-document/)** | プロジェクト全体分析 → CLAUDE.md 生成（最初にやるべきこと） | "プロジェクト分析して", "CLAUDE.md作って", "analyze this project" |
| **[setup-dev-environment](skills/setup-dev-environment/)** | `.claude/` ディレクトリを一括セットアップ（rules, skills, settings, hooks） | "開発環境セットアップして", "setup dev environment", ".claude設定して" |

`setup-dev-environment` は以下を**必須**でインストールします:

- `.claude/rules/` — セキュリティ、Firebase、コーディングルール
- `.claude/skills/` — ローカル開発サーバー操作、Firestore 管理
- `.claude/hooks/prevent-api-key-commit.sh` — API Key のハードコードをブロック
- `.claude/settings.json` — パーミッション + API Key 防止 hook

さらに、以下を**オプション**で追加できます:

| Option | 内容 |
|--------|------|
| **Agents** | コードレビュー + セキュリティ監査エージェント |
| **Hooks (追加)** | prettier / biome フォーマッター自動実行 |
| **MCP** | Firebase Emulator 連携 |

### コード整形・リポジトリ構築

| Skill | Description | Trigger Examples |
|-------|-------------|------------------|
| [export-from-ai-studio](skills/export-from-ai-studio/) | AI Studio エクスポートのコード抽出・整形・API Key サニタイズ | "AI Studioからコード持ってきて", "export my AI Studio project" |
| [repo-initializer-google](skills/repo-initializer-google/) | GitHub リポ作成 + .gitignore / README / GCP 向け初期構成 | "リポジトリ作って", "set up a new repo for my Gemini app" |

### デプロイ・インフラ

| Skill | Description | Trigger Examples |
|-------|-------------|------------------|
| **[graduate-from-ai-studio](skills/graduate-from-ai-studio/)** | 一括卒業: Dockerfile + IaC + CI/CD + Firebase 設定を一括生成 | "AI Studioから卒業", "make this independently deployable" |
| [cloud-run-deploy](skills/cloud-run-deploy/) | Google Cloud Run へのデプロイ（Secret Manager, IAM 込み） | "Cloud Runにデプロイして", "deploy this to Cloud Run" |
| [vercel-railway-deploy](skills/vercel-railway-deploy/) | Vercel / Railway へのデプロイ | "Vercelにデプロイ", "deploy to Railway" |
| [ci-cd-github-actions](skills/ci-cd-github-actions/) | GitHub Actions CI/CD パイプライン構築 | "CI/CD設定して", "add GitHub Actions" |

> **Note:** `graduate-from-ai-studio` は `cloud-run-deploy` と `ci-cd-github-actions` の機能を統合しています。個別のスキルは単体でも利用可能です。

### 運用・セキュリティ

| Skill | Description | Trigger Examples |
|-------|-------------|------------------|
| [monitoring-sentry-datadog](skills/monitoring-sentry-datadog/) | Sentry / Datadog による監視・エラートラッキング | "監視入れて", "add error tracking", "set up monitoring" |
| [security-hardening-gcp](skills/security-hardening-gcp/) | GCP セキュリティ強化（IAM, Secret Manager, API Key 制限） | "セキュリティ設定して", "secure my GCP deployment" |

## Typical Workflow

```mermaid
flowchart TD
    Start["🧪 AI Studio Prototype"] --> A

    subgraph init["初期セットアップ"]
        A["<b>0. analyze-and-document</b><br/>プロジェクト全体分析 → CLAUDE.md 生成"]
        A --> B["<b>0.5 setup-dev-environment</b><br/>.claude/ 一括セットアップ<br/>(rules, skills, hooks, settings)"]
    end

    subgraph code["コード整形・リポ構築"]
        C["<b>1. export-from-ai-studio</b><br/>コード抽出・整形<br/>firebase-applet-config.json サニタイズ"]
        C --> D["<b>2. repo-initializer-google</b><br/>GitHub リポ作成 + 初期構成"]
    end

    subgraph deploy["デプロイ・インフラ"]
        E["<b>3. graduate-from-ai-studio</b><br/>Dockerfile + IaC + CI/CD + Firebase<br/>= cloud-run-deploy + ci-cd-github-actions"]
    end

    subgraph ops["運用・セキュリティ"]
        F["<b>4. monitoring-sentry-datadog</b><br/>監視・アラート設定"]
        F --> G["<b>5. security-hardening-gcp</b><br/>IAM, Secret Manager, API Key 制限"]
    end

    B --> C
    D --> E
    E --> F
    G --> Prod["🚀 Production"]

    style Start fill:#f9f,stroke:#333
    style Prod fill:#9f9,stroke:#333
    style init fill:#fff3e0,stroke:#ff9800
    style code fill:#e3f2fd,stroke:#2196f3
    style deploy fill:#fce4ec,stroke:#e91e63
    style ops fill:#e8f5e9,stroke:#4caf50
```

各スキルは単体でも利用可能です。ワークフロー全体を通す必要はありません。

## Security

AI Studio が生成するプロジェクトには以下のセキュリティ上の注意点があります:

- **`firebase-applet-config.json` に平文 API Key** — `export-from-ai-studio` で環境変数に外出し、`setup-dev-environment` の hook でコミット防止
- **Gemini API Key がハードコードされる場合がある** — Secret Manager へ移行
- **Firebase Web API Key に利用制限なし** — Google Cloud Console でリファラー制限を設定

詳細は [security-hardening-gcp](skills/security-hardening-gcp/) スキルを参照。

## Deploy Guide

AI Studio では「Publish」ボタン1つでデプロイできましたが、卒業後は自分のインフラにデプロイします。`migrate-wizard` または `graduate-from-ai-studio` を実行済みであれば、CI/CD パイプラインと IaC が生成されています。

### GCP / Cloud Run（デフォルト）

#### 初回セットアップ（どちらの方法でも共通）

`migrate-wizard` 完了時の「手動作業」リストに沿って進めます:

```bash
# 1. GCP プロジェクト作成（新規プロジェクトの場合）
gcloud projects create YOUR_PROJECT_ID
gcloud config set project YOUR_PROJECT_ID
firebase projects:addfirebase YOUR_PROJECT_ID

# 2. IaC でインフラ構築（Cloud Run, Artifact Registry, IAM, Secret Manager）
# Terraform の場合:
cd infra/terraform && terraform init && terraform plan && terraform apply

# Pulumi の場合:
cd infra/pulumi && npm install && pulumi up

# CLI スクリプトの場合:
bash infra/scripts/setup.sh

# 3. Firestore ルール・インデックスのデプロイ
firebase deploy --only firestore
```

初回セットアップが完了したら、以下の **A** または **B** いずれかの方法でデプロイします。

#### 方法 A: CI/CD 自動デプロイ（推奨）

> **`git push` = AI Studio の「Publish」ボタン。** main に push するだけで自動デプロイされます。

**初回のみ追加で必要な設定:**

```bash
# Workload Identity Federation 設定（GitHub Actions → GCP の認証）
# 詳細: https://github.com/google-github-actions/auth#workload-identity-federation

# GitHub Secrets 設定
gh secret set WIF_PROVIDER --body "projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER"
gh secret set WIF_SERVICE_ACCOUNT --body "SA_NAME@PROJECT_ID.iam.gserviceaccount.com"
gh secret set GCP_PROJECT_ID --body "YOUR_PROJECT_ID"
```

**デプロイ（初回も2回目以降も同じ）:**

```bash
git add .
git commit -m "Update feature X"
git push origin main
```

GitHub Actions (`.github/workflows/deploy.yml`) が自動で以下を実行します:

1. Docker イメージをビルド
2. Artifact Registry に push
3. Cloud Run サービスを更新
4. Firestore ルール・インデックスをデプロイ

#### 方法 B: 手動デプロイ

> GitHub Actions を使わず、ローカルから直接デプロイする方法。CI/CD の設定が不要で手軽ですが、毎回手動実行が必要です。

```bash
# Cloud Run に直接デプロイ
gcloud run deploy SERVICE_NAME --source . --region asia-northeast1

# Firestore ルールのデプロイ
firebase deploy --only firestore:rules

# Firestore インデックスのデプロイ
firebase deploy --only firestore:indexes
```

#### デプロイの確認（A / B 共通）

```bash
# Cloud Run サービスの URL を確認
gcloud run services describe SERVICE_NAME --region asia-northeast1 --format='value(status.url)'

# ログを確認
gcloud run services logs read SERVICE_NAME --region asia-northeast1 --limit 50

# ヘルスチェック
curl https://YOUR_SERVICE_URL/health
```

### Vercel

> **TODO:** Vercel デプロイガイドは準備中です。現時点では [vercel-railway-deploy](skills/vercel-railway-deploy/) スキルを参照してください。
>
> 対応予定:
> - Next.js / React SPA の Vercel デプロイ手順
> - 環境変数の設定（Gemini API Key, Firebase config）
> - Firestore との接続設定
> - カスタムドメイン設定

## Documentation

- [AI Studio が生成するプロジェクトの構造](docs/ai-studio-project-anatomy.md) — スキルが前提とする共通パターン
- [graduate スキルの設計判断](docs/graduate-skill-design-decisions.md) — 設計時の判断理由の記録

## Installation

### Via Plugin Marketplace (recommended)

```bash
# 1. マーケットプレイスとして登録
/plugin marketplace add --source github:TakuroFukamizu/google-ai-studio-to-prod-skills

# 2. プラグインをインストール
/plugin install google-ai-studio-to-prod@google-ai-studio-to-prod-skills
```

### Via `npx skills` CLI

```bash
# Install all skills
npx skills add TakuroFukamizu/google-ai-studio-to-prod-skills

# Install a specific skill only
npx skills add TakuroFukamizu/google-ai-studio-to-prod-skills --skill graduate-from-ai-studio

# For Claude Code specifically
npx skills add TakuroFukamizu/google-ai-studio-to-prod-skills -a claude-code -y
```

### Via Claude Code `/install` command

```
/install TakuroFukamizu/google-ai-studio-to-prod-skills
```

### Manual (clone and reference locally)

```bash
git clone https://github.com/TakuroFukamizu/google-ai-studio-to-prod-skills.git
```

## Update

インストール方法によって更新手順が異なります:

| インストール方法 | 更新コマンド |
|----------------|-------------|
| Plugin Marketplace | `/plugin marketplace update google-ai-studio-to-prod-skills` |
| `npx skills` | `npx skills add TakuroFukamizu/google-ai-studio-to-prod-skills`（再インストール） |
| `/install` | `/install TakuroFukamizu/google-ai-studio-to-prod-skills`（再インストール） |
| Manual clone | `git pull origin main` → `/reload-plugins` またはセッション再起動 |

## Requirements

- Claude Code CLI
- Google Cloud SDK (`gcloud`) — GCP 関連スキルに必要
- GitHub CLI (`gh`) — リポ初期化・CI/CD に必要
- Node.js 18+ or Python 3.11+ — AI Studio エクスポートに依存

## License

See [LICENSE](LICENSE) for details.
