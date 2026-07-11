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

  Widget buildProgressScreen({Map<String, DailyCheckin>? initialDailyCheckins}) {
    return MaterialApp(
      home: Scaffold(
        body: ProgressScreen(
          weekMealLogs: const [],
          weekExerciseLogs: const [],
          recentWeightLogs: const [],
          goals: goals,
          customerUid: 'test-uid',
          initialDailyCheckins: initialDailyCheckins ?? const {},
          onSaveDailyCheckin: (_, _) async {},
        ),
      ),
    );
  }

  Widget buildWeekCard({Map<String, DailyCheckin>? initialData}) {
    return MaterialApp(
      home: Scaffold(
        body: DailyCheckinWeekCard(
          customerUid: 'test-uid',
          initialData: initialData ?? const {},
          onSave: (_, _) async {},
        ),
      ),
    );
  }

  Widget buildCheckinCard({WeeklyCheckin checkin = const WeeklyCheckin()}) {
    return MaterialApp(
      home: Scaffold(
        body: WeeklyCheckinCard(checkin: checkin),
      ),
    );
  }

  // ── DW: 顧客側 日次チェックイン（DailyCheckinWeekCard） ────────────────────

  testWidgets('DW-1: ProgressScreen に「今週のチェックイン」見出しが表示される',
      (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('今週のチェックイン').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('今週のチェックイン'), findsWidgets);
  });

  testWidgets('DW-2: 7つの曜日タブ（月〜日）が表示される', (tester) async {
    await tester.pumpWidget(buildWeekCard());
    await tester.pump();
    for (final label in ['月', '火', '水', '木', '金', '土', '日']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('DW-3: 未記録のとき空状態メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildWeekCard());
    await tester.pump();
    expect(find.text('まだ記録がありません'), findsOneWidget);
  });

  testWidgets('DW-4: 「この日の状態を更新」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWeekCard());
    await tester.pump();
    expect(find.text('この日の状態を更新'), findsOneWidget);
  });

  testWidgets('DW-5: フォームを開くとスコアボタンが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildWeekCard());
    await tester.pump();
    await tester.tap(find.text('この日の状態を更新'));
    await tester.pump();
    // 5 項目 × ボタン '1' が 5 個（各行に 1 が 1 つずつ）
    expect(find.text('1'), findsNWidgets(5));
    expect(find.text('5'), findsNWidgets(5));
  });

  // ── WT: トレーナー側 WeeklyCheckinCard (読み取り専用) ────────────────────

  testWidgets('WT-1: チェックインが空のとき空状態メッセージが表示される', (tester) async {
    await tester.pumpWidget(buildCheckinCard());
    await tester.pump();
    expect(find.text('今週のチェックインはまだ入力されていません'), findsOneWidget);
  });

  testWidgets('WT-2: 達成度が数字で表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 4);
    await tester.pumpWidget(buildCheckinCard(checkin: checkin));
    await tester.pump();
    expect(find.text('今週の達成度'), findsOneWidget);
    // スコア表示
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('WT-3: 体調メモが表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3, bodyNote: '少し疲れ気味');
    await tester.pumpWidget(buildCheckinCard(checkin: checkin));
    await tester.pump();
    expect(find.text('少し疲れ気味'), findsOneWidget);
  });

  testWidgets('WT-4: 相談事項が表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3, consultation: '食事量を増やしたい');
    await tester.pumpWidget(buildCheckinCard(checkin: checkin));
    await tester.pump();
    expect(find.text('食事量を増やしたい'), findsOneWidget);
  });

  testWidgets('WT-5: 「保存」ボタンが表示されない', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3);
    await tester.pumpWidget(buildCheckinCard(checkin: checkin));
    await tester.pump();
    expect(find.text('保存'), findsNothing);
  });

  testWidgets('WT-6: 「編集」ボタンが表示されない', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3);
    await tester.pumpWidget(buildCheckinCard(checkin: checkin));
    await tester.pump();
    expect(find.text('編集'), findsNothing);
  });
}
