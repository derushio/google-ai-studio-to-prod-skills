# AI Studio が生成するプロジェクトの構造

AI Studio Apps が生成するプロジェクトの共通パターンをまとめる。`graduate-from-ai-studio` スキルはこの構造を前提にプロジェクト分析を行う。

## AI Studio が管理するもの

AI Studio は内部で以下を自動管理しており、プロジェクトコードには含まれない:

- **Cloud Run サービス** — デプロイ・スケーリング・ルーティングすべて自動
- **Dockerfile** — 存在しない。AI Studio が内部でビルド
- **Firebase プロジェクト** — `gen-lang-client-*` という共有プロジェクト上に作成される
- **Firestore データベース** — AI Studio 専用の DB ID（例: `ai-studio-ffcfd659-...`）が割り当てられる
- **環境変数の注入** — `GEMINI_API_KEY`, `APP_URL` は AI Studio が自動で Cloud Run に注入
- **CI/CD** — 存在しない。AI Studio の UI からデプロイ

## プロジェクトに含まれるファイル

### 必ず存在するファイル

| ファイル | 役割 |
|---------|------|
| `firebase-applet-config.json` | Firebase 設定（projectId, appId, apiKey, firestoreDatabaseId 等）。**AI Studio プロジェクトの識別子** |
| `metadata.json` | アプリ名・説明。AI Studio の UI で設定した内容 |
| `firestore.rules` | Firestore セキュリティルール |
| `firebase-blueprint.json` | Firestore のスキーマ定義（コレクション、フィールド型、必須項目） |
| `.env.example` | 必要な環境変数の一覧（`GEMINI_API_KEY`, `APP_URL`） |

### フレームワーク別の構成

**Node.js + Express + Vite (React SPA)** — 最も一般的なパターン:

```
project/
├── firebase-applet-config.json
├── firebase-blueprint.json
├── firestore.rules
├── metadata.json
├── .env.example
├── package.json
├── tsconfig.json
├── vite.config.ts
├── server.ts              # Express サーバー（API + 静的配信）
├── index.html
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── index.css
    ├── lib/
    │   ├── firebase.ts    # Firebase SDK 初期化
    │   └── utils.ts
    └── components/
        └── ui/            # UI コンポーネント
```

**特徴的なパターン:**
- `server.ts` が Express サーバーで、開発時は Vite middleware、本番時は `dist/` を静的配信
- `vite.config.ts` で `GEMINI_API_KEY` と `VITE_APP_URL` を `define` で注入
- `firebase-applet-config.json` を実行時にファイルとして読み込む（環境変数ではない）
- ポートは `3000` 固定（Cloud Run の `PORT` 環境変数対応なし）
- `npm run dev` → `tsx server.ts`、`npm run build` → `vite build`

## 「卒業」時に対応が必要な項目

### 必須対応

1. **Dockerfile が存在しない** → 生成が必要
2. **`PORT` 環境変数に対応していない** → Cloud Run は `PORT` を注入するため、サーバーコードの修正が必要
3. **IaC が存在しない** → Cloud Run, Artifact Registry, IAM, Secret Manager 等のリソース定義が必要
4. **CI/CD が存在しない** → GitHub Actions ワークフローの生成が必要
5. **`firebase.json` が存在しない** → Firestore rules/indexes のデプロイに必要
6. **Firestore の複合インデックス定義がない** → コードから推定して `firestore.indexes.json` を生成

### 判断が必要な項目

1. **Firebase プロジェクト** — `gen-lang-client-*` を使い続けるか、新規プロジェクトに移行するか
   - 使い続ける場合: 既存データがそのまま使える。ただし Google 管理のプロジェクトに依存
   - 新規の場合: 完全な独立。データ移行は手動
2. **環境変数の管理** — AI Studio の Secrets パネルの代わりに Secret Manager を使う
3. **認証設定** — Firebase Auth の承認済みドメインに新しい Cloud Run URL を追加

## `firebase-applet-config.json` の構造

```json
{
  "projectId": "gen-lang-client-XXXXXXXXXX",
  "appId": "1:XXXXX:web:XXXXX",
  "apiKey": "AIzaSy...",
  "authDomain": "gen-lang-client-XXXXXXXXXX.firebaseapp.com",
  "firestoreDatabaseId": "ai-studio-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "storageBucket": "gen-lang-client-XXXXXXXXXX.firebasestorage.app",
  "messagingSenderId": "XXXXX"
}
```

- `projectId` は常に `gen-lang-client-` プレフィックス
- `firestoreDatabaseId` は `ai-studio-` プレフィックス + UUID
- `apiKey` はフロントエンド用の公開キー（シークレットではない）
- 新規プロジェクトに移行する場合、このファイルを差し替える必要がある
