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
}
