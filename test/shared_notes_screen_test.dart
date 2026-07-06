import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Widget buildScreen({
    bool loading = false,
    List<MealLogEntry> mealLogs = const [],
    List<ExerciseLogEntry> exerciseLogs = const [],
    List<WeightLogEntry> weightLogs = const [],
    List<SharedNote> notes = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SharedNotesScreen(
          loading: loading,
          mealLogs: mealLogs,
          exerciseLogs: exerciseLogs,
          weightLogs: weightLogs,
          notes: notes,
          goals: const GoalSettings(),
          selectedDate: today,
          onRefresh: () async {},
        ),
      ),
    );
  }

  // ── SN-1: まとめカード ────────────────────────────────────────
  testWidgets('SN-1: 今日のまとめ見出しが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('今日のまとめ'), findsOneWidget);
  });

  testWidgets('SN-2: loading=true のときはインジケータが表示される', (tester) async {
    await tester.pumpWidget(buildScreen(loading: true));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('今日のまとめ'), findsNothing);
  });

  // ── SN-3: 食事 ────────────────────────────────────────────────
  testWidgets('SN-3: 食事がある場合に食事名が表示される', (tester) async {
    final meal = MealLogEntry(
      name: 'チキンライス',
      kcal: 500,
      protein: 30,
      fat: 10,
      carb: 60,
      loggedAt: today,
      date: today,
    );
    await tester.pumpWidget(buildScreen(mealLogs: [meal]));
    await tester.pump();
    expect(find.text('チキンライス'), findsOneWidget);
  });

  testWidgets('SN-4: 食事がない場合に空メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('食事記録はありません'), findsOneWidget);
  });

  // ── SN-5: 運動 ────────────────────────────────────────────────
  testWidgets('SN-5: 運動がある場合に運動名が表示される', (tester) async {
    final exercise = ExerciseLogEntry(
      name: 'スクワット',
      kcal: 150,
      category: 'self',
      loggedAt: today,
      date: today,
    );
    await tester.pumpWidget(buildScreen(exerciseLogs: [exercise]));
    await tester.pump();
    expect(find.text('スクワット'), findsOneWidget);
  });

  testWidgets('SN-6: 運動がない場合に空メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('運動記録はありません'), findsOneWidget);
  });

  // ── SN-7: 体重 ────────────────────────────────────────────────
  testWidgets('SN-7: 体重がある場合に体重が表示される', (tester) async {
    final weight = WeightLogEntry(
      weight: 65.5,
      loggedAt: today,
      date: today,
    );
    await tester.pumpWidget(buildScreen(weightLogs: [weight]));
    await tester.pump();
    expect(find.text('65.5 kg'), findsOneWidget);
  });

  testWidgets('SN-8: 体重がない場合に空メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('体重記録はありません'), findsOneWidget);
  });

  // ── SN-9: トレーナーノート ─────────────────────────────────────
  testWidgets('SN-9: ノートがある場合にタイトルが表示される', (tester) async {
    final note = SharedNote(
      title: '今週のトレーニング計画',
      body: 'スクワット3セット...',
      trainerUid: 'trainer-t1',
      createdAt: today,
    );
    await tester.pumpWidget(buildScreen(notes: [note]));
    await tester.pump();
    expect(find.text('今週のトレーニング計画'), findsOneWidget);
  });

  testWidgets('SN-10: ノートがない場合に空メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('トレーナーからのノートはまだありません'), findsOneWidget);
  });
}
