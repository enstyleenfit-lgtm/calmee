import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karada_shushi/main.dart';

Reservation makeReservation({
  String? id = 'r1',
  ReservationStatus status = ReservationStatus.scheduled,
  String customerName = '田中様',
  String memo = '',
}) =>
    Reservation(
      id: id,
      customerUid: 'cust1',
      customerName: customerName,
      scheduledAt: DateTime(2026, 8, 1, 15, 0),
      durationMinutes: 60,
      memo: memo,
      status: status,
      createdAt: DateTime(2026, 7, 1),
    );

Widget buildCard(
  Reservation r, {
  void Function(Reservation, ReservationStatus)? onStatusChange,
}) =>
    MaterialApp(
      home: Scaffold(
        body: ReservationCard(
          reservation: r,
          onStatusChange: onStatusChange ?? (a, b) {},
        ),
      ),
    );

void main() {
  // ── RS: ReservationCard ──────────────────────────────────────────────────

  testWidgets('RS-1: scheduled 状態で「予定」バッジが表示される', (tester) async {
    await tester
        .pumpWidget(buildCard(makeReservation(status: ReservationStatus.scheduled)));
    await tester.pump();
    expect(find.textContaining('予定'), findsWidgets);
  });

  testWidgets('RS-2: completed 状態で「完了」バッジが表示される', (tester) async {
    await tester
        .pumpWidget(buildCard(makeReservation(status: ReservationStatus.completed)));
    await tester.pump();
    expect(find.textContaining('完了'), findsOneWidget);
  });

  testWidgets('RS-3: canceled 状態で「キャンセル」バッジが表示される', (tester) async {
    await tester
        .pumpWidget(buildCard(makeReservation(status: ReservationStatus.canceled)));
    await tester.pump();
    expect(find.textContaining('キャンセル'), findsOneWidget);
  });

  testWidgets('RS-4: scheduled のみ操作ボタン（完了にする・キャンセル）が表示される',
      (tester) async {
    await tester
        .pumpWidget(buildCard(makeReservation(status: ReservationStatus.scheduled)));
    await tester.pump();
    expect(find.text('完了にする'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
  });

  testWidgets('RS-5: completed のとき操作ボタンが表示されない', (tester) async {
    await tester
        .pumpWidget(buildCard(makeReservation(status: ReservationStatus.completed)));
    await tester.pump();
    expect(find.text('完了にする'), findsNothing);
    expect(find.text('キャンセル'), findsNothing);
  });

  testWidgets('RS-6: 顧客名が表示される', (tester) async {
    await tester.pumpWidget(buildCard(makeReservation(customerName: '鈴木様')));
    await tester.pump();
    expect(find.text('鈴木様'), findsOneWidget);
  });

  testWidgets('RS-7: 日付が表示される', (tester) async {
    await tester.pumpWidget(buildCard(makeReservation()));
    await tester.pump();
    expect(find.textContaining('8月1日'), findsOneWidget);
  });

  testWidgets('RS-8: メモが表示される', (tester) async {
    await tester.pumpWidget(buildCard(makeReservation(memo: '初回セッション')));
    await tester.pump();
    expect(find.text('初回セッション'), findsOneWidget);
  });

  testWidgets('RS-9: 「完了にする」タップで onStatusChange が completed で呼ばれる',
      (tester) async {
    ReservationStatus? called;
    final r = makeReservation(status: ReservationStatus.scheduled);
    await tester.pumpWidget(buildCard(
      r,
      onStatusChange: (_, s) {
        called = s;
      },
    ));
    await tester.pump();
    await tester.tap(find.text('完了にする'));
    await tester.pump();
    expect(called, ReservationStatus.completed);
  });

  testWidgets('RS-10: 「キャンセル」タップで onStatusChange が canceled で呼ばれる',
      (tester) async {
    ReservationStatus? called;
    final r = makeReservation(status: ReservationStatus.scheduled);
    await tester.pumpWidget(buildCard(
      r,
      onStatusChange: (_, s) {
        called = s;
      },
    ));
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    expect(called, ReservationStatus.canceled);
  });

  // ── RS: AddReservationSheet ──────────────────────────────────────────────

  testWidgets('RS-11: 顧客リストありのとき「顧客を選択」ヒントが表示される', (tester) async {
    final customers = [
      CustomerLink(
          customerUid: 'c1',
          displayName: '田中様',
          linkedAt: DateTime(2026, 1, 1)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddReservationSheet(
            trainerUid: 'trainer1',
            customers: customers,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('予約を追加'), findsOneWidget);
    expect(find.text('顧客を選択'), findsOneWidget);
  });

  testWidgets('RS-12: 顧客未選択で保存するとエラーメッセージが表示される', (tester) async {
    final customers = [
      CustomerLink(
          customerUid: 'c1',
          displayName: '田中様',
          linkedAt: DateTime(2026, 1, 1)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddReservationSheet(
            trainerUid: 'trainer1',
            customers: customers,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('顧客を選択してください'), findsOneWidget);
  });

  // ── RS: TrainerReservationScreen ────────────────────────────────────────

  testWidgets('RS-13: 予約タブに「予約管理」が表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrainerReservationScreen(
            trainerUid: 'test_trainer',
            customers: [],
            initialReservations: [],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('予約管理'), findsOneWidget);
  });

  testWidgets('RS-14: 予約が空のとき空状態テキストが表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrainerReservationScreen(
            trainerUid: 'test_trainer',
            customers: [],
            initialReservations: [],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('予約はありません'), findsOneWidget);
  });

  testWidgets('RS-15: 予約が渡されると ReservationCard が表示される', (tester) async {
    final reservations = [makeReservation(customerName: '山田様')];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerReservationScreen(
            trainerUid: 'test_trainer',
            customers: const [],
            initialReservations: reservations,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('山田様'), findsOneWidget);
  });
}
