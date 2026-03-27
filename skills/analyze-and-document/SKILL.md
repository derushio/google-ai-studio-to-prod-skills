---
name: analyze-and-document
description: Use when first taking over an AI Studio exported project with Claude Code, before any code changes or deployment. Performs deep project analysis and generates CLAUDE.md with architecture, data model, security rules, conventions, and operational notes so that all future Claude Code sessions start with full context.
---

# Analyze and Document AI Studio Project

## Overview

AI Studio から引き継いだプロジェクトを Claude Code で開発する**最初の一歩**。コードを一切変更せず、プロジェクトを徹底的に分析し、`CLAUDE.md` を生成する。以降のすべての Claude Code セッションがこの CLAUDE.md を起点に動く。

**原則:** 理解してから変更する。CLAUDE.md が存在しないプロジェクトでコード変更を始めてはいけない。

## When to Use

- AI Studio からエクスポートしたプロジェクトを初めて Claude Code で開く
- `firebase-applet-config.json` が存在するリポジトリで CLAUDE.md がない
- User says "プロジェクト分析して", "CLAUDE.md作って", "引き継ぎドキュメント作って"
- User says "analyze this project", "create CLAUDE.md", "onboard me to this codebase"

**When NOT to use:**
- CLAUDE.md が既に存在し、内容が最新 → 必要に応じて手動更新
- AI Studio 以外のプロジェクト → 汎用の CLAUDE.md テンプレートを使用

## Execution Flow

```
Phase 1: 全ファイル読み込み・分析 (自動)
  ├── プロジェクトメタデータ収集
  ├── アーキテクチャ分析
  ├── データモデル分析
  ├── セキュリティルール分析
  ├── API エンドポイント分析
  ├── フロントエンド構造分析
  ├── 環境変数・シークレット分析
  └── 既知の問題・技術的負債の検出

Phase 2: 分析結果をユーザーに提示 → 確認・補足

Phase 3: CLAUDE.md 生成
```

## Phase 1: 分析チェックリスト

以下のファイルを**すべて読み込み**、情報を抽出する。ファイルが存在しない場合はスキップし、CLAUDE.md に「未検出」と記録する。

### 1.1 プロジェクトメタデータ

| ファイル | 抽出する情報 |
|---------|------------|
| `metadata.json` | アプリ名、説明文 |
| `package.json` / `requirements.txt` | ランタイム、依存パッケージ、scripts |
| `tsconfig.json` | TypeScript 設定、パスエイリアス |
| `firebase-applet-config.json` | projectId, firestoreDatabaseId, authDomain |

### 1.2 アーキテクチャ分析

| ファイル | 抽出する情報 |
|---------|------------|
| サーバーエントリポイント (`server.ts`, `server.js`, `main.py`) | フレームワーク、ポート番号、ミドルウェア構成、静的ファイル配信パス |
| `vite.config.ts` / `next.config.js` | ビルドツール、プラグイン、環境変数注入 (`define`)、パスエイリアス |
| `index.html` | SPA エントリポイント、外部スクリプト/スタイル |

**検出すべきパターン:**
- Express + Vite middleware（開発時）→ 静的配信（本番時）の切り替え
- `PORT` 環境変数の使用有無（Cloud Run 対応確認）
- HMR 無効化フラグ (`DISABLE_HMR`)

### 1.3 データモデル分析

| ファイル | 抽出する情報 |
|---------|------------|
| `firebase-blueprint.json` | コレクション名、フィールド定義、型、必須項目 |
| `firestore.rules` | アクセス制御パターン（認証ユーザー、オーナー、バックエンド） |
| サーバーコード全体 | Firestore クエリパターン（`where`, `orderBy`, `limit`） |

**出力すべき情報:**
- 各コレクションのスキーマ（フィールド名、型、用途）
- コレクション間のリレーション
- アクセス制御マトリクス（誰が何を読み書きできるか）
- 必要な複合インデックスの推定

### 1.4 API エンドポイント分析

