import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings();
  final testDate = DateTime(2024, 7, 1);

  // ExerciseInputSheet を底部シートとして開くヘルパー
  Widget buildWithSheet({
    required Future<void> Function(ExerciseLogEntry) onSave,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ExerciseInputSheet(date: testDate, onSave: onSave),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  // HomeScreen に運動1件（id あり）を渡すヘルパー
  Widget buildHomeWithExercise({
    required Future<void> Function(String id) onDeleteExercise,
  }) {
    final exercise = ExerciseLogEntry(
      id: 'ex-1',
      name: 'ウォーキング',
      kcal: 200,
      category: 'self',
      loggedAt: DateTime(2024, 7, 1, 9, 0),
      date: DateTime(2024, 7, 1),
    );
    return MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          loading: false,
          goals: goals,
          mealLogs: const [],
          exerciseLogs: [exercise],
          weightLogs: const [],
          recentWeightLogs: const [],
          onRefresh: () async {},
          onDeleteMeal: (_) async {},
          onDeleteExercise: onDeleteExercise,
          onDeleteWeight: (_) async {},
          selectedDate: DateTime(2024, 7, 1),
          onPrevDay: () {},
          onNextDay: () {},
        ),
      ),
    );
  }

  // ── ExerciseInputSheet UI ─────────────────────────────────────

  testWidgets('E-1: 「運動を記録」タイトルが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('運動を記録'), findsOneWidget);
  });

  testWidgets('E-2: 運動名フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('運動名（例：ウォーキング、筋トレ）'), findsOneWidget);
  });

  testWidgets('E-3: 消費カロリーフィールドが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('推定消費カロリー (kcal)'), findsOneWidget);
  });

  testWidgets('E-4: 「保存する」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('保存する'), findsOneWidget);
  });

  testWidgets('E-5: 種別チップ（自主運動 / トレーナー）が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('自主運動'), findsOneWidget);
    expect(find.text('トレーナー'), findsOneWidget);
  });

  testWidgets('E-6: 空で送信すると運動名バリデーションエラーが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pump();
    expect(find.text('運動名を入力してください'), findsOneWidget);
  });

  testWidgets('E-7: 運動名と消費カロリーを入力して保存すると onSave が呼ばれる', (tester) async {
    ExerciseLogEntry? saved;
    await tester.pumpWidget(buildWithSheet(onSave: (e) async { saved = e; }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ランニング');
    // 手入力時は重量欄が at(1)、kcal が at(2)
    await tester.enterText(find.byType(TextFormField).at(2), '300');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'ランニング');
    expect(saved!.kcal, 300);
  });

  // ── 重量補正テスト ─────────────────────────────────────────

  testWidgets('E-11: スクワット選択後に重量入力欄が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    expect(find.text('重量 kg'), findsOneWidget);
  });

  testWidgets('E-12: スクワット選択時に推定消費kcalに 150 が入る', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    // 重量フィールドが index 1、kcal が index 2
    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(kcalCtrl?.text, '150');
  });

  testWidgets('E-13: スクワットで重量 60kg 入力すると kcal が 180 に補正される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    // 重量入力 (index 1) → kcal が 150 × 1.2 = 180 に補正
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.pump();

    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(kcalCtrl?.text, '180');
  });

  testWidgets('E-15: 手入力の筋トレ名では重量欄が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 候補を選ばず手入力（アームカールはリストにないので候補なし）
    await tester.enterText(find.byType(TextFormField).at(0), 'アームカール');
    await tester.pump();

    expect(find.text('重量 kg'), findsOneWidget);
  });

  testWidgets('E-16: 有酸素候補選択後も重量欄が表示されたまま', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // スクワット選択 → 重量欄表示
    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();
    expect(find.text('重量 kg'), findsOneWidget);

    // ランニング選択 → 重量欄は表示されたまま
    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();
    expect(find.text('重量 kg'), findsOneWidget);
  });

  testWidgets('E-14: ランニング選択後も重量入力欄が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    expect(find.text('重量 kg'), findsOneWidget);
  });

  testWidgets('E-17: 画面初期表示で重量欄が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('重量 kg'), findsOneWidget);
  });

  testWidgets('E-18: ランニング選択時に重量を入力してもkcalが変わらない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    // ランニングの referenceKcal = 240 が入っていることを確認 (weight at(1), kcal at(2))
    final kcalBefore = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller?.text;
    expect(kcalBefore, '240');

    // 重量入力してもkcalは変わらない（有酸素は補正なし）
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.pump();

    final kcalAfter = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller?.text;
    expect(kcalAfter, '240');
  });

  // ── 運動削除フロー ─────────────────────────────────────────

  testWidgets('E-8: 運動カードに削除アイコンが表示される（id あり）', (tester) async {
    await tester.pumpWidget(buildHomeWithExercise(onDeleteExercise: (_) async {}));
    await tester.pump();
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  // E-9/E-10: 運動セクションが食事セクションより下に描画されるため、
  // デフォルト 600px では削除アイコンが画面外になる。縦幅を拡張して対応。
  testWidgets('E-9: 削除アイコンをタップすると確認ダイアログが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildHomeWithExercise(onDeleteExercise: (_) async {}));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('運動を削除'), findsOneWidget);
    expect(find.text('「ウォーキング」を削除しますか？'), findsOneWidget);
  });

  testWidgets('E-10: ダイアログの「削除」をタップすると onDeleteExercise が呼ばれる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? deletedId;
    await tester.pumpWidget(buildHomeWithExercise(
      onDeleteExercise: (id) async { deletedId = id; },
    ));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(deletedId, 'ex-1');
  });
}
