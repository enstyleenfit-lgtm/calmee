import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  Widget buildSettings({Future<void> Function(String)? onRoleChange}) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsScreen(
          goals: const GoalSettings(),
          onSave: (_) async {},
          role: 'customer',
          onRoleChange: onRoleChange,
        ),
      ),
    );
  }

  // ── DR: デモ用トップ戻るボタン ─────────────────────────────────
  testWidgets('DR-1: 「デモ用：トップ画面に戻る」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildSettings(onRoleChange: (_) async {}));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('デモ用：トップ画面に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('デモ用：トップ画面に戻る'), findsOneWidget);
  });

  testWidgets('DR-2: 補足文「利用モード選択画面に戻ります」が表示される', (tester) async {
    await tester.pumpWidget(buildSettings(onRoleChange: (_) async {}));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('利用モード選択画面に戻ります'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('利用モード選択画面に戻ります'), findsOneWidget);
  });

  testWidgets('DR-3: ボタンタップで確認ダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildSettings(onRoleChange: (_) async {}));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('デモ用：トップ画面に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('デモ用：トップ画面に戻る'));
    await tester.pumpAndSettle();
    expect(find.text('トップ画面に戻りますか？'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
    expect(find.text('戻る'), findsOneWidget);
  });

  testWidgets('DR-4: ダイアログで「戻る」を押すと onRoleChange("") が呼ばれる', (tester) async {
    String? capturedRole;
    await tester.pumpWidget(buildSettings(onRoleChange: (role) async {
      capturedRole = role;
    }));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('デモ用：トップ画面に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('デモ用：トップ画面に戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(capturedRole, '');
  });

  testWidgets('DR-5: ダイアログで「キャンセル」を押すと onRoleChange は呼ばれない', (tester) async {
    String? capturedRole;
    await tester.pumpWidget(buildSettings(onRoleChange: (role) async {
      capturedRole = role;
    }));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('デモ用：トップ画面に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('デモ用：トップ画面に戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(capturedRole, isNull);
  });

  testWidgets('DR-6: onRoleChange が null のときボタンは無効になる', (tester) async {
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('デモ用：トップ画面に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('デモ用：トップ画面に戻る'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
