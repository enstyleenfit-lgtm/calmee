# Cloud Functions for Calmee

## セットアップ

1. 依存関係のインストール:
```bash
cd functions
npm install
```

2. OpenAI APIキーの設定:
```bash
firebase functions:config:set openai.api_key="YOUR_OPENAI_API_KEY"
```

または、環境変数として設定:
```bash
export OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
```

## デプロイ

```bash
firebase deploy --only functions
```

## 関数

### analyzeMealImage

食事画像をAIで解析し、3択分類（light/normal/heavy）を返す。

**パラメータ:**
- `imageUrl` (string): Firebase Storageの画像URL

**戻り値:**
- `level` (string): "light" | "normal" | "heavy"

**エラー処理:**
- AI解析に失敗した場合は、デフォルトで "normal" を返す





