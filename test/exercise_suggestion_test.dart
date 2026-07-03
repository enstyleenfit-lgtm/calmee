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

    test('ES-9: スクワットは isStrengthTraining が true', () {
      final results = searchExerciseSuggestions('スクワット');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isTrue);
    });

    test('ES-10: ランニングは isStrengthTraining が false', () {
      final results = searchExerciseSuggestions('ランニング');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isFalse);
    });
  });

  group('calcEstimatedKcal', () {
    final squat = searchExerciseSuggestions('スクワット').first;   // referenceKcal=150, strength
    final running = searchExerciseSuggestions('ランニング').first; // referenceKcal=240, aerobic

    test('CK-1: 重量なし（null）→ referenceKcal', () {
      expect(calcEstimatedKcal(squat, null), 150);
    });

    test('CK-2: 20kg以下 → referenceKcal × 1.0', () {
      expect(calcEstimatedKcal(squat, 20), 150);
    });

    test('CK-3: 40kg（21〜50）→ referenceKcal × 1.1 = 165', () {
      expect(calcEstimatedKcal(squat, 40), 165);
    });

    test('CK-4: 60kg（51〜80）→ referenceKcal × 1.2 = 180', () {
      expect(calcEstimatedKcal(squat, 60), 180);
    });

    test('CK-5: 90kg（81以上）→ referenceKcal × 1.3 = 195', () {
      expect(calcEstimatedKcal(squat, 90), 195);
    });

    test('CK-6: 有酸素（ランニング）は重量 60kg でも referenceKcal のまま', () {
      expect(calcEstimatedKcal(running, 60), 240);
    });

    test('CK-7: 有酸素（ランニング）は重量 100kg でも referenceKcal のまま', () {
      expect(calcEstimatedKcal(running, 100), 240);
    });
  });
}
