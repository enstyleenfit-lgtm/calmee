import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  final now = DateTime(2026, 7, 8, 10, 0);

  TrainerMessage makeMsg(String text) => TrainerMessage(
        text: text,
        trainerUid: 'trainer1',
        createdAt: now,
      );

  Widget buildFeedbackCard({
    List<TrainerMessage> messages = const [],
    Future<void> Function(String)? onSend,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TrainerFeedbackInputCard(
            messages: messages,
            onSend: onSend ?? (_) async {},
          ),
        ),
      ),
    );
  }

  Widget buildSharedNotesScreen({
    List<TrainerMessage> trainerMessages = const [],
    List<SharedNote> notes = const [],
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SharedNotesScreen(
          loading: false,
          mealLogs: const [],
          exerciseLogs: const [],
          weightLogs: const [],
          notes: notes,
          goals: const GoalSettings(
            targetKcal: 2000,
            proteinTarget: 120,
            fatTarget: 55,
            carbTarget: 250,
          ),
          selectedDate: now,
          onRefresh: () async {},
          trainerMessages: trainerMessages,
        ),
      ),
    );
  }

  // ── TF: トレーナー側 TrainerFeedbackInputCard ─────────────────────────────

  testWidgets('TF-1: 定型文ボタンが3つ表示される', (tester) async {
    await tester.pumpWidget(buildFeedbackCard());
    await tester.pump();
    expect(find.text('良い感じです。この調子で継続しましょう。'), findsOneWidget);
    expect(find.text('食事量を少し調整していきましょう。'), findsOneWidget);
    expect(find.text('疲労が出ているので無理せず進めましょう。'), findsOneWidget);
  });

  testWidgets('TF-2: 定型文ボタンを押すと入力欄に反映される', (tester) async {
    await tester.pumpWidget(buildFeedbackCard());
    await tester.pump();
    await tester.tap(find.text('良い感じです。この調子で継続しましょう。'));
    await tester.pump();
    expect(find.widgetWithText(TextField, '良い感じです。この調子で継続しましょう。'), findsOneWidget);
  });

  testWidgets('TF-3: 入力欄が空のとき送信ボタンが無効', (tester) async {
    await tester.pumpWidget(buildFeedbackCard());
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('TF-4: 送信後 SnackBar「フィードバックを送信しました」が表示される',
      (tester) async {
    await tester.pumpWidget(buildFeedbackCard(onSend: (_) async {}));
    await tester.pump();
    await tester.tap(find.text('良い感じです。この調子で継続しましょう。'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('フィードバックを送信しました'), findsOneWidget);
  });

  testWidgets('TF-5: 既存メッセージがある場合に「直近のフィードバック」と履歴が表示される',
      (tester) async {
    final messages = [makeMsg('お疲れ様です'), makeMsg('引き続き頑張りましょう')];
    await tester.pumpWidget(buildFeedbackCard(messages: messages));
    await tester.pump();
    expect(find.text('直近のフィードバック'), findsOneWidget);
    expect(find.text('お疲れ様です'), findsOneWidget);
    expect(find.text('引き続き頑張りましょう'), findsOneWidget);
  });

  // ── ST: 顧客側 SharedNotesScreen トレーナーフィードバックセクション ─────────

  testWidgets('ST-1: trainerMessages がある場合「トレーナーフィードバック」セクションとメッセージが表示される',
      (tester) async {
    final messages = [makeMsg('食事がとても良いです')];
    await tester.pumpWidget(buildSharedNotesScreen(trainerMessages: messages));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('トレーナーフィードバック'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('トレーナーフィードバック'), findsOneWidget);
    expect(find.text('食事がとても良いです'), findsOneWidget);
  });

  testWidgets('ST-2: trainerMessages が空の場合「フィードバックはまだありません」が表示される',
      (tester) async {
    await tester.pumpWidget(buildSharedNotesScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('フィードバックはまだありません'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('フィードバックはまだありません'), findsOneWidget);
  });

  testWidgets('ST-3: トレーナーフィードバックと sharedNotes が共存して表示される',
      (tester) async {
    final messages = [makeMsg('よく頑張っています')];
    final notes = [
      SharedNote(
        title: 'ノートタイトル',
        body: 'ノート本文',
        trainerUid: 'trainer1',
        createdAt: now,
      ),
    ];
    await tester.pumpWidget(
        buildSharedNotesScreen(trainerMessages: messages, notes: notes));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('よく頑張っています'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('よく頑張っています'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ノートタイトル'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ノートタイトル'), findsOneWidget);
  });
}
