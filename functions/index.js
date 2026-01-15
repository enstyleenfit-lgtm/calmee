const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const OpenAI = require("openai");

admin.initializeApp();

// Secret Manager: firebase functions:secrets:set OPENAI_API_KEY で登録
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

/**
 * 食事画像をAIで解析し、3択分類（light/normal/heavy）を返す Callable Function
 *
 * 入力: { imageUrl: string }
 * 出力: { level: "light" | "normal" | "heavy" }
 *
 * 失敗時は { level: "normal" } にフォールバック
 */
exports.analyzeMealImage = onCall(
  {
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    // 認証チェック（エミュレータでは緩和）
    // エミュレータ環境では認証をバイパスできる場合がある
    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true" || 
                       process.env.GCLOUD_PROJECT === undefined;
    
    // デバッグ用ログ
    console.log("Request received:", JSON.stringify({
      isEmulator,
      hasAuth: !!request.auth,
      data: request.data,
      dataType: typeof request.data,
    }));

    if (!isEmulator && !request.auth) {
      throw new HttpsError("unauthenticated", "認証が必要です");
    }

    // request.dataが直接imageUrlの場合と、data.imageUrlの場合の両方に対応
    let imageUrl;
    if (typeof request.data === "string") {
      // 直接文字列の場合（エミュレータの形式）
      try {
        const parsed = JSON.parse(request.data);
        imageUrl = parsed.imageUrl || parsed.data?.imageUrl;
      } catch (e) {
        imageUrl = request.data;
      }
    } else if (request.data?.imageUrl) {
      imageUrl = request.data.imageUrl;
    } else if (request.data?.data?.imageUrl) {
      imageUrl = request.data.data.imageUrl;
    }

    if (!imageUrl || typeof imageUrl !== "string") {
      console.error("Invalid imageUrl:", imageUrl, "Request data:", request.data);
      throw new HttpsError("invalid-argument", `imageUrlが必要です。受け取った値: ${JSON.stringify(request.data)}`);
    }

    try {
      const apiKey = OPENAI_API_KEY.value() || process.env.OPENAI_API_KEY;
      if (!apiKey) {
        // Secret未設定時でも落とさず normal にフォールバック
        console.error("OPENAI_API_KEY is not set");
        return {level: "normal"};
      }

      const openai = new OpenAI({apiKey});

      // OpenAI Vision APIで画像を解析（3択分類のみ）
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: `あなたは食事の量を判定する専門家です。
写真を見て、食事の量を以下の3つのカテゴリのいずれかに分類してください：
- light: 軽めの食事（小盛り、サラダ中心、軽食など）
- normal: ちょうどいい量の食事（標準的な一食分）
- heavy: しっかりした食事（大盛り、ボリュームのある食事など）

回答は必ず "light"、"normal"、"heavy" のいずれか1つの単語のみを返してください。
説明やその他のテキストは不要です。`,
          },
          {
            role: "user",
            content: [
              {type: "text", text: "この写真の食事の量を判定してください。"},
              {type: "image_url", image_url: {url: imageUrl}},
            ],
          },
        ],
        max_tokens: 10,
      });

      const raw = (response.choices[0]?.message?.content || "")
        .trim()
        .toLowerCase();

      // 結果を厳密に検証（失敗時は normal）
      if (raw === "light" || raw === "normal" || raw === "heavy") {
        return {level: raw};
      }

      console.warn(`Unexpected AI result: ${raw}`);
      return {level: "normal"};
    } catch (error) {
      console.error("OpenAI API error:", error);
      return {level: "normal"};
    }
  }
);
