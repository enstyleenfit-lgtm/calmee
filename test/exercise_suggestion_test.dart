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
      // 「ス」はスクワット・ショルダープレス・ブルガリアンスクワット等多数にヒットするが上限4件
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

    // ── 追加種目の検索テスト ──────────────────────────────────────

    test('ES-11: 「ベンチ」でベンチプレスが返る', () {
      final results = searchExerciseSuggestions('ベンチ');
      expect(results.any((e) => e.name.contains('ベンチプレス')), isTrue);
    });

    test('ES-12: 「サイドレイズ」でサイドレイズが返る', () {
      final results = searchExerciseSuggestions('サイドレイズ');
      expect(results.any((e) => e.name == 'サイドレイズ'), isTrue);
    });

    test('ES-13: 「アームカール」でアームカールが返る', () {
      final results = searchExerciseSuggestions('アームカール');
      expect(results.any((e) => e.name == 'アームカール'), isTrue);
    });

    test('ES-14: 「ウォーキング」でウォーキングが返る', () {
      final results = searchExerciseSuggestions('ウォーキング');
      expect(results.any((e) => e.name == 'ウォーキング'), isTrue);
    });

    test('ES-15: 「縄跳び」で縄跳びが返る', () {
      final results = searchExerciseSuggestions('縄跳び');
      expect(results.any((e) => e.name == '縄跳び'), isTrue);
    });

    test('ES-16: 「懸垂」で懸垂が返る', () {
      final results = searchExerciseSuggestions('懸垂');
      expect(results.any((e) => e.name == '懸垂'), isTrue);
    });

    // ── 追加種目の isStrengthTraining テスト ─────────────────────

    test('ES-17: ベンチプレスは isStrengthTraining が true', () {
      final results = searchExerciseSuggestions('ベンチプレス');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isTrue);
    });

    test('ES-18: サイドレイズは isStrengthTraining が true', () {
      final results = searchExerciseSuggestions('サイドレイズ');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isTrue);
    });

    test('ES-19: アームカールは isStrengthTraining が true', () {
      final results = searchExerciseSuggestions('アームカール');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isTrue);
    });

    test('ES-20: ウォーキングは isStrengthTraining が false', () {
      final results = searchExerciseSuggestions('ウォーキング');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isFalse);
    });

    test('ES-21: 縄跳びは isStrengthTraining が false', () {
      final results = searchExerciseSuggestions('縄跳び');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isFalse);
    });

    test('ES-22: ラットプルダウンは isStrengthTraining が true', () {
      final results = searchExerciseSuggestions('ラットプルダウン');
      expect(results, isNotEmpty);
      expect(results.first.isStrengthTraining, isTrue);
    });

    // ── 1文字ひらがな検索テスト ──────────────────────────────────

    test('ES-23: 「す」でスクワットが返る（1文字ひらがな検索）', () {
      final results = searchExerciseSuggestions('す');
      expect(results.any((e) => e.name == 'スクワット'), isTrue);
    });

    test('ES-24: 「べ」でベンチプレスが返る（1文字ひらがな検索）', () {
      final results = searchExerciseSuggestions('べ');
      expect(results.any((e) => e.name == 'ベンチプレス'), isTrue);
    });

    test('ES-25: 「で」でデッドリフトが返る（1文字ひらがな検索）', () {
      final results = searchExerciseSuggestions('で');
      expect(results.any((e) => e.name == 'デッドリフト'), isTrue);
    });

    test('ES-26: 「さ」でサイドレイズが返る（1文字ひらがな検索）', () {
      final results = searchExerciseSuggestions('さ');
      expect(results.any((e) => e.name == 'サイドレイズ'), isTrue);
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

  group('calcCardioKcal', () {
    final running = searchExerciseSuggestions('ランニング').first;   // referenceKcal=240
    final walking = searchExerciseSuggestions('ウォーキング').first; // referenceKcal=105

    test('CC-1: ランニング 30分 普通(1.0) → 240', () {
      expect(calcCardioKcal(running, 30, 1.0), 240);
    });

    test('CC-2: ランニング 60分 普通(1.0) → 480', () {
      expect(calcCardioKcal(running, 60, 1.0), 480);
    });

    test('CC-3: ランニング 30分 早め(1.2) → 288', () {
      expect(calcCardioKcal(running, 30, 1.2), 288);
    });

    test('CC-4: ランニング 30分 軽め(0.8) → 192', () {
      expect(calcCardioKcal(running, 30, 0.8), 192);
    });

    test('CC-5: ウォーキング 20分 軽め(0.8) → 56', () {
      expect(calcCardioKcal(walking, 20, 0.8), 56);
    });

    test('CC-6: ランニング 45分 普通(1.0) → 360', () {
      expect(calcCardioKcal(running, 45, 1.0), 360);
    });

    test('CC-7: ランニング 10分 早め(1.2) → 96', () {
      expect(calcCardioKcal(running, 10, 1.2), 96);
    });
  });
}
