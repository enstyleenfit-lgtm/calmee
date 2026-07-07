import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  Widget buildDialog() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showDialog<String>(
              context: ctx,
              builder: (_) => const AddCustomerDialog(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // ── AC: 顧客追加ダイアログ ─────────────────────────────────────
  testWidgets('AC-1: ダイアログに「顧客のUID」フィールドが表示される', (tester) async {
    await openDialog(tester);
    expect(find.text('顧客のUID'), findsOneWidget);
  });

  testWidgets('AC-2: 表示名フィールドは表示されない（UID のみ）', (tester) async {
    await openDialog(tester);
    expect(find.text('表示名'), findsNothing);
  });

  testWidgets('AC-3: 空のまま「追加」を押すとバリデーションエラーが出る', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('追加'));
    await tester.pump();
    expect(find.text('UIDを入力してください'), findsOneWidget);
  });

  testWidgets('AC-4: UID入力後「追加」を押すとダイアログが閉じる', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), 'test-uid-123');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.text('顧客を追加'), findsNothing);
  });

  testWidgets('AC-5: 前後スペース付きUIDでも trim されて登録できる', (tester) async {
    String? returned;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              returned = await showDialog<String>(
                context: ctx,
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
    await tester.enterText(find.byType(TextFormField), '  spaced-uid  ');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(returned, 'spaced-uid');
  });

  testWidgets('AC-6: スペースのみのUIDはバリデーションエラーになる', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('追加'));
    await tester.pump();
    expect(find.text('UIDを入力してください'), findsOneWidget);
  });

  testWidgets('AC-7: 「キャンセル」を押すとダイアログが閉じる', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('顧客を追加'), findsNothing);
  });

  testWidgets('AC-8: ダイアログに「追加」「キャンセル」ボタンが両方表示される', (tester) async {
    await openDialog(tester);
    expect(find.text('追加'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
  });

  testWidgets('AC-9: ヒントテキストに「貼り付け、または入力してください」が含まれる', (tester) async {
    await openDialog(tester);
    expect(find.text('顧客IDを貼り付け、または入力してください'), findsOneWidget);
  });

  testWidgets('AC-10: ペーストボタン（クリップボード専用ボタン）は表示されない', (tester) async {
    // Ctrl+V / 右クリック貼り付け前提のため、専用ペーストボタンは不要
    await openDialog(tester);
    expect(find.byIcon(Icons.content_paste), findsNothing);
    expect(find.byIcon(Icons.content_paste_outlined), findsNothing);
  });

  testWidgets('AC-11: 手入力したUIDで正常に追加できる（UID文字列が返る）', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<String>(
                context: ctx,
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
    await tester.enterText(find.byType(TextFormField), 'manual-uid-xyz');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(result, 'manual-uid-xyz');
  });
}
