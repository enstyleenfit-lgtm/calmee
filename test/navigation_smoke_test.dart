import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

// テスト専用シェル（本番RootShellはFirebase依存のため使わない）
// 注意：本番RootShellのNavBarラベル順・FAB条件と構造を合わせること
class _TestShell extends StatefulWidget {
  const _TestShell();
  @override
  State<_TestShell> createState() => _TestShellState();
}

class _TestShellState extends State<_TestShell> {
  int _index = 0;
  static const _goals = GoalSettings();

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        loading: false,
        goals: _goals,
        mealLogs: const [],
        exerciseLogs: const [],
        weightLogs: const [],
        recentWeightLogs: const [],
        onRefresh: () async {},
        onDeleteMeal: (_) async {},
        onDeleteExercise: (_) async {},
        onDeleteWeight: (_) async {},
        selectedDate: DateTime(2024, 7, 1),
        onPrevDay: () {},
        onNextDay: () {},
      ),
      const SizedBox(), // 進捗（スコープ外）
      const SizedBox(), // 記録（スコープ外）
      SettingsScreen(
        goals: _goals,
        onSave: (_) async {},
      ),
    ];

    return Scaffold(
      body: screens[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.restaurant_outlined),
                        title: const Text('食事を記録'),
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: '進捗'),
          NavigationDestination(icon: Icon(Icons.edit_outlined), label: '記録'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}

void main() {
  Widget buildShell() => const MaterialApp(home: _TestShell());

  // N-1 と N-4: SettingsScreen の labelText は '目標カロリー'（suffixText 'kcal' は別Widget）
  testWidgets('N-1: 設定タブに切り替えできる', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    // 設定画面固有のUIが表示されることを確認
    expect(find.text('目標カロリー'), findsOneWidget);
  });

  testWidgets('N-2: ホームタブでFABが存在する', (tester) async {
    await tester.pumpWidget(buildShell());
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('N-3: FABタップ後「食事を記録」が出現する', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('食事を記録'), findsOneWidget);
  });

  testWidgets('N-4: 設定タブに目標カロリーフィールドが存在する', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('目標カロリー'), findsOneWidget);
  });

  testWidgets('N-5: 設定タブに保存ボタンが存在する', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('保存する'), findsOneWidget);
  });

  testWidgets('N-6: 設定タブからホームに戻ると「からだ収支」が再表示される', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('からだ収支'), findsOneWidget);
  });
}
