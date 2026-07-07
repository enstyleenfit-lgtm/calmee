import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  Widget buildCard({
    KarteGoals goals = const KarteGoals(),
    VoidCallback? onOpenKarte,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomerGoalCard(
          goals: goals,
          onOpenKarte: onOpenKarte ?? () {},
        ),
      ),
    );
  }

  // ── GC: 目標カード ────────────────────────────────────────────
  testWidgets('GC-1: ゴール情報がある場合に最終目標が表示される', (tester) async {
    const goals = KarteGoals(finalGoal: '体重を10kg落とす');
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    expect(find.text('体重を10kg落とす'), findsOneWidget);
  });

  testWidgets('GC-2: ゴール情報がある場合に3ヶ月目標が表示される', (tester) async {
    const goals = KarteGoals(threeMonthGoal: '3ヶ月で5kg減');
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    expect(find.text('3ヶ月で5kg減'), findsOneWidget);
  });

  testWidgets('GC-3: ゴール情報がある場合に1ヶ月目標が表示される', (tester) async {
    const goals = KarteGoals(oneMonthGoal: '1ヶ月で2kg減');
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    expect(find.text('1ヶ月で2kg減'), findsOneWidget);
  });

  testWidgets('GC-4: ゴール情報がある場合に目標の理由が表示される', (tester) async {
    const goals = KarteGoals(goalReason: '結婚式に備えて');
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    expect(find.text('結婚式に備えて'), findsOneWidget);
  });

  testWidgets('GC-5: イベント予定がある場合に表示される', (tester) async {
    const goals = KarteGoals(
      finalGoal: '痩せる',
      eventSchedule: '2025年3月に結婚式',
    );
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    expect(find.text('2025年3月に結婚式'), findsOneWidget);
  });

  testWidgets('GC-6: ゴール情報がない場合に空状態メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.text('目標はまだ設定されていません'), findsOneWidget);
  });

  testWidgets('GC-7: ゴール情報がない場合に「カルテで設定する」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.text('カルテで設定する'), findsOneWidget);
  });

  testWidgets('GC-8: 「カルテを開く」ボタンが常に表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.text('カルテを開く'), findsOneWidget);
  });

  testWidgets('GC-9: 「カルテを開く」タップで onOpenKarte が呼ばれる', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildCard(onOpenKarte: () => called = true));
    await tester.pump();
    await tester.tap(find.text('カルテを開く'));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('GC-10: 「カルテで設定する」タップで onOpenKarte が呼ばれる', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildCard(onOpenKarte: () => called = true));
    await tester.pump();
    await tester.tap(find.text('カルテで設定する'));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('GC-11: kartePrivate のフィールド名が表示されない', (tester) async {
    // CustomerGoalCard は KarteGoals のみ受け取り kartePrivate は一切表示しない
    const goals = KarteGoals(finalGoal: '目標あり');
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    // KartePrivate 固有フィールドが UI に漏れていないことを確認
    expect(find.text('現在の課題'), findsNothing);
    expect(find.text('注意事項'), findsNothing);
    expect(find.text('次回確認事項'), findsNothing);
    expect(find.text('声かけ方'), findsNothing);
  });

  testWidgets('GC-12: イベント予定が空の場合はイベント行が表示されない', (tester) async {
    const goals = KarteGoals(finalGoal: '痩せる');
    await tester.pumpWidget(buildCard(goals: goals));
    await tester.pump();
    expect(find.text('イベント予定'), findsNothing);
  });
}
