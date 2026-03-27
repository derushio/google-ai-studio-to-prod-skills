---
name: setup-dev-environment
description: Use after analyze-and-document has generated CLAUDE.md for an AI Studio project. Installs project-level Claude Code configuration — rules, skills, settings, and optionally agents, hooks, and MCP servers — into the .claude/ directory so that all future sessions have the right guardrails and workflows.
---

# Setup Dev Environment for AI Studio Projects

## Overview

`analyze-and-document` で CLAUDE.md を生成した後の**次のステップ**。プロジェクトの `.claude/` ディレクトリに rules、skills、settings を一括インストールし、Claude Code の開発環境を整える。

**前提:** CLAUDE.md が存在すること。存在しない場合は先に `analyze-and-document` を実行する。

## When to Use

- `analyze-and-document` 完了直後
- AI Studio プロジェクトに `.claude/` ディレクトリがない
- User says "開発環境セットアップして", "setup dev environment", ".claude設定して"
- User says "ルールとスキル入れて", "install project rules"

**When NOT to use:**
- CLAUDE.md がまだ存在しない → 先に `analyze-and-document`
- 既に `.claude/` が整備されている → 必要な部分だけ手動更新

## Execution Flow

### Phase 1: 必須インストール（自動）

以下は常にインストールする:

- `.claude/rules/` — セキュリティ、Firebase、コーディングルール
- `.claude/skills/` — プロジェクト内ワークフロー
- `.claude/settings.json` — パーミッション設定
- `.claude/hooks/prevent-api-key-commit.sh` — API Key コミット防止 hook

### Phase 2: オプション選択

以下をユーザーに提示し、必要なものを選択:

| Option | 内容 | 推奨 |
|--------|------|------|
| **Agents** | コードレビュー、セキュリティ監査の専用エージェント | 中〜大規模プロジェクト |
| **Hooks (追加)** | フォーマッター自動実行 | prettier / biome 使用時 |
| **MCP** | Firebase Emulator 連携 | Firestore 使用時 |

### Phase 3: ファイル生成

---

## Phase 1: 必須インストール

### 1.1 Rules（`.claude/rules/`）

#### `.claude/rules/security.md`

```markdown
---
description: Security rules for AI Studio projects — applies to all files
---

# Security Rules

## API Key の取り扱い

- `firebase-applet-config.json` の `apiKey` フィールドにハードコードされた値をコミットしてはいけない
- API Key は必ず環境変数経由で注入する（`process.env.FIREBASE_API_KEY`）
- Gemini API Key (`GEMINI_API_KEY`) をソースコードに直接書いてはいけない
- `.env` ファイルをコミットしてはいけない

## Secret の検出

以下のパターンがコードに含まれていたら警告する:
- `AIzaSy` で始まる文字列（Firebase/Google API Key）
- `sk-` で始まる文字列（OpenAI 等の API Key）
- `service-account*.json` ファイルの追加

## 環境変数

- 新しい環境変数を追加したら `.env.example` も更新する
- Secret Manager に格納すべき値を平文の環境変数にしない
```

#### `.claude/rules/firebase.md`

```markdown
---
description: Firebase and Firestore conventions for AI Studio projects
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "firestore.rules"
  - "firebase-blueprint.json"
---

# Firebase / Firestore Rules

## Firestore クエリ

- 複合クエリ（`where` + `where`、`where` + `orderBy`）を追加したら `firestore.indexes.json` にインデックスを追加する
- `onSnapshot` リスナーは必ずクリーンアップする（useEffect の return で unsubscribe）
- コレクション名は `firebase-blueprint.json` に定義されたものを使う

## Firebase Auth

- 認証状態の変更は `onAuthStateChanged` で監視する
- サーバーサイドでの認証は Bearer token パターンを使う（`user_configs.apiSecret`）
- 新しい認証プロバイダーを追加したら Firebase Console の承認済みドメインも更新する

## Security Rules

- `firestore.rules` を変更したらデプロイパイプラインでも反映されることを確認する
- `isOwner()`, `isBackend()` 等のヘルパー関数パターンを維持する
- テスト用にルールを緩めてはいけない（`allow read, write: if true` は禁止）
```

#### `.claude/rules/coding-standards.md`

CLAUDE.md の内容から検出したプロジェクトの技術スタックに合わせて生成する。以下はテンプレート:

```markdown
---
description: Coding standards derived from the project's existing patterns
---

# Coding Standards

## 一般

- 既存のコードスタイルに従う（インデント、命名規則、ファイル構成）
- 型定義を省略しない（TypeScript プロジェクトの場合）
- `any` 型を使わない

## コンポーネント

- UI コンポーネントは `src/components/` に配置
- ユーティリティ関数は `src/lib/` に配置
- 新しいコンポーネントは既存の UI ライブラリ（プロジェクト内の components/ui/）を使う

## エラーハンドリング

- API 呼び出しは try-catch で囲む
- ユーザー向けのエラーメッセージと開発者向けのログを分離する
- Firestore 操作のエラーは具体的な例外型でキャッチする
```

