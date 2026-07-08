import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  // CalendarScreen は Firebase リポジトリを initState で作成するが、
  // 実際の Firestore 呼び出しは catch (_) で吸収されるため、
  // Firebase 未初期化の test 環境でも UI テストが成立する。
  // initialDate を渡して月・日付を固定する。

  Widget buildScreen({DateTime? initialDate}) => MaterialApp(
        home: CalendarScreen(
          customerUid: 'test_uid',
          initialDate: initialDate ?? DateTime(2026, 7, 8),
        ),
      );

  // ── CL: CalendarScreen ─────────────────────────────────────────────────────

  testWidgets('CL-1: AppBar タイトル「カレンダー」が表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('カレンダー'), findsWidgets);
  });

  testWidgets('CL-2: 表示月のラベルが正しく表示される', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pump();
    expect(find.text('2026年7月'), findsOneWidget);
  });

  testWidgets('CL-3: 前月ナビボタン（左矢印）が存在する', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });

  testWidgets('CL-4: 次月ナビボタン（右矢印）が存在する', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('CL-5: 前月ボタンをタップすると月が変わる', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pump();
    expect(find.text('2026年7月'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('2026年6月'), findsOneWidget);
    expect(find.text('2026年7月'), findsNothing);
  });

  testWidgets('CL-6: 次月ボタンをタップすると月が変わる', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pump();
    expect(find.text('2026年7月'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('2026年8月'), findsOneWidget);
  });

  testWidgets('CL-7: 曜日ラベル（月〜日）が7個表示される', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    for (final label in ['月', '火', '水', '木', '金', '土', '日']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('CL-8: 当月の 1日と月末日のセルが表示される', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pump();
    expect(find.text('1'), findsWidgets); // 1日
    expect(find.text('31'), findsWidgets); // 7月は31日まで
  });

  testWidgets('CL-9: 記録がないとき「この日の記録はありません」が表示される', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pumpAndSettle();
    expect(find.text('この日の記録はありません'), findsOneWidget);
  });

  testWidgets('CL-10: 日付タップ後に詳細エリアの日付表示が更新される', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pumpAndSettle();

    // 初期選択日は 7月8日
    expect(find.textContaining('7月8日'), findsOneWidget);

    // 15日をタップ
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('7月15日'), findsOneWidget);
  });

  testWidgets('CL-11: 前月→次月と移動すると元の月に戻る', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('2026年6月'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('2026年7月'), findsOneWidget);
  });

  testWidgets('CL-12: 詳細エリアに初期選択日の日付（年月日）が表示される', (tester) async {
    await tester.pumpWidget(buildScreen(initialDate: DateTime(2026, 7, 8)));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026年7月8日'), findsOneWidget);
  });
}
