import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings();
  final pastDate = DateTime(2024, 7, 1); // 月曜日・過去

  Widget buildHome({
    required DateTime date,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          loading: false,
          goals: goals,
          mealLogs: const [],
          exerciseLogs: const [],
          weightLogs: const [],
          recentWeightLogs: const [],
          onRefresh: () async {},
          onDeleteMeal: (_) async {},
          onDeleteExercise: (_) async {},
          onDeleteWeight: (_) async {},
          selectedDate: date,
          onPrevDay: onPrev,
          onNextDay: onNext,
        ),
      ),
    );
  }

  testWidgets('D-1: 前日ボタンをタップすると onPrevDay が呼ばれる', (tester) async {
    var called = false;
    await tester.pumpWidget(buildHome(
      date: pastDate,
      onPrev: () => called = true,
      onNext: () {},
    ));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('D-2: 翌日ボタンをタップすると onNextDay が呼ばれる（過去日）', (tester) async {
    var called = false;
    await tester.pumpWidget(buildHome(
      date: pastDate,
      onPrev: () {},
      onNext: () => called = true,
    ));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('D-3: 日付ラベルが正しく表示される（7月1日（月））', (tester) async {
    await tester.pumpWidget(buildHome(
      date: pastDate,
      onPrev: () {},
      onNext: () {},
    ));
    expect(find.text('7月1日（月）'), findsOneWidget);
  });

  testWidgets('D-4: 今日の日付のとき翌日ボタンは無効（onNextDay が呼ばれない）', (tester) async {
    var called = false;
    await tester.pumpWidget(buildHome(
      date: DateTime.now(),
      onPrev: () {},
      onNext: () => called = true,
    ));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(called, isFalse);
  });
}
