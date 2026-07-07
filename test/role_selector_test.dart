import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  Widget buildScreen({Future<void> Function(String)? onSelect}) {
    return MaterialApp(
      home: RoleSelectorScreen(
        onSelect: onSelect ?? (_) async {},
      ),
    );
  }

  // ── RS: 利用モード選択画面 ─────────────────────────────────────
  testWidgets('RS-1: ウェルカムメッセージが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('からだ収支へようこそ'), findsOneWidget);
  });

  testWidgets('RS-2: 利用方法選択の説明文が表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('利用方法を選択してください'), findsOneWidget);
  });

  testWidgets('RS-3: 「お客さんとして使う」カードが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('お客さんとして使う'), findsOneWidget);
  });

  testWidgets('RS-4: 「トレーナーとして使う」カードが表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('トレーナーとして使う'), findsOneWidget);
  });

  testWidgets('RS-5: 顧客カードの説明文が表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('食事・運動・体重を記録します'), findsOneWidget);
  });

  testWidgets('RS-6: トレーナーカードの説明文が表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('担当顧客の記録・ノート・カルテを確認します'), findsOneWidget);
  });

  testWidgets('RS-7: 「お客さんとして使う」をタップすると customer が渡される', (tester) async {
    String? selected;
    await tester.pumpWidget(buildScreen(onSelect: (role) async {
      selected = role;
    }));
    await tester.pump();
    await tester.tap(find.text('お客さんとして使う'));
    await tester.pump();
    expect(selected, 'customer');
  });

  testWidgets('RS-8: 「トレーナーとして使う」をタップすると trainer が渡される', (tester) async {
    String? selected;
    await tester.pumpWidget(buildScreen(onSelect: (role) async {
      selected = role;
    }));
    await tester.pump();
    await tester.tap(find.text('トレーナーとして使う'));
    await tester.pump();
    expect(selected, 'trainer');
  });
}
