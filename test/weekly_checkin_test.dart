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

  Widget buildProgressScreen({WeeklyCheckin checkin = const WeeklyCheckin()}) {
    return MaterialApp(
      home: Scaffold(
        body: ProgressScreen(
          weekMealLogs: const [],
          weekExerciseLogs: const [],
          recentWeightLogs: const [],
          goals: goals,
          checkin: checkin,
          onSaveCheckin: (_) async {},
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

  // ── WC: 顧客側 週次チェックイン入力フォーム (ProgressScreen 経由) ──────────

  testWidgets('WC-1: ProgressScreen に「今週のチェックイン」見出しが表示される',
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

  testWidgets('WC-2: 「保存」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('保存'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('WC-3: 各スコア行に 1〜5 の数字ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('今週の達成度'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    // 5 項目 × ボタン '1' が 5 個（各行に 1 が 1 つずつ）
    expect(find.text('1'), findsNWidgets(5));
    expect(find.text('5'), findsNWidgets(5));
  });

  testWidgets('WC-4: 体調メモラベルが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('体調メモ'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('体調メモ'), findsOneWidget);
  });

  testWidgets('WC-5: 相談事項ラベルが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('トレーナーに相談したいこと'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('トレーナーに相談したいこと'), findsOneWidget);
  });

  testWidgets('WC-6: 未回答のとき「未回答」テキストが達成度行に表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('未回答').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    // 5 項目すべてが未回答
    expect(find.text('未回答'), findsNWidgets(5));
  });

  testWidgets('WC-7: 入力済みチェックインがある場合スコアボタンが表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3, hunger: 2);
    await tester.pumpWidget(buildProgressScreen(checkin: checkin));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('今週の達成度'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    // ボタン '3' は achievement 行と hunger 行以外にも全行存在する
    expect(find.text('3'), findsNWidgets(5));
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
