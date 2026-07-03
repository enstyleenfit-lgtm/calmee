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
      // 「100」は複数候補にヒットする
      final results = searchFoodSuggestions('100');
      expect(results.length, lessThanOrEqualTo(4));
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
  });
}
