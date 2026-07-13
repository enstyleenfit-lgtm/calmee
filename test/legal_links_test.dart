import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  const goals = GoalSettings(
    targetKcal: 2000,
    proteinTarget: 120.0,
    fatTarget: 55.0,
    carbTarget: 250.0,
  );

  Widget buildSettings() {
    return MaterialApp(
      home: Scaffold(
        body: SettingsScreen(
          goals: goals,
          role: 'customer',
          onSave: (_) async {},
        ),
      ),
    );
  }

  // ── LP: 法的リンク（Legal Policy） ────────────────────────────

  testWidgets('LP-1: SettingsScreen に「プライバシーポリシー」が表示される',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('プライバシーポリシー').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('プライバシーポリシー'), findsWidgets);
  });

  testWidgets('LP-2: SettingsScreen に「利用規約」が表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('利用規約').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('利用規約'), findsWidgets);
  });

  testWidgets('LP-3: 「プライバシーポリシー」タップで PrivacyPolicyScreen が開く',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('プライバシーポリシー').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('プライバシーポリシー').first);
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
  });

  testWidgets('LP-4: PrivacyPolicyScreen に問い合わせ先メールアドレスが表示される',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPolicyScreen()),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('enstyle.enfit@gmail.com'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('enstyle.enfit@gmail.com'), findsWidgets);
  });

  testWidgets('LP-5: TermsOfServiceScreen に健康・医療に関する免責が表示される',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TermsOfServiceScreen()),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.textContaining('医療行為'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('医療行為'), findsWidgets);
  });
}
