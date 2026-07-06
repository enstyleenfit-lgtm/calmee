/// 運動候補データ（ローカル参考値）
///
/// 拡張ポイント:
/// - [met] を使い、体重(kg)・時間(h) から kcal = MET × 体重 × 時間 で動的計算可能。
///   将来、回数・セット・重量（筋トレ）や距離・時間（有酸素）を追加して精密推定に対応。
/// - [searchExerciseSuggestions] を `Future<List<ExerciseSuggestion>>` に変更して
///   外部METsDBやAI補完に差し替え可能。
class ExerciseSuggestion {
  final String name;
  final String category;         // 'self' | 'trainer_session'
  final double met;              // METs値（将来の動的計算用）
  final int referenceKcal;       // 60kg・30分想定の参考値 = MET × 60 × 0.5
  final bool isStrengthTraining; // 筋トレ種目かどうか（重量補正の適用判定）

  const ExerciseSuggestion({
    required this.name,
    required this.category,
    required this.met,
    required this.referenceKcal,
    required this.isStrengthTraining,
  });
}

/// 重量補正後の推定消費kcalを返す
///
/// 筋トレ種目のみ重量補正を適用。有酸素種目は [referenceKcal] をそのまま返す。
///
/// 補正テーブル（筋トレのみ）:
/// - 重量なし / 0〜20kg → × 1.0
/// - 21〜50kg           → × 1.1
/// - 51〜80kg           → × 1.2
/// - 81kg 以上          → × 1.3
///
/// 将来: 体重(kg)・時間(h)・セット・レップから MET 計算に切り替え可能。
int calcEstimatedKcal(ExerciseSuggestion suggestion, double? weightKg) {
  if (!suggestion.isStrengthTraining || weightKg == null) {
    return suggestion.referenceKcal;
  }
  if (weightKg <= 20) return suggestion.referenceKcal;
  if (weightKg <= 50) return (suggestion.referenceKcal * 1.1).round();
  if (weightKg <= 80) return (suggestion.referenceKcal * 1.2).round();
  return (suggestion.referenceKcal * 1.3).round();
}

// METs値は American College of Sports Medicine "Compendium of Physical Activities" に基づく参考値
// referenceKcal = MET × 60kg × 0.5h
const List<ExerciseSuggestion> _kExerciseSuggestions = [
  // ── 胸 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ベンチプレス',           category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'インクラインベンチプレス', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ダンベルプレス',         category: 'self', met: 4.5, referenceKcal: 135, isStrengthTraining: true),
  ExerciseSuggestion(name: 'チェストプレス',         category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ペックフライ',           category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ケーブルクロスオーバー', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),

  // ── 背中 ────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ラットプルダウン', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: 'シーテッドロー',  category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ベントオーバーロー', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ワンハンドロー',  category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: '懸垂',           category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'デッドリフト',   category: 'self', met: 6.0, referenceKcal: 180, isStrengthTraining: true),

  // ── 脚 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'スクワット',           category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'レッグプレス',         category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: 'レッグエクステンション', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'レッグカール',         category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ブルガリアンスクワット', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ルーマニアンデッドリフト', category: 'self', met: 5.5, referenceKcal: 165, isStrengthTraining: true),
  ExerciseSuggestion(name: 'カーフレイズ',         category: 'self', met: 3.0, referenceKcal:  90, isStrengthTraining: true),

  // ── 肩 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ショルダープレス', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: 'サイドレイズ',   category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'リアレイズ',     category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'フロントレイズ', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'アーノルドプレス', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),
  ExerciseSuggestion(name: 'アップライトロー', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true),

  // ── 腕 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'アームカール',         category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ハンマーカール',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ケーブルカール',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'トライセプスプレスダウン', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'フレンチプレス',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ディップス',           category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),

  // ── 腹 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'クランチ',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'レッグレイズ',   category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),
  ExerciseSuggestion(name: 'アブローラー',   category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true),
  ExerciseSuggestion(name: 'プランク',       category: 'self', met: 3.0, referenceKcal:  90, isStrengthTraining: true),
  ExerciseSuggestion(name: 'ケーブルクランチ', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true),

  // ── 有酸素 ──────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ランニング',     category: 'self', met:  8.0, referenceKcal: 240, isStrengthTraining: false),
  ExerciseSuggestion(name: 'ウォーキング',   category: 'self', met:  3.5, referenceKcal: 105, isStrengthTraining: false),
  ExerciseSuggestion(name: 'クロストレーナー', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: false),
  ExerciseSuggestion(name: '自転車',         category: 'self', met:  4.0, referenceKcal: 120, isStrengthTraining: false),
  ExerciseSuggestion(name: '階段昇降',       category: 'self', met:  4.0, referenceKcal: 120, isStrengthTraining: false),
  ExerciseSuggestion(name: '水泳',           category: 'self', met:  6.0, referenceKcal: 180, isStrengthTraining: false),
  ExerciseSuggestion(name: '縄跳び',         category: 'self', met: 10.0, referenceKcal: 300, isStrengthTraining: false),
];

/// キーワードで運動候補を検索する（部分一致・大文字小文字無視、最大4件）
List<ExerciseSuggestion> searchExerciseSuggestions(String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final lower = q.toLowerCase();
  return _kExerciseSuggestions
      .where((e) => e.name.toLowerCase().contains(lower))
      .take(4)
      .toList();
}
