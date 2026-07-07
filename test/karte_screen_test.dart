import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  // ── KB: 基本情報タブ ──────────────────────────────────────────
  testWidgets('KB-1: 基本情報タブに「年齢」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteBasicInfoTab(
          info: const KarteBasicInfo(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('年齢'), findsOneWidget);
  });

  testWidgets('KB-2: 基本情報タブに「身長 (cm)」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteBasicInfoTab(
          info: const KarteBasicInfo(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('身長 (cm)'), findsOneWidget);
  });

  testWidgets('KB-3: 基本情報タブに「保存する」ボタンが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteBasicInfoTab(
          info: const KarteBasicInfo(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('保存する'), findsOneWidget);
  });

  testWidgets('KB-4: 基本情報タブに既存データが表示される', (tester) async {
    const info = KarteBasicInfo(age: 30, height: 168.0);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteBasicInfoTab(
          info: info,
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('30'), findsOneWidget);
  });

  // ── KB: ヒアリングタブ ────────────────────────────────────────
  testWidgets('KB-5: ヒアリングタブに「なぜ始めたいのか」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteHearingTab(
          hearing: const KarteHearing(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('なぜ始めたいのか'), findsOneWidget);
  });

  testWidgets('KB-6: ヒアリングタブに「既往歴・注意事項」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteHearingTab(
          hearing: const KarteHearing(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('既往歴・注意事項'), findsOneWidget);
  });

  testWidgets('KB-7: ヒアリングタブに既存データが表示される', (tester) async {
    const hearing = KarteHearing(motivation: '結婚式のためにきれいになりたい');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteHearingTab(
          hearing: hearing,
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('結婚式のためにきれいになりたい'), findsOneWidget);
  });

  // ── KB: ゴールタブ ────────────────────────────────────────────
  testWidgets('KB-8: ゴールタブに「最終目標」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteGoalsTab(
          goals: const KarteGoals(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('最終目標'), findsOneWidget);
  });

  testWidgets('KB-9: ゴールタブに「1ヶ月目標」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteGoalsTab(
          goals: const KarteGoals(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('1ヶ月目標'), findsOneWidget);
  });

  testWidgets('KB-10: ゴールタブに既存データが表示される', (tester) async {
    const goals = KarteGoals(finalGoal: '体重 -10kg を達成する');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteGoalsTab(
          goals: goals,
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('体重 -10kg を達成する'), findsOneWidget);
  });

  // ── KB: トレーナーメモタブ ────────────────────────────────────
  testWidgets('KB-11: トレーナーメモタブに「現在の課題」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteTrainerMemoTab(
          memo: const KartePrivate(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('現在の課題'), findsOneWidget);
  });

  testWidgets('KB-12: トレーナーメモタブに「声かけ方」フィールドが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteTrainerMemoTab(
          memo: const KartePrivate(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('声かけ方'), findsOneWidget);
  });

  testWidgets('KB-13: トレーナーメモタブに専用バナーが表示される', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KarteTrainerMemoTab(
          memo: const KartePrivate(),
          onSave: (_) async {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('このタブはトレーナーのみ閲覧できます'), findsOneWidget);
  });
}
