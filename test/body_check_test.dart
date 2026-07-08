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

  Widget buildProgressScreen({BodyCheck bodyCheck = const BodyCheck()}) {
    return MaterialApp(
      home: Scaffold(
        body: ProgressScreen(
          weekMealLogs: const [],
          weekExerciseLogs: const [],
          recentWeightLogs: const [],
          goals: goals,
          bodyCheck: bodyCheck,
          onSaveBodyCheck: (_) async {},
        ),
      ),
    );
  }

  Widget buildBodyCheckCard({BodyCheck bodyCheck = const BodyCheck()}) {
    return MaterialApp(
      home: Scaffold(
        body: BodyCheckCard(bodyCheck: bodyCheck),
      ),
    );
  }

  // ── BC: 顧客側 体型チェック入力フォーム (ProgressScreen 経由) ─────────────

  testWidgets('BC-1: ProgressScreen に「体型チェック」見出しが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    // body check は週次チェックインの後のため .first なしで scroll
    await tester.scrollUntilVisible(
      find.text('体型チェック'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('体型チェック'), findsWidgets);
  });

  testWidgets('BC-2: 体型チェックの「保存」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('ウエスト (cm)'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保存'), findsWidgets);
  });

  testWidgets('BC-3: ウエスト入力ラベルが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('ウエスト (cm)'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ウエスト (cm)'), findsOneWidget);
  });

  testWidgets('BC-4: むくみスコアボタンが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('むくみ'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('むくみ'), findsOneWidget);
    // 週次チェックインと体型チェックの両方がキャッシュ内に入ることがあるため findsWidgets で確認
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('BC-5: 腹部つまみ感スコアボタンが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('腹部のつまみ感'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('腹部のつまみ感'), findsOneWidget);
  });

  testWidgets('BC-6: 見た目の変化・気になる部位ラベルが表示される', (tester) async {
    await tester.pumpWidget(buildProgressScreen());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('見た目の変化'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('見た目の変化'), findsOneWidget);
    expect(find.text('気になる部位'), findsOneWidget);
  });

  testWidgets('BC-7: 既存データがある場合にウエスト値が入力欄に表示される', (tester) async {
    const bc = BodyCheck(waist: 72.5);
    await tester.pumpWidget(buildProgressScreen(bodyCheck: bc));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('ウエスト (cm)'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('72.5'), findsOneWidget);
  });

  // ── BT: トレーナー側 BodyCheckCard (読み取り専用) ────────────────────────

  testWidgets('BT-1: 空状態で「体型チェックはまだ記録されていません」が表示される',
      (tester) async {
    await tester.pumpWidget(buildBodyCheckCard());
    await tester.pump();
    expect(find.text('体型チェックはまだ記録されていません'), findsOneWidget);
  });

  testWidgets('BT-2: ウエストが cm 付きで表示される', (tester) async {
    const bc = BodyCheck(waist: 70.0);
    await tester.pumpWidget(buildBodyCheckCard(bodyCheck: bc));
    await tester.pump();
    expect(find.text('70.0 cm'), findsOneWidget);
  });

  testWidgets('BT-3: 体重メモが表示される', (tester) async {
    const bc = BodyCheck(waist: 70.0, weightNote: '少し締まった感じ');
    await tester.pumpWidget(buildBodyCheckCard(bodyCheck: bc));
    await tester.pump();
    expect(find.text('少し締まった感じ'), findsOneWidget);
  });

  testWidgets('BT-4: むくみスコアが表示される', (tester) async {
    const bc = BodyCheck(waist: 70.0, edema: 3);
    await tester.pumpWidget(buildBodyCheckCard(bodyCheck: bc));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('BT-5: 「保存」ボタンが表示されない', (tester) async {
    const bc = BodyCheck(waist: 70.0);
    await tester.pumpWidget(buildBodyCheckCard(bodyCheck: bc));
    await tester.pump();
    expect(find.text('保存'), findsNothing);
  });

  testWidgets('BT-6: 「編集」ボタンが表示されない', (tester) async {
    const bc = BodyCheck(waist: 70.0);
    await tester.pumpWidget(buildBodyCheckCard(bodyCheck: bc));
    await tester.pump();
    expect(find.text('編集'), findsNothing);
  });
}
