# graduate-from-ai-studio スキルの設計判断

`graduate-from-ai-studio` スキルを設計する際に行った判断とその理由を記録する。

## スキルのスコープ

**判断:** Dockerfile + IaC + CI/CD + Firebase 設定をすべてカバーする「オールインワン」スキル

**理由:** AI Studio プロジェクトの「卒業」は、既存の個別スキル（`cloud-run-deploy`, `ci-cd-github-actions`）を順番に実行するだけでは不十分。以下が足りない:
- Firestore rules/indexes のデプロイ設定（`firebase.json`）
- IaC によるインフラのコード管理
- AI Studio 固有の構造（`firebase-applet-config.json` 等）の検出と対応
- Firebase プロジェクトの移行判断

個別スキルは単体でも利用可能なまま残し、`graduate-from-ai-studio` はそれらを統合した上位スキルとして位置づける。

## 実行スタイル: プラン生成 → 一括実行

**判断:** 対話型ウィザードではなく、プランを提示して承認後に一括生成する方式

**理由:**
- 生成するファイル数が多い（10+ファイル）ため、1つずつ確認すると時間がかかりすぎる
- ファイル間の整合性（IaC のリソース名と GitHub Actions の参照名の一致等）を保つには一括生成が適切
- ユーザーは生成後にコードレビューできるため、事前承認はプランレベルで十分

## ユーザー選択肢の設計

### Firebase プロジェクト: 新規 or 既存

**判断:** スキル実行時にユーザーに選ばせる

**理由:**
- 新規プロジェクトは完全な独立を得られるが、データ移行が必要
- 既存（`gen-lang-client-*`）の継続は手軽だが、Google 管理プロジェクトへの依存が残る
- どちらが正解かはユースケース次第。プロトタイプ段階なら既存で十分、本番運用なら新規が推奨

### IaC ツール: Terraform / Pulumi / CLI スクリプト

**判断:** 3つの選択肢を提示し、ユーザーに選ばせる

**理由:**
- **Terraform** — GCP エコシステムで最も成熟。チーム開発に最適。ただし HCL の学習コストがある
- **Pulumi (TypeScript)** — AI Studio プロジェクトが TypeScript の場合、言語を統一できる。プログラマティックに書ける
- **CLI スクリプト** — 学習コスト最小。IaC ツールの導入が大げさに感じるプロトタイプ段階に最適
- 1つに絞ると、そのツールを使わないユーザーにとってスキルの価値が下がる

### CI/CD: GitHub Actions のみ（初期）

**判断:** 初期は GitHub Actions のみサポート。Cloud Build 等は後で拡張可能な設計にする

**理由:**
- GitHub リポジトリが最も一般的なホスティング先
- Workload Identity Federation による keyless 認証が成熟している
- Cloud Build サポートは `cloudbuild.yaml` テンプレートを追加するだけで拡張可能

## セキュリティ方針

### Workload Identity Federation (WIF) を必須とする

**判断:** GitHub Actions → GCP 認証にサービスアカウントキーではなく WIF を使う

**理由:**
- サービスアカウントキー（JSON）はリーク時のリスクが高い
- WIF は keyless で、GitHub リポジトリ単位でアクセスを制限できる
- Google 公式の `google-github-actions/auth` が WIF をネイティブサポート

### Secret Manager を必須とする

**判断:** `GEMINI_API_KEY` 等のシークレットは Cloud Run の環境変数ではなく Secret Manager で管理

**理由:**
- 環境変数は Cloud Run の設定画面やログに平文で表示されるリスクがある
- Secret Manager はアクセス監査、バージョン管理、ローテーションが可能
- IaC で Secret のリソース定義だけ作り、値の設定は手動（IaC にシークレット値を書かない）

## テンプレート設計

### テンプレートの変数埋め込み方式

**判断:** `{{PLACEHOLDER}}` 形式のテンプレート変数を使い、スキル実行時に置換

**理由:**
- Terraform/Pulumi は変数機構を持つため、テンプレート変数は最小限
- シェルスクリプトと GitHub Actions は引数・secrets で動的に値を渡す設計
- `firebase-applet-config.json` のプロジェクト ID 等は、Phase 1 の分析結果から自動で埋め込む

### Dockerfile: マルチステージビルド

**判断:** builder → production の2ステージ構成

**理由:**
- フロントエンド（Vite）のビルド成果物（`dist/`）だけを production イメージにコピー
- `npm ci --omit=dev` で production 依存のみインストールし、イメージサイズを削減
- AI Studio プロジェクトは `tsx` で TypeScript を直接実行する構成が多いため、production イメージにも `tsx` が必要
