import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/data/food_suggestions.dart';

void main() {
  group('searchFoodSuggestions', () {
    test('FS-1: 「む」で鶏むね肉が返る', () {
      final results = searchFoodSuggestions('む');
      expect(results.any((f) => f.name.contains('鶏むね肉')), isTrue);
    });

    test('FS-2: 「白」で白米が返る', () {
      final results = searchFoodSuggestions('白');
      expect(results.any((f) => f.name.contains('白米')), isTrue);
    });

    test('FS-3: 空文字で空リストが返る', () {
      expect(searchFoodSuggestions(''), isEmpty);
    });

    test('FS-4: スペースだけで空リストが返る', () {
      expect(searchFoodSuggestions('   '), isEmpty);
    });

    test('FS-5: ヒットしないキーワードで空リストが返る', () {
      expect(searchFoodSuggestions('zzz'), isEmpty);
    });

    test('FS-6: 最大4件まで返る', () {
      // 「ん」は白米(ごはん)・玄米(げんまい)・鶏むね肉(ちきん)・オートミール(えんばく)等5件以上ヒットするが上限4件
      final results = searchFoodSuggestions('ん');
      expect(results.length, lessThanOrEqualTo(4));
      expect(results.length, equals(4));
    });

    test('FS-7: 白米のkcal/PFC参考値が正しい', () {
      final results = searchFoodSuggestions('白米');
      expect(results, isNotEmpty);
      final item = results.first;
      expect(item.kcal, 168);
      expect(item.protein, 2.5);
      expect(item.fat, 0.3);
      expect(item.carb, 37.1);
    });

    test('FS-8: 鶏むね肉のkcal参考値が正しい', () {
      final results = searchFoodSuggestions('鶏むね肉');
      expect(results, isNotEmpty);
      expect(results.first.kcal, 108);
    });

    // ── かな・別名検索テスト ────────────────────────────────────────

    test('FS-9: 「しろ」で白米が返る（かな検索: しろまい）', () {
      final results = searchFoodSuggestions('しろ');
      expect(results.any((f) => f.name == '白米'), isTrue);
    });

    test('FS-10: 「ごはん」で白米が返る（別名検索）', () {
      final results = searchFoodSuggestions('ごはん');
      expect(results.any((f) => f.name == '白米'), isTrue);
    });

    test('FS-11: 「とり」で鶏むね肉が返る（かな検索）', () {
      final results = searchFoodSuggestions('とり');
      expect(results.any((f) => f.name == '鶏むね肉'), isTrue);
    });

    test('FS-12: 「たまご」で卵が返る（かな検索）', () {
      final results = searchFoodSuggestions('たまご');
      expect(results.any((f) => f.name == '卵'), isTrue);
    });

    test('FS-13: 「ぷろて」でプロテインが返る（かな検索）', () {
      final results = searchFoodSuggestions('ぷろて');
      expect(results.any((f) => f.name == 'プロテイン'), isTrue);
    });
  });
}
