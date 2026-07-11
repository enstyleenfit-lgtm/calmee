import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings(
    targetKcal: 2000,
    proteinTarget: 120.0,
    fatTarget: 55.0,
    carbTarget: 250.0,
  );

  Widget buildProgress({
    List<MealLogEntry> weekMealLogs = const [],
    List<ExerciseLogEntry> weekExerciseLogs = const [],
    List<WeightLogEntry> recentWeightLogs = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProgressScreen(
          weekMealLogs: weekMealLogs,
          weekExerciseLogs: weekExerciseLogs,
          recentWeightLogs: recentWeightLogs,
          goals: goals,
          customerUid: 'test-uid',
          initialDailyCheckins: const {},
        ),
      ),
    );
  }

  testWidgets('P-1: タイトル「週次進捗」が表示される', (tester) async {
    await tester.pumpWidget(buildProgress());
    expect(find.text('週次進捗'), findsOneWidget);
  });

  testWidgets('P-2: 空データで「0/7日」が表示される', (tester) async {
    await tester.pumpWidget(buildProgress());
    expect(find.text('0/7日'), findsOneWidget);
  });

  testWidgets('P-3: 空データで「0 kcal」が複数表示される', (tester) async {
    await tester.pumpWidget(buildProgress());
    expect(find.text('0 kcal'), findsWidgets);
  });

  testWidgets('P-4: 食事ログ追加で摂取カロリーが反映される', (tester) async {
    final meal = MealLogEntry(
      name: 'テスト',
      kcal: 500,
      protein: 20.0,
      fat: 10.0,
      carb: 60.0,
      loggedAt: DateTime.now(),
      date: DateTime.now(),
    );
    await tester.pumpWidget(buildProgress(weekMealLogs: [meal]));
    expect(find.text('500 kcal'), findsWidgets);
  });

  testWidgets('P-5: 日別テーブルのヘッダーが表示される', (tester) async {
    await tester.pumpWidget(buildProgress());
    expect(find.text('日付'), findsOneWidget);
    expect(find.text('摂取'), findsOneWidget);
    expect(find.text('消費'), findsOneWidget);
    expect(find.text('収支'), findsOneWidget);
  });
}
