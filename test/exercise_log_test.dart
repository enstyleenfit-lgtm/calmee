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
    // 手入力時は重量欄が非表示のため kcal が at(1)
    await tester.enterText(find.byType(TextFormField).at(1), '300');
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

    // 重量(1)・回数(2)・セット数(3)が追加されたため kcal は index 4
    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(4))
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

    // 重量(1)入力 → calcEstimatedKcal(60kg)=180 × (10/10) × (3/3) = 180
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.pump();

    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(4))
        .controller;
    expect(kcalCtrl?.text, '180');
  });

  testWidgets('E-15: 手入力のみの状態では重量欄が表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 候補を選ばず手入力
    await tester.enterText(find.byType(TextFormField).at(0), 'アームカール');
    await tester.pump();

    expect(find.text('重量 kg'), findsNothing);
  });

  testWidgets('E-16: 有酸素候補選択後に重量欄が非表示になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // スクワット選択 → 重量欄表示
    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();
    expect(find.text('重量 kg'), findsOneWidget);

    // ランニング選択 → 重量欄が消える
    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();
    expect(find.text('重量 kg'), findsNothing);
  });

  testWidgets('E-14: ランニング選択後は重量入力欄が表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    expect(find.text('重量 kg'), findsNothing);
  });

  testWidgets('E-17: 画面初期表示では重量欄が表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('重量 kg'), findsNothing);
  });

  testWidgets('E-18: ランニング選択時にkcalが240になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    // 有酸素選択後は重量欄が非表示、分テキスト欄(1)が追加されたため kcal は at(2)
    expect(find.text('重量 kg'), findsNothing);
    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(kcalCtrl?.text, '240');
  });

  // ── EC: 有酸素入力UI ───────────────────────────────────────────

  testWidgets('EC-1: 有酸素候補選択後に時間ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, '30分'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '60分'), findsOneWidget);
    expect(find.text('時間'), findsOneWidget);
  });

  testWidgets('EC-2: 有酸素候補選択後に強度ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, '軽め'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '普通'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '早め'), findsOneWidget);
    expect(find.text('強度'), findsOneWidget);
  });

  testWidgets('EC-3: 有酸素候補では重量・回数・セット数が表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    expect(find.text('重量 kg'), findsNothing);
    expect(find.text('回数'), findsNothing);
    expect(find.text('セット数'), findsNothing);
  });

  testWidgets('EC-4: 筋トレ候補では時間・強度UIが表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    expect(find.text('時間'), findsNothing);
    expect(find.text('強度'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '30分'), findsNothing);
  });

  testWidgets('EC-5: 「60分」ボタンでランニングのkcalが480になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '60分'));
    await tester.pump();

    // name(0), 分テキスト(1), kcal(2)
    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(kcalCtrl?.text, '480');
  });

  testWidgets('EC-6: 「早め」ボタンでランニング30分のkcalが288になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '早め'));
    await tester.pump();

    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(kcalCtrl?.text, '288');
  });

  testWidgets('EC-7: 「軽め」ボタンでランニング30分のkcalが192になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '軽め'));
    await tester.pump();

    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(kcalCtrl?.text, '192');
  });

  testWidgets('EC-8: ランニング選択後の保存で durationMinutes=30, intensity=normal が渡る',
      (tester) async {
    ExerciseLogEntry? saved;
    await tester.pumpWidget(buildWithSheet(onSave: (e) async { saved = e; }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.durationMinutes, 30);
    expect(saved!.intensity, 'normal');
  });

  testWidgets('EC-9: 手入力時は durationMinutes・intensity が null', (tester) async {
    ExerciseLogEntry? saved;
    await tester.pumpWidget(buildWithSheet(onSave: (e) async { saved = e; }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ランニング');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '300');
    await tester.pump();

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.durationMinutes, isNull);
    expect(saved!.intensity, isNull);
  });

  // ── 重量・回数・セット数テスト ────────────────────────────────

  testWidgets('EA-1: 初期表示では重量・回数・セット数が表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('重量 kg'), findsNothing);
    expect(find.text('回数'),    findsNothing);
    expect(find.text('セット数'), findsNothing);
  });

  testWidgets('EA-2: スクワット選択後に重量・回数・セット数が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    expect(find.text('重量 kg'), findsOneWidget);
    expect(find.text('回数'),    findsOneWidget);
    // 'セット数' はラベルとフィールドラベルの2箇所に表示される
    expect(find.text('セット数'), findsWidgets);
  });

  testWidgets('EA-3: スクワット選択時に回数10・セット数3が初期入力される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    // name(0), 重量(1), 回数(2), セット数(3), kcal(4), メモ(5)
    final repsCtrl = tester.widget<TextFormField>(find.byType(TextFormField).at(2)).controller;
    final setsCtrl = tester.widget<TextFormField>(find.byType(TextFormField).at(3)).controller;
    expect(repsCtrl?.text, '10');
    expect(setsCtrl?.text, '3');
  });

  testWidgets('EA-4: セット数ボタン 1〜5 が表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, '1'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '3'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '5'), findsOneWidget);
  });

  testWidgets('EA-5: セット数ボタン5をタップするとセット数フィールドが5になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, '5'));
    await tester.pump();

    final setsCtrl = tester.widget<TextFormField>(find.byType(TextFormField).at(3)).controller;
    expect(setsCtrl?.text, '5');
  });

  testWidgets('EA-6: スクワット 重量60kg・10回・3セットで kcal が 180 になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    // 重量60kg: calcEstimatedKcal(150, 60kg) = 180
    // reps=10, sets=3 → factor = (10/10)×(3/3) = 1
    // estimatedKcal = 180
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.pump();

    final kcalCtrl = tester.widget<TextFormField>(find.byType(TextFormField).at(4)).controller;
    expect(kcalCtrl?.text, '180');
  });

  testWidgets('EA-7: スクワット 重量60kg・10回・5セットで kcal が 180 より増える', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'スク');
    await tester.pump();
    await tester.tap(find.text('スクワット'));
    await tester.pump();

    // セット数5に変更してから重量入力
    // 180 × (10/10) × (5/3) = 300
    await tester.tap(find.widgetWithText(OutlinedButton, '5'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.pump();

    final kcalCtrl = tester.widget<TextFormField>(find.byType(TextFormField).at(4)).controller;
    expect(int.parse(kcalCtrl!.text), greaterThan(180));
  });

  testWidgets('EA-8: ランニング選択時は重量・回数・セット数が表示されない', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ラン');
    await tester.pump();
    await tester.tap(find.text('ランニング'));
    await tester.pump();

    expect(find.text('重量 kg'), findsNothing);
    expect(find.text('回数'),    findsNothing);
    expect(find.text('セット数'), findsNothing);
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
