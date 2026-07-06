// 食事候補データ（ローカル参考値）
// 出典：文部科学省「日本食品標準成分表2020年版」をもとにした参考値

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

const List<FoodSuggestion> _kFoodSuggestions = [
  // ── 主食・炭水化物 ────────────────────────────────────────────
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
      AmountOption(label: '300g', amount: 300),
    ],
  ),
  FoodSuggestion(
    name: '雑穀米',
    kcal: 168, protein: 2.9, fat: 0.8, carb: 36.5,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['雑穀米', 'ざっこくまい', 'こくまい', 'ごはん', 'こめ', '雑穀', 'ざっこく'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
      AmountOption(label: '300g', amount: 300),
    ],
  ),
  FoodSuggestion(
    name: 'おにぎり',
    kcal: 185, protein: 3.1, fat: 0.5, carb: 40.6,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['おにぎり', 'にぎりめし', 'おむすび', 'こめ', 'ごはん'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
      AmountOption(label: '3個', amount: 3),
    ],
  ),
  FoodSuggestion(
    name: '食パン',
    kcal: 149, protein: 5.3, fat: 2.5, carb: 27.8,
    baseAmount: 1, baseUnit: '枚',
    searchTerms: ['食パン', 'しょくぱん', 'パン', 'ぱん', 'ブレッド', 'ぶれっど', 'トースト', 'とーすと'],
    amountOptions: [
      AmountOption(label: '1枚', amount: 1),
      AmountOption(label: '2枚', amount: 2),
      AmountOption(label: '3枚', amount: 3),
    ],
  ),
  FoodSuggestion(
    name: 'ベーグル',
    kcal: 275, protein: 9.0, fat: 1.5, carb: 56.0,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['ベーグル', 'べーぐる', 'パン', 'ぱん'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'うどん',
    kcal: 105, protein: 2.6, fat: 0.4, carb: 21.6,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['うどん', '饂飩', 'めん', '麺', 'ぬーどる', 'ヌードル'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'そば',
    kcal: 132, protein: 4.8, fat: 1.0, carb: 26.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['そば', '蕎麦', 'めん', '麺', 'そばめん'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'パスタ',
    kcal: 165, protein: 5.8, fat: 0.9, carb: 32.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['パスタ', 'ぱすた', 'スパゲッティ', 'すぱげってぃ', 'めん', '麺', 'マカロニ', 'まかろに'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '中華麺',
    kcal: 149, protein: 4.9, fat: 0.6, carb: 29.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['中華麺', 'ちゅうかめん', 'ラーメン', 'らーめん', 'めん', '麺', 'ちゅうか'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
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
    name: 'さつまいも',
    kcal: 132, protein: 1.2, fat: 0.2, carb: 30.9,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['さつまいも', 'さつま', 'スイートポテト', 'すいーとぽてと', 'いも', 'やきいも', '焼き芋'],
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
    name: 'コーンフレーク',
    kcal: 114, protein: 2.3, fat: 0.5, carb: 25.1,
    baseAmount: 30, baseUnit: 'g',
    searchTerms: ['コーンフレーク', 'こーんふれーく', 'シリアル', 'しりある', 'こーんふれーくす'],
    amountOptions: [
      AmountOption(label: '30g', amount:  30),
      AmountOption(label: '50g', amount:  50),
      AmountOption(label: '80g', amount:  80),
    ],
  ),
  FoodSuggestion(
    name: 'グラノーラ',
    kcal: 230, protein: 5.0, fat: 8.5, carb: 33.6,
    baseAmount: 50, baseUnit: 'g',
    searchTerms: ['グラノーラ', 'ぐらのーら', 'シリアル', 'しりある', 'みゅーずり', 'ミューズリ'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '80g',  amount:  80),
      AmountOption(label: '100g', amount: 100),
    ],
  ),

  // ── 肉 ──────────────────────────────────────────────────────────
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
    name: '鶏もも肉',
    kcal: 190, protein: 17.3, fat: 12.8, carb: 0.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['鶏もも肉', 'とりももにく', 'もも', 'ちきん', 'チキン', '鶏肉', 'とりにく', 'とり'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'ささみ',
    kcal: 98, protein: 23.0, fat: 0.8, carb: 0.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['ささみ', 'ささ身', 'ちきん', 'チキン', 'とり', '鶏肉', 'とりにく'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: '鶏ひき肉',
    kcal: 186, protein: 17.5, fat: 12.3, carb: 0.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['鶏ひき肉', 'とりひきにく', 'ひきにく', 'ミンチ', 'みんち', 'とり', '鶏肉'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '牛赤身肉',
    kcal: 167, protein: 21.2, fat: 9.4, carb: 0.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['牛赤身肉', 'ぎゅうあかみ', 'ぎゅうにく', '牛肉', 'びーふ', 'ビーフ', 'あかみ'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '牛ひき肉',
    kcal: 224, protein: 17.1, fat: 16.3, carb: 0.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['牛ひき肉', 'ぎゅうひきにく', 'ひきにく', 'ミンチ', 'みんち', 'ぎゅうにく', '牛肉'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '豚ヒレ肉',
    kcal: 130, protein: 22.2, fat: 3.7, carb: 0.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['豚ヒレ肉', 'ぶたひれにく', 'ひれ', 'ぽーく', 'ポーク', 'ぶたにく', '豚肉'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '豚ロース',
    kcal: 263, protein: 19.3, fat: 19.2, carb: 0.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['豚ロース', 'ぶたろーす', 'ろーす', 'ぽーく', 'ポーク', 'ぶたにく', '豚肉'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '豚ひき肉',
    kcal: 209, protein: 17.7, fat: 14.7, carb: 0.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['豚ひき肉', 'ぶたひきにく', 'ひきにく', 'ミンチ', 'みんち', 'ぶたにく', '豚肉'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'ハム',
    kcal: 39, protein: 3.2, fat: 2.8, carb: 0.4,
    baseAmount: 1, baseUnit: '枚',
    searchTerms: ['ハム', 'はむ', 'ぽーく', 'ポーク', 'ランチョンミート', 'ろーすはむ'],
    amountOptions: [
      AmountOption(label: '1枚', amount: 1),
      AmountOption(label: '2枚', amount: 2),
      AmountOption(label: '3枚', amount: 3),
    ],
  ),
  FoodSuggestion(
    name: 'ベーコン',
    kcal: 81, protein: 3.0, fat: 7.3, carb: 0.1,
    baseAmount: 1, baseUnit: '枚',
    searchTerms: ['ベーコン', 'べーこん', 'ぽーく', 'ポーク', 'ぶたにく'],
    amountOptions: [
      AmountOption(label: '1枚', amount: 1),
      AmountOption(label: '2枚', amount: 2),
      AmountOption(label: '3枚', amount: 3),
    ],
  ),

  // ── 魚・海鮮 ─────────────────────────────────────────────────
  FoodSuggestion(
    name: '鮭',
    kcal: 133, protein: 22.3, fat: 4.1, carb: 0.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['鮭', 'さけ', 'しゃけ', 'サーモン', 'さーもん', 'さかな', '魚'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'サバ',
    kcal: 211, protein: 20.6, fat: 12.1, carb: 0.3,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['サバ', 'さば', '鯖', 'さかな', '魚'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'マグロ赤身',
    kcal: 125, protein: 26.4, fat: 1.4, carb: 0.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['マグロ赤身', 'まぐろあかみ', 'まぐろ', 'マグロ', 'あかみ', 'さかな', '魚', 'ツナ', 'つな'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'カツオ',
    kcal: 114, protein: 25.8, fat: 0.5, carb: 0.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['カツオ', 'かつお', '鰹', 'さかな', '魚', 'かつおのたたき'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'タラ',
    kcal: 77, protein: 17.6, fat: 0.2, carb: 0.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['タラ', 'たら', '鱈', 'さかな', '魚', 'ほっけ'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'アジ',
    kcal: 126, protein: 19.7, fat: 4.5, carb: 0.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['アジ', 'あじ', '鯵', 'さかな', '魚'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'イワシ',
    kcal: 169, protein: 19.2, fat: 9.2, carb: 0.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['イワシ', 'いわし', '鰯', 'さかな', '魚'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'エビ',
    kcal: 83, protein: 19.6, fat: 0.6, carb: 0.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['エビ', 'えび', '海老', 'しーふーど', 'シーフード', 'ぷりぷり'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'イカ',
    kcal: 83, protein: 17.9, fat: 0.8, carb: 0.4,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['イカ', 'いか', '烏賊', 'しーふーど', 'シーフード'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'ツナ缶',
    kcal: 170, protein: 14.0, fat: 12.2, carb: 0.1,
    baseAmount: 1, baseUnit: '缶',
    searchTerms: ['ツナ缶', 'つなかん', 'ツナ', 'つな', 'かんづめ', '缶詰', 'シーチキン', 'しーちきん'],
    amountOptions: [
      AmountOption(label: '1缶', amount: 1),
      AmountOption(label: '2缶', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'ノンオイルツナ',
    kcal: 50, protein: 11.2, fat: 0.5, carb: 0.4,
    baseAmount: 1, baseUnit: '缶',
    searchTerms: ['ノンオイルツナ', 'のんおいるつな', 'ツナ', 'つな', 'かんづめ', '缶詰', 'のんおいる', 'しーちきん'],
    amountOptions: [
      AmountOption(label: '1缶', amount: 1),
      AmountOption(label: '2缶', amount: 2),
    ],
  ),

  // ── 卵・大豆・乳製品 ─────────────────────────────────────────
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
    name: '卵白',
    kcal: 14, protein: 3.2, fat: 0.0, carb: 0.2,
    baseAmount: 1, baseUnit: '個分',
    searchTerms: ['卵白', 'らんぱく', 'たまごしろみ', 'えっぐほわいと', 'エッグホワイト', 'たまご', 'しろみ'],
    amountOptions: [
      AmountOption(label: '1個分', amount: 1),
      AmountOption(label: '2個分', amount: 2),
      AmountOption(label: '3個分', amount: 3),
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
    name: '木綿豆腐',
    kcal: 72, protein: 7.0, fat: 4.2, carb: 1.5,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['木綿豆腐', 'もめんとうふ', 'とうふ', '豆腐', 'もめん'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '絹豆腐',
    kcal: 56, protein: 5.3, fat: 3.0, carb: 2.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['絹豆腐', 'きぬとうふ', 'とうふ', '豆腐', 'きぬ', 'きぬごし'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '豆乳',
    kcal: 92, protein: 7.2, fat: 4.0, carb: 6.2,
    baseAmount: 200, baseUnit: 'ml',
    searchTerms: ['豆乳', 'とうにゅう', 'だいずみるく', 'そいみるく', 'ソイミルク'],
    amountOptions: [
      AmountOption(label: '200ml', amount: 200),
      AmountOption(label: '400ml', amount: 400),
    ],
  ),
  FoodSuggestion(
    name: 'ギリシャヨーグルト',
    kcal: 62, protein: 10.0, fat: 0.3, carb: 4.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['ギリシャヨーグルト', 'ぎりしゃよーぐると', 'よーぐると', 'ヨーグルト', 'ぷれーんよーぐると', 'ぎりしゃ'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '170g', amount: 170),
    ],
  ),
  FoodSuggestion(
    name: '無脂肪ヨーグルト',
    kcal: 56, protein: 5.8, fat: 0.2, carb: 8.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['無脂肪ヨーグルト', 'むしぼうよーぐると', 'よーぐると', 'ヨーグルト', 'のんふぁっとよーぐると'],
    amountOptions: [
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '牛乳',
    kcal: 134, protein: 6.6, fat: 7.6, carb: 9.6,
    baseAmount: 200, baseUnit: 'ml',
    searchTerms: ['牛乳', 'ぎゅうにゅう', 'みるく', 'ミルク', 'もみるく'],
    amountOptions: [
      AmountOption(label: '200ml', amount: 200),
      AmountOption(label: '400ml', amount: 400),
    ],
  ),
  FoodSuggestion(
    name: 'チーズ',
    kcal: 61, protein: 4.7, fat: 4.7, carb: 0.2,
    baseAmount: 1, baseUnit: '枚',
    searchTerms: ['チーズ', 'ちーず', 'スライスチーズ', 'すらいすちーず', 'チェダー', 'ちぇだー'],
    amountOptions: [
      AmountOption(label: '1枚', amount: 1),
      AmountOption(label: '2枚', amount: 2),
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

  // ── 野菜 ─────────────────────────────────────────────────────
  FoodSuggestion(
    name: 'ブロッコリー',
    kcal: 33, protein: 4.3, fat: 0.5, carb: 5.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['ブロッコリー', 'ぶろっこりー', 'やさい', '野菜'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'ほうれん草',
    kcal: 20, protein: 2.2, fat: 0.4, carb: 3.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['ほうれん草', 'ほうれんそう', 'やさい', '野菜', 'ほうれん'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'キャベツ',
    kcal: 23, protein: 1.3, fat: 0.2, carb: 5.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['キャベツ', 'きゃべつ', 'やさい', '野菜'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'レタス',
    kcal: 12, protein: 0.6, fat: 0.1, carb: 2.8,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['レタス', 'れたす', 'やさい', '野菜', 'さらだ', 'サラダ'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'トマト',
    kcal: 19, protein: 0.7, fat: 0.1, carb: 4.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['トマト', 'とまと', 'やさい', '野菜', 'トマト'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: '大根',
    kcal: 18, protein: 0.5, fat: 0.1, carb: 4.1,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['大根', 'だいこん', 'やさい', '野菜', 'ラディッシュ', 'らでぃっしゅ'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'にんじん',
    kcal: 39, protein: 0.7, fat: 0.2, carb: 9.3,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['にんじん', '人参', 'キャロット', 'きゃろっと', 'やさい', '野菜'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: '玉ねぎ',
    kcal: 37, protein: 1.0, fat: 0.1, carb: 8.8,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['玉ねぎ', 'たまねぎ', 'おにおん', 'オニオン', 'やさい', '野菜'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'きのこ',
    kcal: 22, protein: 2.9, fat: 0.5, carb: 3.2,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['きのこ', 'キノコ', '茸', 'しいたけ', '椎茸', 'しめじ', 'えのき', 'まいたけ', 'やさい'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'もやし',
    kcal: 14, protein: 1.7, fat: 0.1, carb: 2.6,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['もやし', 'モヤシ', 'やさい', '野菜', 'まめもやし', 'だいずもやし'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '200g', amount: 200),
    ],
  ),
  FoodSuggestion(
    name: 'アスパラ',
    kcal: 22, protein: 2.6, fat: 0.2, carb: 3.9,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['アスパラ', 'あすぱら', 'アスパラガス', 'あすぱらがす', 'やさい', '野菜'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'きゅうり',
    kcal: 14, protein: 1.0, fat: 0.1, carb: 3.0,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['きゅうり', '胡瓜', 'キュウリ', 'やさい', '野菜', 'くきゅうり'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: '海藻サラダ',
    kcal: 9, protein: 0.7, fat: 0.1, carb: 1.6,
    baseAmount: 30, baseUnit: 'g',
    searchTerms: ['海藻サラダ', 'かいそうさらだ', 'かいそう', '海藻', 'わかめ', 'さらだ', 'サラダ'],
    amountOptions: [
      AmountOption(label: '30g',  amount:  30),
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
    ],
  ),

  // ── 果物 ─────────────────────────────────────────────────────
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
    name: 'りんご',
    kcal: 91, protein: 0.3, fat: 0.5, carb: 21.9,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['りんご', 'リンゴ', '林檎', 'くだもの', 'フルーツ', 'ふるーつ', 'あっぷる', 'アップル'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '1/2個', amount: 0.5),
    ],
  ),
  FoodSuggestion(
    name: 'キウイ',
    kcal: 53, protein: 1.0, fat: 0.1, carb: 13.5,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['キウイ', 'きうい', 'キウイフルーツ', 'くだもの', 'フルーツ', 'ふるーつ'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'ブルーベリー',
    kcal: 49, protein: 0.5, fat: 0.1, carb: 12.9,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['ブルーベリー', 'ぶるーべりー', 'べりー', 'ベリー', 'くだもの', 'フルーツ', 'ふるーつ'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
    ],
  ),
  FoodSuggestion(
    name: 'みかん',
    kcal: 46, protein: 0.7, fat: 0.1, carb: 11.0,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['みかん', 'ミカン', '蜜柑', 'くだもの', 'フルーツ', 'ふるーつ', 'たんげりん'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
      AmountOption(label: '3個', amount: 3),
    ],
  ),
  FoodSuggestion(
    name: 'いちご',
    kcal: 34, protein: 0.9, fat: 0.1, carb: 8.5,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['いちご', 'イチゴ', '苺', 'くだもの', 'フルーツ', 'ふるーつ', 'すとろべりー', 'ストロベリー'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'パイナップル',
    kcal: 53, protein: 0.6, fat: 0.1, carb: 13.7,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['パイナップル', 'ぱいなっぷる', 'くだもの', 'フルーツ', 'ふるーつ', 'ぱいん', 'パイン'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),

  // ── 脂質・ナッツ ──────────────────────────────────────────────
  FoodSuggestion(
    name: 'アボカド',
    kcal: 187, protein: 2.5, fat: 17.5, carb: 7.9,
    baseAmount: 100, baseUnit: 'g',
    searchTerms: ['アボカド', 'あぼかど', 'あぼがど', 'アボガド', 'くだもの', 'やさい'],
    amountOptions: [
      AmountOption(label: '50g',  amount:  50),
      AmountOption(label: '100g', amount: 100),
      AmountOption(label: '150g', amount: 150),
    ],
  ),
  FoodSuggestion(
    name: 'アーモンド',
    kcal: 152, protein: 5.1, fat: 13.0, carb: 5.5,
    baseAmount: 25, baseUnit: 'g',
    searchTerms: ['アーモンド', 'あーもんど', 'ナッツ', 'なっつ', 'あーまんど'],
    amountOptions: [
      AmountOption(label: '25g', amount: 25),
      AmountOption(label: '50g', amount: 50),
    ],
  ),
  FoodSuggestion(
    name: 'くるみ',
    kcal: 202, protein: 4.4, fat: 20.6, carb: 3.5,
    baseAmount: 30, baseUnit: 'g',
    searchTerms: ['くるみ', 'クルミ', '胡桃', 'ナッツ', 'なっつ', 'ウォルナッツ', 'うぉるなっつ'],
    amountOptions: [
      AmountOption(label: '30g', amount: 30),
      AmountOption(label: '60g', amount: 60),
    ],
  ),
  FoodSuggestion(
    name: 'ピーナッツバター',
    kcal: 96, protein: 4.1, fat: 8.1, carb: 3.2,
    baseAmount: 1, baseUnit: '大さじ',
    searchTerms: ['ピーナッツバター', 'ぴーなっつばたー', 'ぴーなっつ', 'ピーナッツ', 'なっつ', 'ぴーなっつすぷれっど'],
    amountOptions: [
      AmountOption(label: '大さじ1', amount: 1),
      AmountOption(label: '大さじ2', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'オリーブオイル',
    kcal: 125, protein: 0.0, fat: 14.0, carb: 0.0,
    baseAmount: 1, baseUnit: '大さじ',
    searchTerms: ['オリーブオイル', 'おりーぶおいる', 'あぶら', '油', 'オイル', 'おいる', 'おりーぶ'],
    amountOptions: [
      AmountOption(label: '大さじ1', amount: 1),
      AmountOption(label: '大さじ2', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'MCTオイル',
    kcal: 123, protein: 0.0, fat: 13.7, carb: 0.0,
    baseAmount: 1, baseUnit: '大さじ',
    searchTerms: ['MCTオイル', 'えむしーてぃーおいる', 'あぶら', '油', 'オイル', 'おいる', 'えむしーてぃー'],
    amountOptions: [
      AmountOption(label: '大さじ1', amount: 1),
      AmountOption(label: '大さじ2', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'ごま油',
    kcal: 125, protein: 0.0, fat: 13.9, carb: 0.0,
    baseAmount: 1, baseUnit: '大さじ',
    searchTerms: ['ごま油', 'ごまあぶら', 'ごま', 'セサミ', 'せさみ', 'あぶら', '油'],
    amountOptions: [
      AmountOption(label: '大さじ1', amount: 1),
      AmountOption(label: '大さじ2', amount: 2),
    ],
  ),

  // ── 減量・大会用 ──────────────────────────────────────────────
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
    name: 'はちみつ',
    kcal: 69, protein: 0.1, fat: 0.0, carb: 18.7,
    baseAmount: 1, baseUnit: '大さじ',
    searchTerms: ['はちみつ', 'ハチミツ', '蜂蜜', 'みつ', 'ハニー', 'はにー'],
    amountOptions: [
      AmountOption(label: '小さじ1', amount: 0.33),
      AmountOption(label: '大さじ1', amount: 1),
      AmountOption(label: '大さじ2', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: '塩おにぎり',
    kcal: 185, protein: 3.1, fat: 0.5, carb: 40.6,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['塩おにぎり', 'しおおにぎり', 'おにぎり', 'にぎりめし', 'おむすび', 'しおむすび'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'サラダチキン',
    kcal: 130, protein: 28.8, fat: 1.7, carb: 0.5,
    baseAmount: 1, baseUnit: '袋',
    searchTerms: ['サラダチキン', 'さらだちきん', 'ちきん', 'チキン', 'むねにく', 'とり', '鶏肉', 'とりにく'],
    amountOptions: [
      AmountOption(label: '1袋', amount: 1),
      AmountOption(label: '2袋', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'ゼロカロリーゼリー',
    kcal: 5, protein: 0.1, fat: 0.0, carb: 1.8,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['ゼロカロリーゼリー', 'ぜろかろりーぜりー', 'ゼリー', 'ぜりー', 'ダイエット', 'だいえっと', 'ぜろかろ'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: '和菓子',
    kcal: 216, protein: 3.2, fat: 0.4, carb: 49.2,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['和菓子', 'わがし', 'かし', '菓子', 'おかし', 'わかし'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: '大福',
    kcal: 235, protein: 4.1, fat: 0.4, carb: 54.5,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['大福', 'だいふく', 'もち', 'わがし', '和菓子', 'おかし', 'だいふくもち'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
  FoodSuggestion(
    name: 'どら焼き',
    kcal: 284, protein: 6.1, fat: 3.3, carb: 58.5,
    baseAmount: 1, baseUnit: '個',
    searchTerms: ['どら焼き', 'どらやき', 'どら', 'わがし', '和菓子', 'おかし'],
    amountOptions: [
      AmountOption(label: '1個', amount: 1),
      AmountOption(label: '2個', amount: 2),
    ],
  ),
];

/// キーワードで食事候補を検索する（最大4件）
///
/// startsWith一致を優先し、1文字入力でも意図した候補が先頭に表示される。
/// その後 contains一致で補完する。
List<FoodSuggestion> searchFoodSuggestions(String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final lower = q.toLowerCase();
  final starts = <FoodSuggestion>[];
  final others = <FoodSuggestion>[];
  for (final f in _kFoodSuggestions) {
    if (f.searchTerms.any((t) => t.toLowerCase().startsWith(lower))) {
      starts.add(f);
    } else if (f.searchTerms.any((t) => t.toLowerCase().contains(lower))) {
      others.add(f);
    }
  }
  return [...starts, ...others].take(4).toList();
}
