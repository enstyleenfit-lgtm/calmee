// 食事候補データ（ローカル参考値）

/// 量ボタン候補（表示ラベルと実際の量）
class AmountOption {
  final String label;  // 表示ラベル（"100g", "1個" など）
  final double amount; // baseUnit 単位での実量（比例計算の分子に使用）

  const AmountOption({required this.label, required this.amount});
}

class FoodSuggestion {
  final String name;
  final int kcal;            // baseAmount あたりの参考値
  final double protein;      // baseAmount あたりの参考値 (g)
  final double fat;          // baseAmount あたりの参考値 (g)
  final double carb;         // baseAmount あたりの参考値 (g)
  final List<String> searchTerms; // 検索対象（漢字・かな・別名）
  final int baseAmount;      // 基準量（数値のみ）
  final String baseUnit;     // 基準単位（'g', '個', 'パック' など）
  final List<AmountOption> amountOptions; // 量ボタン候補

  const FoodSuggestion({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.searchTerms,
    required this.baseAmount,
    required this.baseUnit,
    required this.amountOptions,
  });
}

// 文部科学省「日本食品標準成分表2020年版」をもとにした参考値
const List<FoodSuggestion> _kFoodSuggestions = [
  FoodSuggestion(
    name: '白米',
    kcal: 168, protein: 2.5, fat: 0.3, carb: 37.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['白米', 'しろまい', 'はくまい', 'ごはん', '米', 'こめ'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
      AmountOption(label: '300g', amount: 300),
    ],
  ),
  FoodSuggestion(
    name: '玄米',
    kcal: 165, protein: 2.8, fat: 1.0, carb: 35.6,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['玄米', 'げんまい', 'こめ', 'ごはん'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '鶏むね肉',
    kcal: 108, protein: 22.3, fat: 1.5, carb: 0.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['鶏むね肉', 'とりむねにく', 'とり', 'むね', 'ちきん', 'チキン', '鶏肉', 'とりにく'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '卵',
    kcal: 91, protein: 7.4, fat: 6.2, carb: 0.2,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['卵', 'たまご', 'えっぐ', 'エッグ'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
      AmountOption(label: '3個', amount: 3),
    ],
  ),
  FoodSuggestion(
    name: '納豆',
    kcal: 100, protein: 8.3, fat: 5.0, carb: 6.1,
    baseAmount: 1, baseUnit: 'パック',
    searchTerms: ['納豆', 'なっとう', 'なとう'],
    amountOptions: [
      AmountOption(label: '1パック', amount: 1),
      AmountOption(label: '2パック', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'バナナ',
    kcal: 86, protein: 1.1, fat: 0.2, carb: 22.5,
    baseAmount: 1, baseUnit: '本',
    searchTerms: ['バナナ', 'ばなな', 'フルーツ', 'くだもの', 'ふるーつ'],
    amountOptions: [
      AmountOption(label: '1本', amount: 1),
      AmountOption(label: '2本', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'オートミール',
    kcal: 114, protein: 3.8, fat: 2.1, carb: 20.0,
    baseAmount: 30, baseUnit: 'g',
    searchTerms: ['オートミール', 'おーとみーる', 'えんばく', 'シリアル', 'しりある'],
    amountOptions: [
      AmountOption(label: '30g',  amount:  30),
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
    ],
  ),
  FoodSuggestion(
    name: 'じゃがいも',
    kcal: 76, protein: 1.8, fat: 0.1, carb: 17.6,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['じゃがいも', 'じゃが', 'ポテト', 'ぽてと', 'いも'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '餅',
    kcal: 118, protein: 2.1, fat: 0.4, carb: 27.0,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['餅', 'もち', 'おもち'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
      AmountOption(label: '3個', amount: 3),
    ],
  ),
  FoodSuggestion(
    name: 'こしあん',
    kcal: 65, protein: 2.1, fat: 0.2, carb: 14.4,
    baseAmount: 30, baseUnit: 'g',
    searchTerms: ['こしあん', 'あん', 'あんこ', 'こし餡'],
    amountOptions: [
      AmountOption(label: '30g',  amount:  30),
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
    ],
  ),
  FoodSuggestion(
    name: 'プロテイン',
    kcal: 120, protein: 24.0, fat: 2.0, carb: 3.0,
    baseAmount: 1, baseUnit: '杯',
    searchTerms: ['プロテイン', 'ぷろてぃん', 'ぷろて', 'たんぱく', 'たんぱくしつ', 'プロテインシェイク'],
    amountOptions: [
      AmountOption(label: '1杯', amount: 1),
      AmountOption(label: '2杯', amount: 2),
    ],
  ),
];

/// キーワードで食事候補を検索する（部分一致・大文字小文字無視、最大4件）
///
/// [searchTerms] を対象に検索するため、漢字・かな・別名すべてで検索可能。
List<FoodSuggestion> searchFoodSuggestions(String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final lower = q.toLowerCase();
  return _kFoodSuggestions
      .where((f) => f.searchTerms.any((t) => t.toLowerCase().contains(lower)))
      .take(4)
      .toList();
}
