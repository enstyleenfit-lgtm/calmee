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

  testWidgets('F-1: メッセージがある場合「トレーナーより」ラベルが表示される', (tester) async {
    await tester.pumpWidget(buildHome(messages: [msg1]));
    await tester.pump();
    expect(find.text('トレーナーより'), findsOneWidget);
  });

  testWidgets('F-2: メッセージ本文が表示される', (tester) async {
    await tester.pumpWidget(buildHome(messages: [msg1]));
    await tester.pump();
    expect(find.text('よく頑張りました！'), findsOneWidget);
  });

  testWidgets('F-3: メッセージがない場合「トレーナーより」ラベルが表示されない', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();
    expect(find.text('トレーナーより'), findsNothing);
  });

  testWidgets('F-4: 複数メッセージがある場合は先頭の1件だけ表示される', (tester) async {
    await tester.pumpWidget(buildHome(messages: [msg1, msg2]));
    await tester.pump();
    // msg1（先頭）の本文は表示される
    expect(find.text('よく頑張りました！'), findsOneWidget);
    // msg2 の本文は表示されない
    expect(find.text('明日も頑張りましょう'), findsNothing);
    // 「トレーナーより」は1件のみ
    expect(find.text('トレーナーより'), findsOneWidget);
  });
}