**注意:** `coding-standards.md` の内容は CLAUDE.md から検出した技術スタックに合わせてカスタマイズする。上記は Node.js + TypeScript + React の例。

### 1.2 Skills（`.claude/skills/`）

#### `.claude/skills/dev-server/SKILL.md`

CLAUDE.md の「開発コマンド」セクションから生成する:

```yaml
---
name: dev-server
description: Use when user wants to start, restart, or check the local development server
---
```

```markdown
# Dev Server

## Start

CLAUDE.md の開発コマンドセクションに記載されたコマンドを実行する。

一般的なパターン:

1. 依存パッケージが最新か確認（`package-lock.json` の変更を検出）
2. `.env` または `.env.local` が存在するか確認
3. 開発サーバーを起動

## Troubleshooting

- ポートが使用中の場合: `lsof -i :PORT` で確認し、ユーザーに報告
- 依存パッケージエラーの場合: `rm -rf node_modules && npm install`
- 環境変数が不足している場合: `.env.example` と比較して不足を報告
```

#### `.claude/skills/firestore-ops/SKILL.md`

Firestore を使用するプロジェクトでのみ生成:

```yaml
---
name: firestore-ops
description: Use when user wants to query, inspect, or modify Firestore data locally or manage security rules and indexes
---
```

```markdown
# Firestore Operations

## Security Rules の更新

1. `firestore.rules` を編集
2. 変更内容がアクセス制御マトリクス（CLAUDE.md 参照）と整合するか確認
3. ルールのデプロイ: `firebase deploy --only firestore:rules`

## インデックスの管理

1. 新しい複合クエリを追加した場合、`firestore.indexes.json` を更新
2. デプロイ: `firebase deploy --only firestore:indexes`
3. Firestore エミュレータで動作確認

## データの確認

Firebase Emulator が稼働している場合:
- Emulator UI: http://localhost:4000
- REST API: `curl http://localhost:8080/v1/projects/PROJECT_ID/databases/DB_ID/documents/COLLECTION`
```

### 1.3 Hook — API Key コミット防止（`.claude/hooks/prevent-api-key-commit.sh`）

Edit / Write 時に API Key のハードコードをブロックする。**これは必須で常にインストールする。**

```bash
#!/bin/bash
# Prevent committing hardcoded API keys
# Called as a PreToolUse hook on Edit/Write tools

INPUT=$(cat)
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Check for API key patterns in content being written
if echo "$CONTENT" | grep -qE 'AIzaSy[a-zA-Z0-9_-]{33}'; then
  echo '{"decision": "block", "reason": "Firebase/Google API Key がハードコードされています。環境変数を使用してください。"}'
  exit 0
fi

if echo "$CONTENT" | grep -qE '"apiKey"\s*:\s*"AIzaSy'; then
  echo '{"decision": "block", "reason": "firebase-applet-config.json に平文の apiKey を書き込もうとしています。環境変数 FIREBASE_API_KEY を使用してください。"}'
  exit 0
fi

exit 0
```

生成後に `chmod +x .claude/hooks/prevent-api-key-commit.sh` を実行する。

### 1.4 Settings（`.claude/settings.json`）

permissions と API Key 防止 hook を含む:

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Edit(**)",
      "Write(**)",
      "Glob(**)",
      "Grep(**)",
      "Bash(npm run *)",
      "Bash(npm install *)",
      "Bash(npm test *)",
      "Bash(npx *)",
      "Bash(firebase emulators:*)",
      "Bash(firebase deploy *)",
      "Bash(gcloud run *)",
      "Bash(git *)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(git push --force *)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/prevent-api-key-commit.sh"
          }
        ]
      }
    ]
  }
}
```

**注意:** settings.json の内容はプロジェクトで使用するツールチェーンに合わせてカスタマイズする。Python プロジェクトなら `pip`, `pytest` 等を追加。

---

## Phase 2: オプション選択

Phase 1 の生成が完了したら、以下を提示:

```
=== 必須インストール完了 ===

✓ .claude/rules/security.md
✓ .claude/rules/firebase.md
✓ .claude/rules/coding-standards.md
✓ .claude/skills/dev-server/SKILL.md
✓ .claude/skills/firestore-ops/SKILL.md
✓ .claude/hooks/prevent-api-key-commit.sh
✓ .claude/settings.json (permissions + API Key 防止 hook)

=== 追加オプション ===

以下を追加でインストールしますか？（複数選択可）

  [A] Agents — コードレビュー + セキュリティ監査エージェント
      .claude/agents/code-reviewer/AGENT.md
      .claude/agents/security-auditor/AGENT.md

  [B] Hooks (追加) — フォーマッター自動実行
      settings.json に PostToolUse hook 追加 (prettier / biome)

  [C] MCP — Firebase Emulator 連携
      .mcp.json

  [N] なし — 必須構成のみで進める

選択してください (例: A,B / AB / N):
```

---

## Option A: Agents

### `.claude/agents/code-reviewer/AGENT.md`

```yaml
---
name: code-reviewer
description: Reviews code changes for quality, security, and consistency with project conventions
model: sonnet
---
```

