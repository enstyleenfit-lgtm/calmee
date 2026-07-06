import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings();
  final testDate = DateTime(2024, 7, 1);

  // MealInputSheet を底部シートとして開くヘルパー
  Widget buildWithSheet({required Future<void> Function(MealLogEntry) onSave}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => MealInputSheet(date: testDate, onSave: onSave),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  // HomeScreen に食事1件（id あり）を渡すヘルパー
  Widget buildHomeWithMeal({
    required Future<void> Function(String id) onDeleteMeal,
  }) {
    final meal = MealLogEntry(
      id: 'meal-1',
      name: 'テストランチ',
      kcal: 600,
      protein: 30.0,
      fat: 15.0,
      carb: 80.0,
      loggedAt: DateTime(2024, 7, 1, 12, 0),
      date: DateTime(2024, 7, 1),
    );
    return MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          loading: false,
          goals: goals,
          mealLogs: [meal],
          exerciseLogs: const [],
          weightLogs: const [],
          recentWeightLogs: const [],
          onRefresh: () async {},
          onDeleteMeal: onDeleteMeal,
          onDeleteExercise: (_) async {},
          onDeleteWeight: (_) async {},
          selectedDate: DateTime(2024, 7, 1),
          onPrevDay: () {},
          onNextDay: () {},
        ),
      ),
    );
  }

  // ── MealInputSheet UI ─────────────────────────────────────────

  testWidgets('M-1: 「食事を記録」タイトルが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('食事を記録'), findsOneWidget);
  });

  testWidgets('M-2: 食事名フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('食事名（例：朝食、ランチ）'), findsOneWidget);
  });

  testWidgets('M-3: カロリーフィールドが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('カロリー (kcal)※参考値'), findsOneWidget);
  });

  testWidgets('M-4: 「保存する」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('保存する'), findsOneWidget);
  });

  testWidgets('M-5: 空で送信すると食事名バリデーションエラーが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pump();
    expect(find.text('食事名を入力してください'), findsOneWidget);
  });

  testWidgets('M-6: 食事名とカロリーを入力して保存すると onSave が呼ばれる', (tester) async {
    MealLogEntry? saved;
    await tester.pumpWidget(buildWithSheet(onSave: (e) async { saved = e; }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ランチ');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'ランチ');
    expect(saved!.kcal, 500);
  });

  // ── 食事削除フロー ─────────────────────────────────────────

  testWidgets('M-7: 食事カードに削除アイコンが表示される（id あり）', (tester) async {
    await tester.pumpWidget(buildHomeWithMeal(onDeleteMeal: (_) async {}));
    await tester.pump();
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('M-8: 削除アイコンをタップすると確認ダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildHomeWithMeal(onDeleteMeal: (_) async {}));
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('食事を削除'), findsOneWidget);
    expect(find.text('「テストランチ」を削除しますか？'), findsOneWidget);
  });

  testWidgets('M-9: ダイアログの「削除」をタップすると onDeleteMeal が呼ばれる', (tester) async {
    String? deletedId;
    await tester.pumpWidget(buildHomeWithMeal(onDeleteMeal: (id) async { deletedId = id; }));
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(deletedId, 'meal-1');
  });

  // ── 量ボタンテスト ────────────────────────────────────────────

  testWidgets('MA-1: 白米候補を選択すると量ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // かな検索 'しろ' → 候補に '白米' が表示される（EditableText='しろ' ≠ Text='白米'）
    await tester.enterText(find.byType(TextFormField).at(0), 'しろ');
    await tester.pump();
    await tester.tap(find.text('白米'));
    await tester.pump();

    expect(find.text('100g'), findsOneWidget);
    expect(find.text('200g'), findsOneWidget);
  });

  testWidgets('MA-2: 白米 200g ボタンをタップすると kcal が 336 になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'しろ');
    await tester.pump();
    await tester.tap(find.text('白米'));
    await tester.pump();

    await tester.tap(find.text('200g'));
    await tester.pump();

    // 量ボタンは OutlinedButton（TextFormField ではない）なのでインデックスは不変
    // name(0), kcal(1), protein(2), fat(3), carb(4)
    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(1))
        .controller;
    expect(kcalCtrl?.text, '336'); // 168 × (200/100) = 336
  });

  testWidgets('MA-3: 白米 200g ボタンをタップすると protein が 5.0 になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'しろ');
    await tester.pump();
    await tester.tap(find.text('白米'));
    await tester.pump();

    await tester.tap(find.text('200g'));
    await tester.pump();

    final proteinCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(2))
        .controller;
    expect(proteinCtrl?.text, '5.0'); // 2.5 × (200/100) = 5.0
  });

  testWidgets('MA-4: 卵 2個 ボタンをタップすると kcal が 182 になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // かな検索 'たまご' → 候補に '卵' が表示される（EditableText='たまご' ≠ Text='卵'）
    await tester.enterText(find.byType(TextFormField).at(0), 'たまご');
    await tester.pump();
    await tester.tap(find.text('卵'));
    await tester.pump();

    await tester.tap(find.text('2個'));
    await tester.pump();

    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(1))
        .controller;
    expect(kcalCtrl?.text, '182'); // 91 × (2/1) = 182
  });

  testWidgets('MA-5: 鶏むね肉 150g ボタンをタップすると kcal が 162 になる', (tester) async {
    await tester.pumpWidget(buildWithSheet(onSave: (_) async {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // かな検索 'とり' → 候補に '鶏むね肉' が表示される（EditableText='とり' ≠ Text='鶏むね肉'）
    await tester.enterText(find.byType(TextFormField).at(0), 'とり');
    await tester.pump();
    await tester.tap(find.text('鶏むね肉'));
    await tester.pump();

    await tester.tap(find.text('150g'));
    await tester.pump();

    final kcalCtrl = tester
        .widget<TextFormField>(find.byType(TextFormField).at(1))
        .controller;
    expect(kcalCtrl?.text, '162'); // (108 × 1.5).round() = 162
  });
}
