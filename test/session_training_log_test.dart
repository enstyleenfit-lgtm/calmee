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

  Widget buildCard({
    SessionTrainingLog log = const SessionTrainingLog(),
    Future<void> Function(List<SessionExercise>)? onSave,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SessionTrainingLogCard(
            log: log,
            onSave: onSave ?? (_) async {},
          ),
        ),
      ),
    );
  }

  Widget buildNotesScreen({
    SessionTrainingLog sessionTrainingLog = const SessionTrainingLog(),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SharedNotesScreen(
          loading: false,
          mealLogs: const [],
          exerciseLogs: const [],
          weightLogs: const [],
          notes: const [],
          goals: goals,
          selectedDate: DateTime(2026, 7, 8),
          onRefresh: () async {},
          sessionTrainingLog: sessionTrainingLog,
        ),
      ),
    );
  }

  // ── STL: トレーナー側 SessionTrainingLogCard ──────────────────────────────

  testWidgets('STL-1: SessionTrainingLogCard が表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.text('セッション記録'), findsOneWidget);
  });

  testWidgets('STL-2: 種目名入力欄が表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.widgetWithText(TextField, '種目名'), findsWidgets);
  });

  testWidgets('STL-3: 種目を追加するとリストに表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, '種目名'), 'ベンチプレス');
    await tester.pump();
    await tester.tap(find.text('追加'));
    await tester.pump();
    expect(find.text('ベンチプレス'), findsOneWidget);
  });

  testWidgets('STL-4: 種目を削除できる', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, '種目名'), 'スクワット');
    await tester.pump();
    await tester.tap(find.text('追加'));
    await tester.pump();
    expect(find.text('スクワット'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('スクワット'), findsNothing);
  });

  testWidgets('STL-5: 保存後 SnackBar「セッション記録を保存しました」が表示される',
      (tester) async {
    await tester.pumpWidget(buildCard(onSave: (_) async {}));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('セッション記録を保存しました'), findsOneWidget);
  });

  testWidgets('STL-6: 既存データがある場合に種目リストが表示される', (tester) async {
    const log = SessionTrainingLog(exercises: [
      SessionExercise(name: 'デッドリフト', weightKg: 100.0, reps: 5, sets: 3),
    ]);
    await tester.pumpWidget(buildCard(log: log));
    await tester.pump();
    expect(find.text('デッドリフト'), findsOneWidget);
  });

  // ── ST: 顧客側 SharedNotesScreen セッション記録セクション ─────────────────

  testWidgets('ST-4: 顧客側ノートタブに「セッション記録」セクションが表示される',
      (tester) async {
    const log = SessionTrainingLog(
        exercises: [SessionExercise(name: 'ショルダープレス')]);
    await tester.pumpWidget(buildNotesScreen(sessionTrainingLog: log));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('セッション記録'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('セッション記録'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ショルダープレス'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ショルダープレス'), findsOneWidget);
  });

  testWidgets('ST-5: セッション記録が空の場合「セッション記録はまだありません」が表示される',
      (tester) async {
    await tester.pumpWidget(buildNotesScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('セッション記録はまだありません'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('セッション記録はまだありません'), findsOneWidget);
  });
}
