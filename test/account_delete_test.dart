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

  Widget buildSettings({VoidCallback? onDeleteAccount}) {
    return MaterialApp(
      home: Scaffold(
        body: SettingsScreen(
          goals: goals,
          role: 'customer',
          onSave: (_) async {},
          onDeleteAccount: onDeleteAccount ?? () {},
        ),
      ),
    );
  }

  Widget buildTrainerSelf({VoidCallback? onDeleteAccount}) {
    return MaterialApp(
      home: Scaffold(
        body: TrainerSelfScreen(
          onDeleteAccount: onDeleteAccount ?? () {},
        ),
      ),
    );
  }

  // ── AD: アカウント削除導線 ────────────────────────────────────

  testWidgets('AD-1: SettingsScreen に「アカウントを削除する」が表示される',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('アカウントを削除する').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('アカウントを削除する'), findsWidgets);
  });

  testWidgets('AD-2: SettingsScreen の削除ボタンタップで確認ダイアログが表示される',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('アカウントを削除する').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('アカウントを削除する').first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('AD-3: 確認ダイアログに「復元できません」が表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('アカウントを削除する').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('アカウントを削除する').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('復元できません'), findsWidgets);
  });

  testWidgets('AD-4: 確認ダイアログに問い合わせ先メールアドレスが表示される',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('アカウントを削除する').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('アカウントを削除する').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('enstyle.enfit@gmail.com'), findsWidgets);
  });

  testWidgets('AD-5: 「キャンセル」タップでダイアログが閉じる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSettings());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('アカウントを削除する').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('アカウントを削除する').first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('AD-6: TrainerSelfScreen に「アカウントを削除する」が表示される',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTrainerSelf());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('アカウントを削除する').first,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('アカウントを削除する'), findsWidgets);
  });
}