サーバーコードから全 API エンドポイントを抽出:

| 抽出項目 | 例 |
|---------|---|
| メソッド + パス | `POST /api/usage` |
| 認証方式 | Bearer token (`apiSecret` in `user_configs`) |
| リクエスト/レスポンス形状 | `{ inputTokens: number, outputTokens: number, date: string }` |
| バリデーション | 必須フィールド、型チェック |
| エラーハンドリング | ステータスコード、エラーメッセージ |

### 1.5 フロントエンド構造分析

| ファイル | 抽出する情報 |
|---------|------------|
| `src/App.tsx` (メインコンポーネント) | 画面構成、状態管理、Firebase連携パターン |
| `src/components/**` | コンポーネント一覧、UIライブラリの使用 |
| `src/lib/firebase.ts` | Firebase SDK 初期化方法、使用サービス (Auth, Firestore, Storage) |
| `src/lib/*.ts` | ユーティリティ、ヘルパー関数 |

**検出すべき情報:**
- 認証フロー（Google Sign-in, Anonymous Auth 等）
- リアルタイムリスナー (`onSnapshot`) の使用箇所
- クライアントサイドのビジネスロジック

### 1.6 環境変数・シークレット分析

| ファイル | 抽出する情報 |
|---------|------------|
| `.env.example` | 定義済み環境変数 |
| `vite.config.ts` の `define` | フロントエンドに注入される変数 |
| サーバーコードの `process.env.*` | サーバーサイドで使用される変数 |

**セキュリティチェック:**
- `firebase-applet-config.json` に平文 API Key が含まれているか → 警告
- ハードコードされた認証情報がないか
- `.gitignore` に `.env` が含まれているか

### 1.7 既知の問題・技術的負債

AI Studio プロジェクトに共通する問題を検出:

| 問題 | 検出方法 |
|------|---------|
| `PORT` 環境変数未対応 | サーバーコードで `PORT` の使用を検索 |
| `firebase-applet-config.json` に平文 `apiKey` | ファイル内容を確認 |
| Dockerfile が存在しない | ファイル存在チェック |
| CI/CD が存在しない | `.github/workflows/` の存在チェック |
| `firebase.json` が存在しない | ファイル存在チェック |
| 複合インデックス未定義 | `firestore.indexes.json` の存在チェック |
| テストが存在しない | `tests/`, `__tests__/`, `*.test.*`, `*.spec.*` の存在チェック |

## Phase 2: ユーザーへの確認

分析結果を要約して提示し、以下を確認:

```
=== プロジェクト分析完了 ===

アプリ名: Claude Code Utility Dashboard
フレームワーク: Express + Vite (React SPA)
ランタイム: Node.js (TypeScript / tsx)
データベース: Firestore (2 collections: claude_usage, user_configs)
認証: Firebase Auth (Google Sign-in)
API: 1 endpoint (POST /api/usage, Bearer token)

検出した問題:
  ⚠ firebase-applet-config.json に平文 API Key
  ⚠ PORT 環境変数未対応
  ⚠ Dockerfile なし
  ⚠ CI/CD なし
  ⚠ テストなし

確認事項:
  1. 追加で記載すべきビジネスコンテキストはありますか？
     （例: このアプリの利用者、運用上の注意点、既知のバグなど）
  2. 開発時のコマンドや手順で補足はありますか？
```

## Phase 3: CLAUDE.md 生成

以下のテンプレートに沿って `CLAUDE.md` を生成する。**プロジェクトルートに配置**。

```markdown
# CLAUDE.md

## プロジェクト概要

[metadata.json + ユーザー補足から生成]

- **アプリ名:** [名前]
- **概要:** [説明]
- **主要技術:** [フレームワーク, ランタイム, DB]
- **AI Studio プロジェクト:** [projectId] (firestoreDatabaseId: [id])

## アーキテクチャ

[図は ASCII で簡潔に]

```
Client (React SPA)
  ├── Firebase Auth (Google Sign-in)
  ├── Firestore (リアルタイム読み取り)
  └── POST /api/usage → Express Server → Firestore (書き込み)
