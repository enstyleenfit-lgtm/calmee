import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings();
  final baseDate = DateTime(2024, 7, 1);

  // テスト用メッセージ
  final msg1 = TrainerMessage(
    id: 'msg-1',
    text: 'よく頑張りました！',
    trainerUid: 'trainer-t1',
    createdAt: DateTime(2024, 7, 1, 10, 0),
  );
  final msg2 = TrainerMessage(
    id: 'msg-2',
    text: '明日も頑張りましょう',
    trainerUid: 'trainer-t1',
    createdAt: DateTime(2024, 7, 1, 9, 0),
  );

  // フィードバックカードは DateNavBar の直下（画面上部）に描画されるため
  // setSurfaceSize 不要
  Widget buildHome({List<TrainerMessage> messages = const []}) {
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
          selectedDate: baseDate,
          onPrevDay: () {},
          onNextDay: () {},
          trainerMessages: messages,
        ),
      ),
    );
  }

  // トレーナーメッセージカードはUX改善のため非表示にした。
  // データ構造・Firestore・送信機能は保持。

  testWidgets('F-1: メッセージがあっても「トレーナーより」ラベルは表示されない', (tester) async {
    await tester.pumpWidget(buildHome(messages: [msg1]));
    await tester.pump();
    expect(find.text('トレーナーより'), findsNothing);
  });

  testWidgets('F-2: メッセージがあってもメッセージ本文は表示されない', (tester) async {
    await tester.pumpWidget(buildHome(messages: [msg1]));
    await tester.pump();
    expect(find.text('よく頑張りました！'), findsNothing);
  });

  testWidgets('F-3: メッセージがない場合も「トレーナーより」ラベルが表示されない', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();
    expect(find.text('トレーナーより'), findsNothing);
  });

  testWidgets('F-4: 複数メッセージがあってもいずれも表示されない', (tester) async {
    await tester.pumpWidget(buildHome(messages: [msg1, msg2]));
    await tester.pump();
    expect(find.text('よく頑張りました！'), findsNothing);
    expect(find.text('明日も頑張りましょう'), findsNothing);
    expect(find.text('トレーナーより'), findsNothing);
  });
}