```markdown
# Code Reviewer

プロジェクトの CLAUDE.md と .claude/rules/ に基づいてコードレビューを行う。

## レビュー観点

1. **セキュリティ** — API Key のハードコード、firebase-applet-config.json の apiKey 漏洩、認証バイパス
2. **Firestore** — Security Rules との整合性、複合インデックスの追加漏れ、リスナーのクリーンアップ
3. **型安全性** — any の使用、型定義の欠如
4. **エラーハンドリング** — 未処理の Promise、Firestore 操作のエラーハンドリング

## 出力フォーマット

| ファイル | 行 | 重要度 | 指摘内容 |
|---------|---|--------|---------|

重要度: Critical / Warning / Info
```

### `.claude/agents/security-auditor/AGENT.md`

```yaml
---
name: security-auditor
description: Audits the project for security issues specific to AI Studio and Firebase applications
model: sonnet
---
```

```markdown
# Security Auditor

AI Studio プロジェクト特有のセキュリティリスクを監査する。

## チェック項目

1. **firebase-applet-config.json**
   - apiKey がプレースホルダーになっているか
   - git history に平文の apiKey が残っていないか

2. **環境変数**
   - GEMINI_API_KEY がコードにハードコードされていないか
   - .env がコミットされていないか
   - .env.example が最新か

3. **Firestore Security Rules**
   - `allow read, write: if true` が存在しないか
   - 認証チェック（isAuthenticated, isOwner）が適切か
   - バックエンドアクセスのスコープが最小限か

4. **依存パッケージ**
   - 既知の脆弱性がないか（npm audit）
   - 不要な依存がないか

## 出力

各項目について PASS / FAIL / WARNING を報告し、FAIL の場合は修正手順を提示する。
```

---

## Option B: Hooks (追加) — フォーマッター自動実行

> **Note:** API Key コミット防止 hook は Phase 1 で必須インストール済み。このオプションはフォーマッターの自動実行を追加する。

プロジェクトに `prettier` または `biome` が含まれている場合、settings.json の hooks に PostToolUse を追加:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write $CLAUDE_FILE_PATH 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

`biome` の場合は `npx @biomejs/biome format --write $CLAUDE_FILE_PATH` に置き換える。

---

## Option C: MCP

### `.mcp.json`

Firestore を使用するプロジェクトで Firebase Emulator 連携を設定:

```json
{
  "mcpServers": {
    "firebase": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "firebase-tools", "emulators:exec", "--only", "firestore", "--"],
      "env": {
        "GOOGLE_CLOUD_PROJECT": "${GOOGLE_CLOUD_PROJECT}",
        "FIRESTORE_EMULATOR_HOST": "localhost:8080"
      }
    }
  }
}
```

**注意:** MCP の設定はプロジェクトの実際の構成に合わせて調整する。上記は Firestore Emulator の例。

---

## Phase 3: ファイル生成

選択に基づいてファイルを生成する。生成時の注意:

1. **CLAUDE.md を読み込む** — プロジェクト固有の技術スタック、コマンド、データモデルを反映する
2. **既存の `.claude/` を確認** — 既にファイルがある場合は上書きせず、マージするか確認する
3. **settings.json はマージ** — 既存の permissions に追加する形で設定する
4. **hook スクリプトに実行権限を付与** — `chmod +x .claude/hooks/*.sh`
5. **`.gitignore` の確認** — `.claude/settings.local.json` が含まれていることを確認

### 生成完了後の出力

```
=== Dev Environment Setup Complete ===

必須（常にインストール）:
  ✓ .claude/rules/security.md
  ✓ .claude/rules/firebase.md
  ✓ .claude/rules/coding-standards.md
  ✓ .claude/skills/dev-server/SKILL.md
  ✓ .claude/skills/firestore-ops/SKILL.md
  ✓ .claude/hooks/prevent-api-key-commit.sh
  ✓ .claude/settings.json (permissions + API Key 防止 hook)

オプション（選択した場合のみ）:
  ✓ .claude/agents/code-reviewer/AGENT.md       [A]
  ✓ .claude/agents/security-auditor/AGENT.md    [A]
  ✓ settings.json に formatter hook 追加         [B]
  ✓ .mcp.json                                   [C]

次のステップ:
  1. 生成されたファイルを確認し、プロジェクトに合わせて調整
  2. git add .claude/ && git commit -m "Add Claude Code dev environment"
  3. .claude/settings.local.json に個人設定を追加（gitignore 済み）
  4. チームメンバーに .claude/ の使い方を共有
```

## Common Mistakes

- **CLAUDE.md なしで実行する** — analyze-and-document を先に実行すること。CLAUDE.md の情報が rules と skills のカスタマイズに必要
- **settings.json に過剰なパーミッション** — `Bash(*)` のようなワイルドカードは避ける。必要なコマンドだけ許可する
- **hook スクリプトの実行権限忘れ** — `chmod +x` しないと hook が動かない
- **settings.local.json をコミットする** — `.gitignore` に含まれていることを確認
- **全オプションを入れすぎる** — 小規模プロジェクトに Agents や MCP は不要な場合が多い。必要になったら追加する
