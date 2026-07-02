import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings();
  final testDate = DateTime(2024, 7, 1);

  // WeightInputSheet を底部シートとして開くヘルパー
  Widget buildWithSheet({
    required Future<void> Function(WeightLogEntry) onSave,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => WeightInputSheet(date: testDate, onSave: onSave),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  // HomeScreen に体重1件（id あり）を渡すヘルパー
  // recentWeightLogs を空にして _WeightChart の fl_chart レンダリングを回避
  Widget buildHomeWithWeight({
    required Future<void> Function(String id) onDeleteWeight,
    String memo = '',
  }) {
    final weight = WeightLogEntry(
      id: 'weight-1',
      weight: 60.0,
      memo: memo,
      loggedAt: DateTime(2024, 7, 1, 9, 0),
      date: DateTime(2024, 7, 1),
    );
    return MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          loading: false,
          goals: goals,
          mealLogs: const [],
          exerciseLogs: const [],
          weightLogs: [weight],
          recentWeightLogs: const [],
          onRefresh: () async {},
          onDeleteMeal: (_) async {},
          onDeleteExercise: (_) async {},
          onDeleteWeight: onDeleteWeight,
          selectedDate: DateTime(2024, 7, 1),
          onPrevDay: () {},
          onNextDay: () {},
        ),
      ),
    );
  }

  // ── WeightInputSheet UI ─────────────────────────────────────

  testWidgets('W-1: 「体重を記録」タイトルが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('体重を記録'), findsOneWidget);
  });

  testWidgets('W-2: 体重 (kg) フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('体重 (kg)'), findsOneWidget);
  });

  testWidgets('W-3: メモ（任意）フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('メモ（任意）'), findsOneWidget);
  });

  testWidgets('W-4: 「保存する」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('保存する'), findsOneWidget);
  });

  testWidgets('W-5: 空で送信すると体重バリデーションエラーが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pump();
    expect(find.text('体重を入力してください'), findsOneWidget);
  });

  testWidgets('W-6: 体重を入力して保存すると onSave が呼ばれる', (tester) async {
    WeightLogEntry? saved;
    await tester.pumpWidget(buildWithSheet(onSave: (e) async { saved = e; }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '65.5');
    await tester.enterText(find.byType(TextFormField).at(1), '朝食後');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.weight, 65.5);
    expect(saved!.memo, '朝食後');
  });

  // ── 体重カード表示 ─────────────────────────────────────────
  // 体重セクションは食事・運動セクションより下に描画される。
  // ListView の遅延ビルドにより、デフォルト 600px では体重カードが未描画になるため
  // W-7 以降はすべて setSurfaceSize で縦幅を拡張する。

  testWidgets('W-7: 体重カードに体重（60.0 kg）が表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildHomeWithWeight(onDeleteWeight: (_) async {}),
    );
    await tester.pump();
    expect(find.text('60.0 kg'), findsWidgets);
  });

  testWidgets('W-8: 体重カードにメモが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildHomeWithWeight(onDeleteWeight: (_) async {}, memo: '朝イチ'),
    );
    await tester.pump();
    expect(find.text('朝イチ'), findsOneWidget);
  });

  // ── 体重削除フロー ─────────────────────────────────────────

  testWidgets('W-9: 体重カードに削除アイコンが表示される（id あり）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildHomeWithWeight(onDeleteWeight: (_) async {}),
    );
    await tester.pump();
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('W-10: 削除アイコンをタップすると確認ダイアログが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildHomeWithWeight(onDeleteWeight: (_) async {}),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('体重を削除'), findsOneWidget);
    expect(find.text('60.0 kg の記録を削除しますか？'), findsOneWidget);
  });

  testWidgets('W-11: ダイアログの「削除」をタップすると onDeleteWeight が呼ばれる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? deletedId;
    await tester.pumpWidget(
      buildHomeWithWeight(onDeleteWeight: (id) async { deletedId = id; }),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(deletedId, 'weight-1');
  });
}
