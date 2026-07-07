import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Widget buildScreen({KarteGoals karteGoals = const KarteGoals()}) {
    return MaterialApp(
      home: Scaffold(
        body: SharedNotesScreen(
          loading: false,
          mealLogs: const [],
          exerciseLogs: const [],
          weightLogs: const [],
          notes: const [],
          goals: const GoalSettings(),
          karteGoals: karteGoals,
          selectedDate: today,
          onRefresh: () async {},
        ),
      ),
    );
  }

  // ── SNG: 顧客ノートタブ 目標カード ──────────────────────────────

  testWidgets('SNG-1: ゴール情報がある場合に最終目標が表示される', (tester) async {
    const goals = KarteGoals(finalGoal: '体重を10kg落とす');
    await tester.pumpWidget(buildScreen(karteGoals: goals));
    await tester.pump();
    expect(find.text('体重を10kg落とす'), findsOneWidget);
  });

  testWidgets('SNG-2: ゴール情報がない場合に空状態メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('目標はまだ設定されていません'), findsOneWidget);
  });

  testWidgets('SNG-3: 目標カードが今日のまとめカードとともに表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('今日のまとめ'), findsOneWidget);
    expect(find.text('目標'), findsOneWidget);
  });

  testWidgets('SNG-4: kartePrivate のフィールドが表示されない', (tester) async {
    const goals = KarteGoals(finalGoal: '目標あり');
    await tester.pumpWidget(buildScreen(karteGoals: goals));
    await tester.pump();
    expect(find.text('現在の課題'), findsNothing);
    expect(find.text('注意事項'), findsNothing);
    expect(find.text('次回確認事項'), findsNothing);
    expect(find.text('声かけ方'), findsNothing);
  });

  testWidgets('SNG-5: 「カルテを開く」ボタンが表示されない（顧客はカルテを直接開けない）',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('カルテを開く'), findsNothing);
  });

  testWidgets('SNG-6: 「カルテで設定する」ボタンが表示されない（顧客は自分でカルテを設定できない）',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('カルテで設定する'), findsNothing);
  });

  testWidgets('SNG-7: イベント予定がある場合に表示される', (tester) async {
    const goals = KarteGoals(
      finalGoal: '痩せる',
      eventSchedule: '2025年3月に結婚式',
    );
    await tester.pumpWidget(buildScreen(karteGoals: goals));
    await tester.pump();
    expect(find.text('2025年3月に結婚式'), findsOneWidget);
  });

  testWidgets('SNG-8: 複数ゴールが設定されている場合にすべて表示される', (tester) async {
    const goals = KarteGoals(
      finalGoal: '最終目標テキスト',
      threeMonthGoal: '3ヶ月目標テキスト',
      oneMonthGoal: '1ヶ月目標テキスト',
      goalReason: '目標理由テキスト',
    );
    await tester.pumpWidget(buildScreen(karteGoals: goals));
    await tester.pump();
    expect(find.text('最終目標テキスト'), findsOneWidget);
    expect(find.text('3ヶ月目標テキスト'), findsOneWidget);
    expect(find.text('1ヶ月目標テキスト'), findsOneWidget);
    expect(find.text('目標理由テキスト'), findsOneWidget);
  });
}
