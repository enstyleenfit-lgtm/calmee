/// 食事候補データ（ローカル参考値）
///
/// 拡張ポイント:
/// - [searchFoodSuggestions] の戻り値を `Future<List<FoodSuggestion>>` に変更し、
///   呼び出し側を await に書き換えるだけで外部API（食品成分DB等）に差し替え可能。
class FoodSuggestion {
  final String name;
  final int kcal;       // 参考値 (kcal)
  final double protein; // 参考値 (g)
  final double fat;     // 参考値 (g)
  final double carb;    // 参考値 (g)

  const FoodSuggestion({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
  });
}

// 文部科学省「日本食品標準成分表2020年版」をもとにした参考値
const List<FoodSuggestion> _kFoodSuggestions = [
  FoodSuggestion(name: '白米 100g',      kcal: 168, protein:  2.5, fat: 0.3, carb: 37.1),
  FoodSuggestion(name: '玄米 100g',      kcal: 165, protein:  2.8, fat: 1.0, carb: 35.6),
  FoodSuggestion(name: '鶏むね肉 100g',  kcal: 108, protein: 22.3, fat: 1.5, carb:  0.0),
  FoodSuggestion(name: '卵 1個',         kcal:  91, protein:  7.4, fat: 6.2, carb:  0.2),
  FoodSuggestion(name: '納豆 1パック',   kcal: 100, protein:  8.3, fat: 5.0, carb:  6.1),
  FoodSuggestion(name: 'バナナ 1本',     kcal:  86, protein:  1.1, fat: 0.2, carb: 22.5),
  FoodSuggestion(name: 'オートミール 30g', kcal: 114, protein: 3.8, fat: 2.1, carb: 20.0),
  FoodSuggestion(name: 'じゃがいも 100g', kcal: 76, protein:  1.8, fat: 0.1, carb: 17.6),
  FoodSuggestion(name: '餅 1個',         kcal: 118, protein:  2.1, fat: 0.4, carb: 27.0),
  FoodSuggestion(name: 'こしあん 30g',   kcal:  65, protein:  2.1, fat: 0.2, carb: 14.4),
];

/// キーワードで食事候補を検索する（部分一致・大文字小文字無視、最大4件）
List<FoodSuggestion> searchFoodSuggestions(String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final lower = q.toLowerCase();
  return _kFoodSuggestions
      .where((f) => f.name.toLowerCase().contains(lower))
      .take(4)
      .toList();
}