```

### ディレクトリ構造

```
[実際のディレクトリツリー — 主要ファイルのみ、役割コメント付き]
```

### サーバー構成

- エントリポイント: [ファイル名]
- フレームワーク: [名前 + バージョン]
- ポート: [番号] (⚠ PORT 環境変数未対応の場合は警告)
- 開発モード: [Vite middleware 等の説明]
- 本番モード: [静的配信の説明]

### フロントエンド構成

- ビルドツール: [Vite 等]
- UIライブラリ: [使用コンポーネントライブラリ]
- 状態管理: [方式]
- スタイリング: [TailwindCSS 等]

## データモデル

### [コレクション名1]

| フィールド | 型 | 必須 | 説明 |
|-----------|---|------|------|
| ... | ... | ... | ... |

### [コレクション名2]

[同上]

### アクセス制御

| コレクション | 読み取り | 書き込み | 削除 |
|-------------|---------|---------|------|
| [名前] | [条件] | [条件] | [条件] |

### 複合インデックス（推定）

[コードから推定したインデックスを記載。未定義の場合は生成コマンドも記載]

## API エンドポイント

### [METHOD] [PATH]

- **認証:** [方式]
- **リクエスト:** [形状]
- **レスポンス:** [形状]
- **エラー:** [ステータスコード + 条件]

## 環境変数

| 変数名 | 用途 | 設定場所 | 必須 |
|--------|------|---------|------|
| GEMINI_API_KEY | Gemini API 認証 | Secret Manager / .env | ✅ |
| [他] | ... | ... | ... |

## 開発コマンド

```bash
npm install          # 依存パッケージインストール
npm run dev          # 開発サーバー起動 (http://localhost:XXXX)
npm run build        # プロダクションビルド
npm run lint         # 型チェック
```

## セキュリティ注意事項

- [firebase-applet-config.json の apiKey 問題がある場合はここに警告]
- [その他のセキュリティ関連の注意]

## 既知の問題・技術的負債

- [ ] [検出した問題1]
- [ ] [検出した問題2]
- ...

## AI Studio からの卒業ステータス

| 項目 | 状態 | 対応スキル |
|------|------|-----------|
| firebase-applet-config.json サニタイズ | ❌ 未対応 | export-from-ai-studio |
| Dockerfile | ❌ 未作成 | graduate-from-ai-studio |
| IaC | ❌ 未作成 | graduate-from-ai-studio |
| CI/CD | ❌ 未作成 | ci-cd-github-actions |
| 監視 | ❌ 未設定 | monitoring-sentry-datadog |
| セキュリティ強化 | ❌ 未実施 | security-hardening-gcp |
```

## CLAUDE.md 品質基準

生成した CLAUDE.md は以下を満たすこと:

- **すべてのフィールドが実際のコードから検証済み** — 推測で埋めない。不明な場合は「要確認」と明記
- **コピペ可能なコマンド** — 開発コマンドはそのまま実行可能な形で記載
- **セキュリティ問題を見逃さない** — 平文 API Key、ハードコードされた認証情報は必ず警告
- **次のアクションが明確** — 既知の問題セクションで何をすべきかがわかる
- **卒業ステータス** — 他のスキルとの連携ポイントが一目でわかる

## Common Mistakes

- **分析せずにコード変更を始める** — CLAUDE.md が存在しない AI Studio プロジェクトでは、まずこのスキルを実行する
- **firebase-blueprint.json を無視する** — データモデルの正式な定義がここにある。コードだけ見ると見落とす
- **firestore.rules を読まない** — アクセス制御パターン（isOwner, isBackend 等）を理解しないと認証周りのバグを作る
- **vite.config.ts の `define` を見落とす** — 環境変数がビルド時に注入されるパターンを見逃すと本番で動かない
- **ユーザーへの確認をスキップする** — コードからは読み取れないビジネスコンテキストや運用情報がある
