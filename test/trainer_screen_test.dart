import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

// TrainerHomeScreen は initState でFirebaseを直接呼びcatchがないため
// widget testでは使えない。navigation_smoke_test.dartと同じアプローチで
// テスト専用シェルを作り、AddCustomerDialog / TrainerCustomerDetailScreen
// の実クラスをそこから呼び出す。
class _TestTrainerShell extends StatelessWidget {
  const _TestTrainerShell({required this.customers});
  final List<CustomerLink> customers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('トレーナーホーム')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<({String uid, String name})>(
          context: context,
          builder: (_) => const AddCustomerDialog(),
        ),
        child: const Icon(Icons.person_add_outlined),
      ),
      body: customers.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('担当顧客がいません'),
                  SizedBox(height: 8),
                  Text('右下の＋ボタンから顧客を追加してください'),
                ],
              ),
            )
          : ListView(
              children: customers
                  .map((c) => ListTile(
                        title: Text(c.displayName),
                        subtitle: Text('UID: ${c.customerUid}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainerCustomerDetailScreen(
                              customer: c,
                              trainerUid: 'test-trainer',
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

void main() {
  final customer1 = CustomerLink(
    customerUid: 'uid-alice-001',
    displayName: '田中様',
    linkedAt: DateTime(2024, 7, 1),
  );

  Widget buildShell({List<CustomerLink> customers = const []}) {
    return MaterialApp(home: _TestTrainerShell(customers: customers));
  }

  // ── 空状態 ────────────────────────────────────────────────

  testWidgets('T-1: 顧客がいない場合「担当顧客がいません」が表示される', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.pump();
    expect(find.text('担当顧客がいません'), findsOneWidget);
    expect(find.text('右下の＋ボタンから顧客を追加してください'), findsOneWidget);
  });

  // ── 顧客一覧 ──────────────────────────────────────────────

  testWidgets('T-2: 顧客がいる場合は表示名が表示される', (tester) async {
    await tester.pumpWidget(buildShell(customers: [customer1]));
    await tester.pump();
    expect(find.text('田中様'), findsOneWidget);
  });

  // ── AddCustomerDialog ─────────────────────────────────────

  testWidgets('T-3: FABをタップすると「顧客を追加」ダイアログが開く', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.byIcon(Icons.person_add_outlined));
    await tester.pumpAndSettle();
    expect(find.text('顧客を追加'), findsOneWidget);
  });

  testWidgets('T-4: ダイアログに UID フィールドと表示名フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.byIcon(Icons.person_add_outlined));
    await tester.pumpAndSettle();
    expect(find.text('顧客のUID'), findsOneWidget);
    expect(find.text('表示名'), findsOneWidget);
  });

  testWidgets('T-5: 空で追加するとバリデーションエラーが表示される', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.tap(find.byIcon(Icons.person_add_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('追加'));
    await tester.pump();
    expect(find.text('UIDを入力してください'), findsOneWidget);
  });

  testWidgets('T-6: UID と表示名を入力して追加すると値が返る', (tester) async {
    ({String uid, String name})? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<({String uid, String name})>(
                context: context,
                builder: (_) => const AddCustomerDialog(),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'uid-alice-001');
    await tester.enterText(find.byType(TextFormField).at(1), '田中様');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(result?.uid, 'uid-alice-001');
    expect(result?.name, '田中様');
  });

  // ── 顧客詳細遷移 ──────────────────────────────────────────
  // TrainerCustomerDetailScreen は initState で Firebase を呼ぶが
  // try/catch があるため、Firebase 未初期化でもエラー状態で表示される。
  // AppBar の顧客名は常に表示されるため、それを検証する。

  testWidgets('T-7: 顧客カードをタップすると詳細画面の AppBar に顧客名が表示される',
      (tester) async {
    await tester.pumpWidget(buildShell(customers: [customer1]));
    await tester.pump();
    await tester.tap(find.text('田中様'));
    await tester.pumpAndSettle();
    // AppBar タイトルに顧客名が表示される
    expect(find.text('田中様'), findsOneWidget);
  });
}
