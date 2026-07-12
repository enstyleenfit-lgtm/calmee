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

  // ── DR: モード選択に戻るボタン ─────────────────────────────────
  testWidgets('DR-1: 「モード選択に戻る」ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildSettings(onRoleChange: (_) async {}));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('モード選択に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('モード選択に戻る'), findsOneWidget);
  });

  testWidgets('DR-3: ボタンタップで確認ダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildSettings(onRoleChange: (_) async {}));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('モード選択に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('モード選択に戻る'));
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
      find.text('モード選択に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('モード選択に戻る'));
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
      find.text('モード選択に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('モード選択に戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(capturedRole, isNull);
  });

  testWidgets('DR-6: onRoleChange が null のときボタンは無効になる', (tester) async {
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('モード選択に戻る'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('モード選択に戻る'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
