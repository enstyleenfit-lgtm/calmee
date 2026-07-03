/// 運動候補データ（ローカル参考値）
///
/// 拡張ポイント:
/// - [met] を使い、体重(kg)・時間(h) から kcal = MET × 体重 × 時間 で動的計算可能。
///   将来、回数・セット・重量（筋トレ）や距離（有酸素）を追加してより精密な推定に対応。
/// - [searchExerciseSuggestions] を Future<> に変更して外部METsDBやAI補完に差し替え可能。
class ExerciseSuggestion {
  final String name;
  final String category;   // 'self' | 'trainer_session'
  final double met;        // METs値（将来の動的計算用）
  final int referenceKcal; // 60kg・30分想定の参考値 = MET × 60 × 0.5

  const ExerciseSuggestion({
    required this.name,
    required this.category,
    required this.met,
    required this.referenceKcal,
  });
}

// METs値は American College of Sports Medicine "Compendium of Physical Activities" に基づく参考値
const List<ExerciseSuggestion> _kExerciseSuggestions = [
  ExerciseSuggestion(name: 'スクワット',       category: 'self', met: 5.0, referenceKcal: 150),
  ExerciseSuggestion(name: 'ベンチプレス',     category: 'self', met: 5.0, referenceKcal: 150),
  ExerciseSuggestion(name: 'デッドリフト',     category: 'self', met: 6.0, referenceKcal: 180),
  ExerciseSuggestion(name: 'ラットプルダウン', category: 'self', met: 4.0, referenceKcal: 120),
  ExerciseSuggestion(name: 'ショルダープレス', category: 'self', met: 4.0, referenceKcal: 120),
  ExerciseSuggestion(name: 'レッグプレス',     category: 'self', met: 4.0, referenceKcal: 120),
  ExerciseSuggestion(name: 'ランニング',       category: 'self', met: 8.0, referenceKcal: 240),
  ExerciseSuggestion(name: 'ウォーキング',     category: 'self', met: 3.5, referenceKcal: 105),
  ExerciseSuggestion(name: 'クロストレーナー', category: 'self', met: 5.0, referenceKcal: 150),
  ExerciseSuggestion(name: '自転車',           category: 'self', met: 4.0, referenceKcal: 120),
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
