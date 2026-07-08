import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

void main() {
  Widget buildCard({
    WeeklyCheckin checkin = const WeeklyCheckin(),
    BodyCheck bodyCheck = const BodyCheck(),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WeeklyStatusCard(checkin: checkin, bodyCheck: bodyCheck),
      ),
    );
  }

  // ── WST: WeeklyStatusCard (トレーナー統合ビュー) ─────────────────────────

  testWidgets('WST-1: 両方空のとき空状態テキストが2行表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.text('チェックイン未入力'), findsOneWidget);
    expect(find.text('体型チェック未記録'), findsOneWidget);
  });

  testWidgets('WST-2: 達成度チップが表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 5);
    await tester.pumpWidget(buildCard(checkin: checkin));
    await tester.pump();
    expect(find.text('達成度'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('WST-3: 疲労チップが表示される', (tester) async {
    const checkin = WeeklyCheckin(fatigue: 4);
    await tester.pumpWidget(buildCard(checkin: checkin));
    await tester.pump();
    expect(find.text('疲労'), findsOneWidget);
  });

  testWidgets('WST-4: 睡眠チップが表示される', (tester) async {
    const checkin = WeeklyCheckin(sleep: 3);
    await tester.pumpWidget(buildCard(checkin: checkin));
    await tester.pump();
    expect(find.text('睡眠'), findsOneWidget);
  });

  testWidgets('WST-5: むくみチップが表示される', (tester) async {
    const bodyCheck = BodyCheck(edema: 3);
    await tester.pumpWidget(buildCard(bodyCheck: bodyCheck));
    await tester.pump();
    expect(find.text('むくみ'), findsOneWidget);
  });

  testWidgets('WST-6: 腹部つまみ感チップが表示される', (tester) async {
    const bodyCheck = BodyCheck(pinchFeel: 2);
    await tester.pumpWidget(buildCard(bodyCheck: bodyCheck));
    await tester.pump();
    expect(find.text('腹部つまみ感'), findsOneWidget);
  });

  testWidgets('WST-7: ウエストが cm 付きで表示される', (tester) async {
    const bodyCheck = BodyCheck(waist: 72.5);
    await tester.pumpWidget(buildCard(bodyCheck: bodyCheck));
    await tester.pump();
    expect(find.text('72.5 cm'), findsOneWidget);
  });

  testWidgets('WST-8: 体調メモが表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3, bodyNote: '少し疲れ気味です');
    await tester.pumpWidget(buildCard(checkin: checkin));
    await tester.pump();
    expect(find.text('少し疲れ気味です'), findsOneWidget);
  });

  testWidgets('WST-9: 相談事項が表示される', (tester) async {
    const checkin = WeeklyCheckin(achievement: 3, consultation: '食事量を増やしたい');
    await tester.pumpWidget(buildCard(checkin: checkin));
    await tester.pump();
    expect(find.text('食事量を増やしたい'), findsOneWidget);
  });

  testWidgets('WST-10: 見た目変化が表示される', (tester) async {
    const bodyCheck = BodyCheck(edema: 1, lookNote: 'お腹が引き締まった');
    await tester.pumpWidget(buildCard(bodyCheck: bodyCheck));
    await tester.pump();
    expect(find.text('お腹が引き締まった'), findsOneWidget);
  });

  testWidgets('WST-11: 気になる部位が表示される', (tester) async {
    const bodyCheck = BodyCheck(edema: 1, concernArea: '太もも');
    await tester.pumpWidget(buildCard(bodyCheck: bodyCheck));
    await tester.pump();
    expect(find.text('太もも'), findsOneWidget);
  });

  testWidgets('WST-12: チェックインのみ入力済みのとき体型バッジが「未」と表示される',
      (tester) async {
    const checkin = WeeklyCheckin(achievement: 3);
    await tester.pumpWidget(buildCard(checkin: checkin));
    await tester.pump();
    expect(find.textContaining('チェックイン ✓'), findsOneWidget);
    expect(find.textContaining('体型 未'), findsOneWidget);
  });

  testWidgets('WST-13: タイトル「今週の状態」が表示される', (tester) async {
    await tester.pumpWidget(buildCard());
    await tester.pump();
    expect(find.text('今週の状態'), findsOneWidget);
  });
}
