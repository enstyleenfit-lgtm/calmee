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

  Widget buildHome({
    List<MealLogEntry> mealLogs = const [],
    List<ExerciseLogEntry> exerciseLogs = const [],
    List<WeightLogEntry> weightLogs = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          loading: false,
          goals: goals,
          mealLogs: mealLogs,
          exerciseLogs: exerciseLogs,
          weightLogs: weightLogs,
          recentWeightLogs: const [],
          onRefresh: () async {},
          onDeleteMeal: (_) async {},
          onDeleteExercise: (_) async {},
          onDeleteWeight: (_) async {},
          selectedDate: DateTime(2024, 7, 1),
          onPrevDay: () {},
          onNextDay: () {},
        ),
      ),
    );
  }

  testWidgets('H-1: タイトル「からだ収支」が表示される', (tester) async {
    await tester.pumpWidget(buildHome());
    expect(find.text('からだ収支'), findsOneWidget);
  });

  testWidgets('H-2: 摂取カロリーと目標カロリーが表示される', (tester) async {
    final meal = MealLogEntry(
      name: 'テスト',
      kcal: 500,
      protein: 20.0,
      fat: 10.0,
      carb: 60.0,
      loggedAt: DateTime.now(),
      date: DateTime.now(),
    );
    await tester.pumpWidget(buildHome(mealLogs: [meal]));
    expect(find.text('500'), findsWidgets);
    expect(find.text('2000'), findsWidgets);
  });

  testWidgets('H-3: PFCラベル P/F/C が3つ表示される', (tester) async {
    await tester.pumpWidget(buildHome());
    expect(find.text('P'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('H-4: 食事が空のとき空状態メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildHome());
    expect(find.text('+ ボタンから食事を記録しよう'), findsOneWidget);
  });

  testWidgets('H-5: 運動が空のとき空状態メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('+ ボタンから運動を記録しよう'), findsOneWidget);
  });
}
