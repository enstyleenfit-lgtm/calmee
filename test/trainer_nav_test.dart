import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

// TrainerReservationPlaceholder, TrainerPostPlaceholder, TrainerSelfScreen は
// 純粋 StatelessWidget のため Firebase 未初期化でもテスト可能。

void main() {
  // ── TN: Trainer Navigation Tab Widgets ────────────────────────────────────

  // ── 予約タブ ──────────────────────────────────────────────────────────────

  testWidgets('TN-1: 予約タブに「予約管理」が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrainerReservationPlaceholder())),
    );
    await tester.pump();
    expect(find.text('予約管理'), findsOneWidget);
  });

  testWidgets('TN-2: 予約タブにセッション予定の説明文が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrainerReservationPlaceholder())),
    );
    await tester.pump();
    expect(find.textContaining('セッション予定'), findsOneWidget);
  });

  testWidgets('TN-3: 予約タブに「Coming soon」ラベルが表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrainerReservationPlaceholder())),
    );
    await tester.pump();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  // ── 投稿タブ ──────────────────────────────────────────────────────────────

  testWidgets('TN-4: 投稿タブに「投稿」が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrainerPostPlaceholder())),
    );
    await tester.pump();
    expect(find.text('投稿'), findsOneWidget);
  });

  testWidgets('TN-5: 投稿タブに配信の説明文が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrainerPostPlaceholder())),
    );
    await tester.pump();
    expect(find.textContaining('配信'), findsOneWidget);
  });

  testWidgets('TN-6: 投稿タブに「Coming soon」ラベルが表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrainerPostPlaceholder())),
    );
    await tester.pump();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  // ── 自分タブ ──────────────────────────────────────────────────────────────

  testWidgets('TN-7: onSwitchToCustomer が渡されると「お客さんモードに切り替える」が表示される',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerSelfScreen(
            onSwitchToCustomer: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('お客さんモードに切り替える'), findsOneWidget);
  });

  testWidgets('TN-8: onReturnToTop が渡されると「デモ用：トップ画面に戻る」が表示される',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerSelfScreen(
            onReturnToTop: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('デモ用：トップ画面に戻る'), findsOneWidget);
  });

  testWidgets('TN-9: onReturnToTop が null のとき「デモ用：トップ画面に戻る」が表示されない',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrainerSelfScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('デモ用：トップ画面に戻る'), findsNothing);
  });

  testWidgets('TN-10: onSwitchToCustomer が null のとき「お客さんモードに切り替える」が表示されない',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrainerSelfScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('お客さんモードに切り替える'), findsNothing);
  });

  testWidgets('TN-11: onSwitchToCustomer タップでコールバックが呼ばれる', (tester) async {
    bool called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerSelfScreen(
            onSwitchToCustomer: () { called = true; },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('お客さんモードに切り替える'));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('TN-12: onReturnToTop タップでコールバックが呼ばれる', (tester) async {
    bool called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerSelfScreen(
            onReturnToTop: () { called = true; },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('デモ用：トップ画面に戻る'));
    await tester.pump();
    expect(called, isTrue);
  });
}
