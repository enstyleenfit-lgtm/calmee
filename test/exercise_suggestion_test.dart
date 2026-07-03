import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/data/exercise_suggestions.dart';

void main() {
  group('searchExerciseSuggestions', () {
    test('ES-1: 「ラン」でランニングが返る', () {
      final results = searchExerciseSuggestions('ラン');
      expect(results.any((e) => e.name.contains('ランニング')), isTrue);
    });

    test('ES-2: 「スク」でスクワットが返る', () {
      final results = searchExerciseSuggestions('スク');
      expect(results.any((e) => e.name.contains('スクワット')), isTrue);
    });

    test('ES-3: 空文字で空リストが返る', () {
      expect(searchExerciseSuggestions(''), isEmpty);
    });

    test('ES-4: ヒットしないキーワードで空リストが返る', () {
      expect(searchExerciseSuggestions('zzz'), isEmpty);
    });

    test('ES-5: 最大4件まで返る', () {
      // 「ス」はスクワット・ショルダープレス・レッグプレス・クロストレーナーにヒット
      final results = searchExerciseSuggestions('ス');
      expect(results.length, lessThanOrEqualTo(4));
    });

    test('ES-6: ランニングの referenceKcal は 240', () {
      final results = searchExerciseSuggestions('ランニング');
      expect(results, isNotEmpty);
      expect(results.first.referenceKcal, 240);
    });

    test('ES-7: ランニングの met は 8.0', () {
      final results = searchExerciseSuggestions('ランニング');
      expect(results, isNotEmpty);
      expect(results.first.met, 8.0);
    });

    test('ES-8: スクワットの category は self', () {
      final results = searchExerciseSuggestions('スクワット');
      expect(results, isNotEmpty);
      expect(results.first.category, 'self');
    });
  });
}
