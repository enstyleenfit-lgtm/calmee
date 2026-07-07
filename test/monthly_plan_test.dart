import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Widget buildTrainerCard({
    MonthlyPlan plan = const MonthlyPlan(),
    MonthlyPlanMemo memo = const MonthlyPlanMemo(),
    VoidCallback? onEdit,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TrainerMonthlyPlanCard(
          plan: plan,
          memo: memo,
          onEdit: onEdit ?? () {},
        ),
      ),
    );
  }

  Widget buildCustomerScreen({MonthlyPlan monthlyPlan = const MonthlyPlan()}) {
    return MaterialApp(
      home: Scaffold(
        body: SharedNotesScreen(
          loading: false,
          mealLogs: const [],
          exerciseLogs: const [],
          weightLogs: const [],
          notes: const [],
          goals: const GoalSettings(),
          monthlyPlan: monthlyPlan,
          selectedDate: today,
          onRefresh: () async {},
        ),
      ),
    );
  }

  // ── MP-T: トレーナー側 月次計画カード ─────────────────────────────────

  testWidgets('MP-T1: 計画が空のとき「まだ計画が入力されていません」が表示される', (tester) async {
    await tester.pumpWidget(buildTrainerCard());
    await tester.pump();
    expect(find.text('まだ計画が入力されていません'), findsOneWidget);
  });

  testWidgets('MP-T2: 計画がある場合に今月の目標が表示される', (tester) async {
    const plan = MonthlyPlan(monthGoal: '体重を2kg落とす');
    await tester.pumpWidget(buildTrainerCard(plan: plan));
    await tester.pump();
    expect(find.text('体重を2kg落とす'), findsOneWidget);
  });

  testWidgets('MP-T3: 食事方針・運動方針・体重体型・注意点が表示される', (tester) async {
    const plan = MonthlyPlan(
      dietPolicy: 'タンパク質を増やす',
      exercisePolicy: '週3回筋トレ',
      bodyPolicy: '体脂肪率維持',
      caution: '膝に注意',
    );
    await tester.pumpWidget(buildTrainerCard(plan: plan));
    await tester.pump();
    expect(find.text('タンパク質を増やす'), findsOneWidget);
    expect(find.text('週3回筋トレ'), findsOneWidget);
    expect(find.text('体脂肪率維持'), findsOneWidget);
    expect(find.text('膝に注意'), findsOneWidget);
  });

  testWidgets('MP-T4: トレーナーメモが表示される（トレーナー側）', (tester) async {
    const memo = MonthlyPlanMemo(trainerMemo: '先月から進捗良好');
    await tester.pumpWidget(buildTrainerCard(memo: memo));
    await tester.pump();
    expect(find.text('先月から進捗良好'), findsOneWidget);
  });

  testWidgets('MP-T5: 計画が空のとき「計画を入力」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildTrainerCard());
    await tester.pump();
    expect(find.text('計画を入力'), findsOneWidget);
  });

  testWidgets('MP-T6: 計画がある場合は「編集」ボタンが表示される', (tester) async {
    const plan = MonthlyPlan(monthGoal: '目標あり');
    await tester.pumpWidget(buildTrainerCard(plan: plan));
    await tester.pump();
    expect(find.text('編集'), findsOneWidget);
  });

  testWidgets('MP-T7: 「今月の計画」ヘッダーが表示される', (tester) async {
    await tester.pumpWidget(buildTrainerCard());
    await tester.pump();
    expect(find.text('今月の計画'), findsOneWidget);
  });

  // ── MP-C: 顧客側 月次計画カード (SharedNotesScreen 経由) ──────────────

  testWidgets('MP-C1: 計画が空のとき「今月の計画はまだ設定されていません」が表示される', (tester) async {
    await tester.pumpWidget(buildCustomerScreen());
    await tester.pump();
    expect(find.text('今月の計画はまだ設定されていません'), findsOneWidget);
  });

  testWidgets('MP-C2: 計画がある場合に今月の目標が表示される', (tester) async {
    const plan = MonthlyPlan(monthGoal: '3kg減量');
    await tester.pumpWidget(buildCustomerScreen(monthlyPlan: plan));
    await tester.pump();
    expect(find.text('3kg減量'), findsOneWidget);
  });

  testWidgets('MP-C3: 食事方針・運動方針・体重体型・注意点が表示される', (tester) async {
    const plan = MonthlyPlan(
      dietPolicy: '野菜から食べる',
      exercisePolicy: '毎日ウォーキング',
      bodyPolicy: '体重維持',
      caution: '腰を大切に',
    );
    await tester.pumpWidget(buildCustomerScreen(monthlyPlan: plan));
    await tester.pump();
    expect(find.text('野菜から食べる'), findsOneWidget);
    expect(find.text('毎日ウォーキング'), findsOneWidget);
    expect(find.text('体重維持'), findsOneWidget);
    expect(find.text('腰を大切に'), findsOneWidget);
  });

  testWidgets('MP-C4: トレーナーメモは顧客側に表示されない', (tester) async {
    // monthlyPlan には trainerMemo がないので表示されようがないことを確認
    // (trainerMemo は MonthlyPlanMemo に属し SharedNotesScreen には渡さない)
    const plan = MonthlyPlan(monthGoal: '目標あり');
    await tester.pumpWidget(buildCustomerScreen(monthlyPlan: plan));
    await tester.pump();
    expect(find.text('トレーナーメモ'), findsNothing);
  });

  testWidgets('MP-C5: 顧客側に編集ボタンが表示されない', (tester) async {
    await tester.pumpWidget(buildCustomerScreen());
    await tester.pump();
    expect(find.text('計画を入力'), findsNothing);
    expect(find.text('編集'), findsNothing);
  });

  testWidgets('MP-C6: 計画カードの見出し「今月の計画」が表示される', (tester) async {
    await tester.pumpWidget(buildCustomerScreen());
    await tester.pump();
    expect(find.text('今月の計画'), findsOneWidget);
  });
}
