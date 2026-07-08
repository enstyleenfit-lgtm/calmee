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
  final List<String> searchTerms; // ひらがな読み・別名（1文字検索に対応）

  const ExerciseSuggestion({
    required this.name,
    required this.category,
    required this.met,
    required this.referenceKcal,
    required this.isStrengthTraining,
    this.searchTerms = const [],
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

/// 有酸素運動の推定消費kcalを返す
///
/// [referenceKcal] は 30分・普通強度 (intensityFactor=1.0) の基準値。
/// - 時間補正: referenceKcal × minutes / 30
/// - 強度補正: 軽め 0.8 / 普通 1.0 / 早め 1.2
int calcCardioKcal(ExerciseSuggestion s, int minutes, double intensityFactor) {
  return (s.referenceKcal * minutes / 30 * intensityFactor).round();
}

// METs値は American College of Sports Medicine "Compendium of Physical Activities" に基づく参考値
// referenceKcal = MET × 60kg × 0.5h
const List<ExerciseSuggestion> _kExerciseSuggestions = [
  // ── 胸 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ベンチプレス',           category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['べんちぷれす', 'べんち']),
  ExerciseSuggestion(name: 'インクラインベンチプレス', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['いんくらいんべんちぷれす', 'いんくらいん']),
  ExerciseSuggestion(name: 'ダンベルプレス',         category: 'self', met: 4.5, referenceKcal: 135, isStrengthTraining: true,  searchTerms: ['だんべるぷれす', 'だんべる']),
  ExerciseSuggestion(name: 'チェストプレス',         category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['ちぇすとぷれす', 'ちぇすと']),
  ExerciseSuggestion(name: 'ペックフライ',           category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['ぺっくふらい', 'ぺっく']),
  ExerciseSuggestion(name: 'ケーブルクロスオーバー', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['けーぶるくろすおーばー']),

  // ── 背中 ────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ラットプルダウン',   category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['らっとぷるだうん', 'らっと']),
  ExerciseSuggestion(name: 'シーテッドロー',     category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['しーてっどろー']),
  ExerciseSuggestion(name: 'ベントオーバーロー', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['べんとおーばーろー', 'べんと']),
  ExerciseSuggestion(name: 'ワンハンドロー',     category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['わんはんどろー']),
  ExerciseSuggestion(name: '懸垂',               category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['けんすい', 'ちんにんぐ']),
  ExerciseSuggestion(name: 'デッドリフト',       category: 'self', met: 6.0, referenceKcal: 180, isStrengthTraining: true,  searchTerms: ['でっどりふと', 'でっど']),

  // ── 脚 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'スクワット',             category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['すくわっと']),
  ExerciseSuggestion(name: 'レッグプレス',           category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['れっぐぷれす']),
  ExerciseSuggestion(name: 'レッグエクステンション', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['れっぐえくすてんしょん']),
  ExerciseSuggestion(name: 'レッグカール',           category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['れっぐかーる']),
  ExerciseSuggestion(name: 'ブルガリアンスクワット', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['ぶるがりあんすくわっと']),
  ExerciseSuggestion(name: 'ルーマニアンデッドリフト', category: 'self', met: 5.5, referenceKcal: 165, isStrengthTraining: true,  searchTerms: ['るーまにあんでっどりふと']),
  ExerciseSuggestion(name: 'カーフレイズ',           category: 'self', met: 3.0, referenceKcal:  90, isStrengthTraining: true,  searchTerms: ['かーふれいず']),

  // ── 肩 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ショルダープレス', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['しょるだーぷれす', 'しょるだー']),
  ExerciseSuggestion(name: 'サイドレイズ',   category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['さいどれいず', 'さいど']),
  ExerciseSuggestion(name: 'リアレイズ',     category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['りあれいず']),
  ExerciseSuggestion(name: 'フロントレイズ', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['ふろんとれいず']),
  ExerciseSuggestion(name: 'アーノルドプレス', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['あーのるどぷれす']),
  ExerciseSuggestion(name: 'アップライトロー', category: 'self', met: 4.0, referenceKcal: 120, isStrengthTraining: true,  searchTerms: ['あっぷらいとろー']),

  // ── 腕 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'アームカール',         category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['あーむかーる']),
  ExerciseSuggestion(name: 'ハンマーカール',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['はんまーかーる']),
  ExerciseSuggestion(name: 'ケーブルカール',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['けーぶるかーる']),
  ExerciseSuggestion(name: 'トライセプスプレスダウン', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['とらいせぷすぷれすだうん', 'とらいせぷす']),
  ExerciseSuggestion(name: 'フレンチプレス',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['ふれんちぷれす', 'ふれんち']),
  ExerciseSuggestion(name: 'ディップス',           category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['でぃっぷす']),

  // ── 腹 ──────────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'クランチ',       category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['くらんち']),
  ExerciseSuggestion(name: 'レッグレイズ',   category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['れっぐれいず']),
  ExerciseSuggestion(name: 'アブローラー',   category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: true,  searchTerms: ['あぶろーらー']),
  ExerciseSuggestion(name: 'プランク',       category: 'self', met: 3.0, referenceKcal:  90, isStrengthTraining: true,  searchTerms: ['ぷらんく']),
  ExerciseSuggestion(name: 'ケーブルクランチ', category: 'self', met: 3.5, referenceKcal: 105, isStrengthTraining: true,  searchTerms: ['けーぶるくらんち']),

  // ── 有酸素 ──────────────────────────────────────────────────────
  ExerciseSuggestion(name: 'ランニング',     category: 'self', met:  8.0, referenceKcal: 240, isStrengthTraining: false, searchTerms: ['らんにんぐ', 'じょぎんぐ']),
  ExerciseSuggestion(name: 'ウォーキング',   category: 'self', met:  3.5, referenceKcal: 105, isStrengthTraining: false, searchTerms: ['うぉーきんぐ', 'うおーきんぐ', 'さんぽ']),
  ExerciseSuggestion(name: 'クロストレーナー', category: 'self', met: 5.0, referenceKcal: 150, isStrengthTraining: false, searchTerms: ['くろすとれーなー']),
  ExerciseSuggestion(name: '自転車',         category: 'self', met:  4.0, referenceKcal: 120, isStrengthTraining: false, searchTerms: ['じてんしゃ', 'ちゃり', 'さいくる']),
  ExerciseSuggestion(name: '階段昇降',       category: 'self', met:  4.0, referenceKcal: 120, isStrengthTraining: false, searchTerms: ['かいだんしょうこう', 'かいだん', 'すてっぱー']),
  ExerciseSuggestion(name: '水泳',           category: 'self', met:  6.0, referenceKcal: 180, isStrengthTraining: false, searchTerms: ['すいえい', 'すいみんぐ']),
  ExerciseSuggestion(name: '縄跳び',         category: 'self', met: 10.0, referenceKcal: 300, isStrengthTraining: false, searchTerms: ['なわとび', 'なわ']),
];

/// キーワードで運動候補を検索する（最大4件）
///
/// 名前・[searchTerms] に対して startsWith一致を優先し、1文字でも意図した候補が先頭に出る。
/// その後 contains一致で補完する。
List<ExerciseSuggestion> searchExerciseSuggestions(String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final lower = q.toLowerCase();
  final starts = <ExerciseSuggestion>[];
  final others = <ExerciseSuggestion>[];
  for (final e in _kExerciseSuggestions) {
    final terms = [e.name, ...e.searchTerms];
    if (terms.any((t) => t.toLowerCase().startsWith(lower))) {
      starts.add(e);
    } else if (terms.any((t) => t.toLowerCase().contains(lower))) {
      others.add(e);
    }
  }
  return [...starts, ...others].take(4).toList();
}
