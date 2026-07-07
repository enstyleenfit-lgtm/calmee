import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Web判定
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// 通知 + TTS + timezone
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'data/food_suggestions.dart';
import 'data/exercise_suggestions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CalmeeApp());
}

/// ----------------------------
/// Models
/// ----------------------------

class HabitEntry {
  final DateTime date; // dateOnly
  final String habit;

  HabitEntry({required this.date, required this.habit});

  static HabitEntry fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ts = data['date'] as Timestamp?;
    return HabitEntry(
      date: (ts?.toDate()) ?? DateTime.now(),
      habit: (data['habit'] as String?) ?? '',
    );
  }
}

class TodayStatus {
  final bool doneToday;
  final HabitEntry? todayEntry;
  final int streak; // 表示用（直近履歴から簡易）

  TodayStatus({
    required this.doneToday,
    required this.todayEntry,
    required this.streak,
  });
}

class PlanItem {
  final String type; // meal/stretch/workout/sleep
  final String time; // "08:00"
  final String title;
  final bool enabled;

  PlanItem({
    required this.type,
    required this.time,
    required this.title,
    required this.enabled,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'time': time,
        'title': title,
        'enabled': enabled,
      };

  static PlanItem fromMap(Map<String, dynamic> m) => PlanItem(
        type: (m['type'] as String?) ?? 'meal',
        time: (m['time'] as String?) ?? '08:00',
        title: (m['title'] as String?) ?? '',
        enabled: (m['enabled'] as bool?) ?? true,
      );

  PlanItem copyWith({
    String? type,
    String? time,
    String? title,
    bool? enabled,
  }) {
    return PlanItem(
      type: type ?? this.type,
      time: time ?? this.time,
      title: title ?? this.title,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// ----------------------------
/// Calorie Models (ダミー)
/// ----------------------------

class DailyCalorieSummary {
  final int intake;
  final int burn; // 消費カロリー（運動）
  final int target;

  const DailyCalorieSummary({
    required this.intake,
    this.burn = 0,
    required this.target,
  });

  int get balance => intake - burn; // 純収支（摂取 - 消費）
  int get remaining => target - balance; // 残り枠（目標 - 純収支）
  double get progress => (balance / target).clamp(0.0, 1.0);
}

class MealLog {
  final String name;
  final int kcal;
  final double protein;
  final double fat;
  final double carb;
  final String time;

  const MealLog({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.time,
  });
}

class MealLogEntry {
  final String? id;
  final String name;
  final int kcal;
  final double protein;
  final double fat;
  final double carb;
  final DateTime loggedAt;
  final DateTime date;

  MealLogEntry({
    this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.loggedAt,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carb': carb,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'date': Timestamp.fromDate(date),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static MealLogEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final loggedAt =
        (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return MealLogEntry(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      kcal: (data['kcal'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      carb: (data['carb'] as num?)?.toDouble() ?? 0.0,
      loggedAt: loggedAt,
      date: date,
    );
  }
}

class ExerciseLogEntry {
  final String? id;
  final String name;
  final int kcal;
  final String category; // "self" = 自主運動, "trainer_session" = トレーナーとのトレーニング
  final String memo;
  final DateTime loggedAt;
  final DateTime date;
  final String createdByRole; // "customer" | "trainer"（将来のロール分岐用）

  ExerciseLogEntry({
    this.id,
    required this.name,
    required this.kcal,
    required this.category,
    this.memo = '',
    required this.loggedAt,
    required this.date,
    this.createdByRole = 'customer',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'kcal': kcal,
        'category': category,
        'memo': memo,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'date': Timestamp.fromDate(date),
        'createdByRole': createdByRole,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static ExerciseLogEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final loggedAt =
        (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ExerciseLogEntry(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      kcal: (data['kcal'] as num?)?.toInt() ?? 0,
      category: (data['category'] as String?) ?? 'self',
      memo: (data['memo'] as String?) ?? '',
      loggedAt: loggedAt,
      date: date,
      createdByRole: (data['createdByRole'] as String?) ?? 'customer',
    );
  }
}

class WeightLogEntry {
  final String? id;
  final double weight;
  final String memo;
  final DateTime loggedAt;
  final DateTime date;
  final String createdByRole;

  WeightLogEntry({
    this.id,
    required this.weight,
    this.memo = '',
    required this.loggedAt,
    required this.date,
    this.createdByRole = 'customer',
  });

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'memo': memo,
        'loggedAt': Timestamp.fromDate(loggedAt),
        'date': Timestamp.fromDate(date),
        'createdByRole': createdByRole,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static WeightLogEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final loggedAt =
        (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return WeightLogEntry(
      id: doc.id,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      memo: (data['memo'] as String?) ?? '',
      loggedAt: loggedAt,
      date: date,
      createdByRole: (data['createdByRole'] as String?) ?? 'customer',
    );
  }
}

/// ----------------------------
/// TrainerMessage
/// ----------------------------

class TrainerMessage {
  final String? id;
  final String text;
  final String trainerUid;
  final DateTime createdAt;
  final bool isRead;

  TrainerMessage({
    this.id,
    required this.text,
    required this.trainerUid,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'trainerUid': trainerUid,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static TrainerMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TrainerMessage(
      id: doc.id,
      text: (data['text'] as String?) ?? '',
      trainerUid: (data['trainerUid'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }
}

/// ----------------------------
/// SharedNote
/// ----------------------------

class SharedNote {
  final String? id;
  final String title;
  final String body;
  final String trainerUid;
  final DateTime createdAt;

  SharedNote({
    this.id,
    required this.title,
    required this.body,
    required this.trainerUid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'trainerUid': trainerUid,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static SharedNote fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SharedNote(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      trainerUid: (data['trainerUid'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// ----------------------------
/// CustomerLink
/// ----------------------------

class CustomerLink {
  final String customerUid;
  final String displayName;
  final DateTime linkedAt;

  CustomerLink({
    required this.customerUid,
    required this.displayName,
    required this.linkedAt,
  });

  static CustomerLink fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CustomerLink(
      customerUid: doc.id,
      displayName: (data['displayName'] as String?) ?? '',
      linkedAt: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// ----------------------------
/// Noti + TTS
/// ----------------------------

class NotiTtsService {
  NotiTtsService._();
  static final instance = NotiTtsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();

  // ★ 通知タップ時のpayloadを保持（Homeで導線表示用）
  String? lastPayload;

  Future<void> init() async {
    tzdata.initializeTimeZones();

    // TTS（最低限）
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) async {
        final text = resp.payload ?? '';
        if (text.trim().isNotEmpty) {
          lastPayload = text;
          await speak(text);
        }
      },
    );

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    // Webは型/挙動の制限があるので何もしない
    if (kIsWeb) return;

    // Android 13+
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    // iOS（最低限）
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    // ※ DarwinFlutterLocalNotificationsPlugin は環境差が出るため使わない
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// 当日分だけ通知をスケジュール（MVP）
  Future<void> scheduleTodayPlan(List<PlanItem> items) async {
    // Webでは通知が成立しないことが多いのでスキップ
    if (kIsWeb) return;

    await cancelAll();

    final now = DateTime.now();
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      if (!it.enabled) continue;

      final parts = it.time.split(':');
      final hh = int.tryParse(parts[0]) ?? 8;
      final mm = int.tryParse(parts[1]) ?? 0;

      final when = DateTime(now.year, now.month, now.day, hh, mm);
      if (when.isBefore(now)) continue;

      final payload = _payloadText(it);

      await _plugin.zonedSchedule(
        1000 + i,
        'からだ収支：${it.title}',
        'タップして音声でサポートします',
        tz.TZDateTime.from(when, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'calmee_plan',
            'からだ収支 プラン',
            channelDescription: '予定のリマインド通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  String _payloadText(PlanItem it) {
    switch (it.type) {
      case 'meal':
        return '食事の時間です。焦らず、整えていこう。${it.title}';
      case 'stretch':
        return 'ストレッチの時間です。呼吸を深く。${it.title}';
      case 'workout':
        return '軽く動く時間です。できるところから。${it.title}';
      case 'sleep':
        return '休む準備をしよう。明日の自分が助かる。${it.title}';
      default:
        return '予定の時間です。${it.title}';
    }
  }
}

/// ----------------------------
/// Firestore Repos
/// ----------------------------

class HabitRepository {
  HabitRepository(this.uid);

  final String uid;

  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('habits');

  DateTime toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String docIdByDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<List<HabitEntry>> loadRecent({int limit = 7}) async {
    final snap =
        await _habitsRef.orderBy('date', descending: true).limit(limit).get();
    return snap.docs.map(HabitEntry.fromDoc).toList();
  }

  Future<void> saveToday({required String habit}) async {
    final today = toDateOnly(DateTime.now());
    final docId = docIdByDate(today);

    await _habitsRef.doc(docId).set({
      'date': Timestamp.fromDate(today),
      'habit': habit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ★B1: streakをFirestoreで正確に管理
  Future<int> updateStreakOnCompleteToday() async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final metaRef = userDoc.collection('meta').doc('streak');

    final today = toDateOnly(DateTime.now());

    return FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snap = await tx.get(metaRef);

      int current = 0;
      DateTime? lastDone;

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        current = (data['current'] as num?)?.toInt() ?? 0;
        final ts = data['lastDoneDate'] as Timestamp?;
        lastDone = ts?.toDate();
        if (lastDone != null) {
          lastDone = toDateOnly(lastDone);
        }
      }

      if (lastDone == null) {
        current = 1;
      } else if (lastDone == today) {
        // 今日すでに完了 → そのまま
      } else if (lastDone == today.subtract(const Duration(days: 1))) {
        current += 1;
      } else {
        current = 1;
      }

      tx.set(metaRef, {
        'current': current,
        'lastDoneDate': Timestamp.fromDate(today),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return current;
    });
  }
}

class PlanRepository {
  PlanRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('plans');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _docId(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  List<PlanItem> defaultPlan() => [
        PlanItem(type: 'meal', time: '08:00', title: '朝食', enabled: true),
        PlanItem(type: 'stretch', time: '12:00', title: 'ストレッチ3分', enabled: true),
        PlanItem(type: 'meal', time: '16:00', title: '水分・軽食', enabled: true),
        PlanItem(type: 'sleep', time: '23:30', title: '寝る準備', enabled: true),
      ];

  Future<List<PlanItem>> loadToday() async {
    final today = _dateOnly(DateTime.now());
    final doc = await _ref.doc(_docId(today)).get();
    final data = doc.data();
    if (data == null) return defaultPlan();

    final raw = (data['items'] as List?) ?? [];
    if (raw.isEmpty) return defaultPlan();

    return raw
        .map((e) => PlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveToday(List<PlanItem> items) async {
    final today = _dateOnly(DateTime.now());
    await _ref.doc(_docId(today)).set({
      'date': Timestamp.fromDate(today),
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class MealRepository {
  MealRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mealLogs');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> saveMeal(MealLogEntry entry) async {
    await _ref.add(entry.toMap());
  }

  Future<List<MealLogEntry>> loadToday() async {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final snap = await _ref
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    final entries = snap.docs
        .map((d) => MealLogEntry.fromDoc(d))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return entries;
  }

  Future<List<MealLogEntry>> loadForDate(DateTime date) async {
    final d = _dateOnly(date);
    final nextDay = d.add(const Duration(days: 1));
    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .get();
    return snap.docs.map((doc) => MealLogEntry.fromDoc(doc)).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<List<MealLogEntry>> loadForDateRange(
      DateTime from, DateTime to) async {
    final f = _dateOnly(from);
    final tEnd = _dateOnly(to).add(const Duration(days: 1));
    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(f))
        .where('date', isLessThan: Timestamp.fromDate(tEnd))
        .get();
    return snap.docs.map((d) => MealLogEntry.fromDoc(d)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> deleteMeal(String id) async {
    await _ref.doc(id).delete();
  }
}

class ExerciseRepository {
  ExerciseRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exerciseLogs');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> saveExercise(ExerciseLogEntry entry) async {
    await _ref.add(entry.toMap());
  }

  Future<List<ExerciseLogEntry>> loadToday() async {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('date', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    return snap.docs
        .map((d) => ExerciseLogEntry.fromDoc(d))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<List<ExerciseLogEntry>> loadForDate(DateTime date) async {
    final d = _dateOnly(date);
    final nextDay = d.add(const Duration(days: 1));
    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .get();
    return snap.docs.map((doc) => ExerciseLogEntry.fromDoc(doc)).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<List<ExerciseLogEntry>> loadForDateRange(
      DateTime from, DateTime to) async {
    final f = _dateOnly(from);
    final tEnd = _dateOnly(to).add(const Duration(days: 1));
    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(f))
        .where('date', isLessThan: Timestamp.fromDate(tEnd))
        .get();
    return snap.docs.map((d) => ExerciseLogEntry.fromDoc(d)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> deleteExercise(String id) async {
    await _ref.doc(id).delete();
  }
}

class WeightRepository {
  WeightRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('weightLogs');

  Future<void> saveWeight(WeightLogEntry entry) async {
    await _ref.add(entry.toMap());
  }

  Future<List<WeightLogEntry>> loadRecent({int limit = 7}) async {
    final snap = await _ref
        .orderBy('loggedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => WeightLogEntry.fromDoc(d)).toList();
  }

  Future<List<WeightLogEntry>> loadForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final nextDay = d.add(const Duration(days: 1));
    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .get();
    return snap.docs.map((doc) => WeightLogEntry.fromDoc(doc)).toList();
  }

  Future<void> deleteWeight(String id) async {
    await _ref.doc(id).delete();
  }
}

/// ----------------------------
/// TrainerMessageRepository
/// ----------------------------

class TrainerMessageRepository {
  TrainerMessageRepository(this.customerUid);
  final String customerUid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(customerUid)
          .collection('trainerMessages');

  Future<void> sendMessage({
    required String text,
    required String trainerUid,
  }) async {
    final now = DateTime.now();
    await _ref.add({
      'text': text.trim(),
      'trainerUid': trainerUid,
      'createdAt': Timestamp.fromDate(now),
      'isRead': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<TrainerMessage>> loadRecent({int limit = 3}) async {
    final snap = await _ref
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => TrainerMessage.fromDoc(d)).toList();
  }
}

/// ----------------------------
/// SharedNoteRepository
/// ----------------------------

class SharedNoteRepository {
  SharedNoteRepository(this.customerUid);
  final String customerUid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(customerUid)
          .collection('sharedNotes');

  Future<void> saveNote(SharedNote note) async {
    await _ref.add(note.toMap());
  }

  Future<List<SharedNote>> loadRecent({int limit = 20}) async {
    final snap = await _ref
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => SharedNote.fromDoc(d)).toList();
  }
}

/// ----------------------------
/// Karte models
/// ----------------------------

class KarteBasicInfo {
  const KarteBasicInfo({
    this.age,
    this.gender = '',
    this.height,
    this.currentWeight,
    this.targetWeight,
    this.bodyFatPct,
    this.lifestyleRhythm = '',
  });
  final int? age;
  final String gender;
  final double? height;
  final double? currentWeight;
  final double? targetWeight;
  final double? bodyFatPct;
  final String lifestyleRhythm;

  Map<String, dynamic> toMap() => {
        'age': age,
        'gender': gender,
        'height': height,
        'currentWeight': currentWeight,
        'targetWeight': targetWeight,
        'bodyFatPct': bodyFatPct,
        'lifestyleRhythm': lifestyleRhythm,
      };

  static KarteBasicInfo fromMap(Map<String, dynamic> m) => KarteBasicInfo(
        age: m['age'] as int?,
        gender: (m['gender'] as String?) ?? '',
        height: (m['height'] as num?)?.toDouble(),
        currentWeight: (m['currentWeight'] as num?)?.toDouble(),
        targetWeight: (m['targetWeight'] as num?)?.toDouble(),
        bodyFatPct: (m['bodyFatPct'] as num?)?.toDouble(),
        lifestyleRhythm: (m['lifestyleRhythm'] as String?) ?? '',
      );
}

class KarteHearing {
  const KarteHearing({
    this.referralSource = '',
    this.motivation = '',
    this.concerns = '',
    this.dietHistory = '',
    this.exerciseHistory = '',
    this.dietChallenges = '',
    this.medicalNotes = '',
  });
  final String referralSource;
  final String motivation;
  final String concerns;
  final String dietHistory;
  final String exerciseHistory;
  final String dietChallenges;
  final String medicalNotes;

  Map<String, dynamic> toMap() => {
        'referralSource': referralSource,
        'motivation': motivation,
        'concerns': concerns,
        'dietHistory': dietHistory,
        'exerciseHistory': exerciseHistory,
        'dietChallenges': dietChallenges,
        'medicalNotes': medicalNotes,
      };

  static KarteHearing fromMap(Map<String, dynamic> m) => KarteHearing(
        referralSource: (m['referralSource'] as String?) ?? '',
        motivation: (m['motivation'] as String?) ?? '',
        concerns: (m['concerns'] as String?) ?? '',
        dietHistory: (m['dietHistory'] as String?) ?? '',
        exerciseHistory: (m['exerciseHistory'] as String?) ?? '',
        dietChallenges: (m['dietChallenges'] as String?) ?? '',
        medicalNotes: (m['medicalNotes'] as String?) ?? '',
      );
}

class KarteGoals {
  const KarteGoals({
    this.finalGoal = '',
    this.threeMonthGoal = '',
    this.oneMonthGoal = '',
    this.eventSchedule = '',
    this.goalReason = '',
    this.avoidState = '',
  });
  final String finalGoal;
  final String threeMonthGoal;
  final String oneMonthGoal;
  final String eventSchedule;
  final String goalReason;
  final String avoidState;

  Map<String, dynamic> toMap() => {
        'finalGoal': finalGoal,
        'threeMonthGoal': threeMonthGoal,
        'oneMonthGoal': oneMonthGoal,
        'eventSchedule': eventSchedule,
        'goalReason': goalReason,
        'avoidState': avoidState,
      };

  static KarteGoals fromMap(Map<String, dynamic> m) => KarteGoals(
        finalGoal: (m['finalGoal'] as String?) ?? '',
        threeMonthGoal: (m['threeMonthGoal'] as String?) ?? '',
        oneMonthGoal: (m['oneMonthGoal'] as String?) ?? '',
        eventSchedule: (m['eventSchedule'] as String?) ?? '',
        goalReason: (m['goalReason'] as String?) ?? '',
        avoidState: (m['avoidState'] as String?) ?? '',
      );
}

class KarteProfile {
  const KarteProfile({
    this.basicInfo = const KarteBasicInfo(),
    this.hearing = const KarteHearing(),
    this.goals = const KarteGoals(),
  });
  final KarteBasicInfo basicInfo;
  final KarteHearing hearing;
  final KarteGoals goals;

  Map<String, dynamic> toMap() => {
        'basicInfo': basicInfo.toMap(),
        'hearing': hearing.toMap(),
        'goals': goals.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static KarteProfile fromMap(Map<String, dynamic> m) => KarteProfile(
        basicInfo: KarteBasicInfo.fromMap(
            (m['basicInfo'] as Map<String, dynamic>?) ?? {}),
        hearing: KarteHearing.fromMap(
            (m['hearing'] as Map<String, dynamic>?) ?? {}),
        goals: KarteGoals.fromMap(
            (m['goals'] as Map<String, dynamic>?) ?? {}),
      );
}

class KartePrivate {
  const KartePrivate({
    this.currentChallenges = '',
    this.cautions = '',
    this.nextCheckItems = '',
    this.motivationTrend = '',
    this.coachingStyle = '',
  });
  final String currentChallenges;
  final String cautions;
  final String nextCheckItems;
  final String motivationTrend;
  final String coachingStyle;

  Map<String, dynamic> toMap() => {
        'currentChallenges': currentChallenges,
        'cautions': cautions,
        'nextCheckItems': nextCheckItems,
        'motivationTrend': motivationTrend,
        'coachingStyle': coachingStyle,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static KartePrivate fromMap(Map<String, dynamic> m) => KartePrivate(
        currentChallenges: (m['currentChallenges'] as String?) ?? '',
        cautions: (m['cautions'] as String?) ?? '',
        nextCheckItems: (m['nextCheckItems'] as String?) ?? '',
        motivationTrend: (m['motivationTrend'] as String?) ?? '',
        coachingStyle: (m['coachingStyle'] as String?) ?? '',
      );
}

/// ----------------------------
/// KarteRepository
/// ----------------------------

class KarteRepository {
  KarteRepository(this.customerUid);
  final String customerUid;

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(customerUid)
          .collection('karteProfile')
          .doc('data');

  DocumentReference<Map<String, dynamic>> get _privateRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(customerUid)
          .collection('kartePrivate')
          .doc('data');

  Future<KarteProfile> loadProfile() async {
    final snap = await _profileRef.get();
    if (!snap.exists || snap.data() == null) return const KarteProfile();
    return KarteProfile.fromMap(snap.data()!);
  }

  Future<void> saveProfile(KarteProfile profile) async {
    await _profileRef.set(profile.toMap());
  }

  Future<KartePrivate> loadPrivate() async {
    final snap = await _privateRef.get();
    if (!snap.exists || snap.data() == null) return const KartePrivate();
    return KartePrivate.fromMap(snap.data()!);
  }

  Future<void> savePrivate(KartePrivate private) async {
    await _privateRef.set(private.toMap());
  }
}

/// ----------------------------
/// CustomerNotFoundException
class CustomerNotFoundException implements Exception {
  const CustomerNotFoundException();
}

/// TrainerCustomerRepository
/// ----------------------------

class TrainerCustomerRepository {
  TrainerCustomerRepository(this.trainerUid);
  final String trainerUid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('trainers')
          .doc(trainerUid)
          .collection('customers');

  Future<List<CustomerLink>> loadCustomers() async {
    final snap = await _ref.orderBy('linkedAt', descending: true).get();
    return snap.docs.map((d) => CustomerLink.fromDoc(d)).toList();
  }

  Future<void> addCustomer(String customerUid) async {
    // 重複チェック：既にリンク済みなら何もしない
    final existing = await _ref.doc(customerUid).get();
    if (existing.exists) return;

    // デフォルト表示名：UID 先頭8文字
    String displayName =
        customerUid.substring(0, customerUid.length.clamp(0, 8));

    // 顧客の profile を読んで存在確認と displayName 取得
    // permission-denied はルール未デプロイとみなし存在確認をスキップして進む
    try {
      final profileSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerUid)
          .collection('profile')
          .doc('data')
          .get();
      if (!profileSnap.exists) throw const CustomerNotFoundException();
      final raw = profileSnap.data()?['displayName'];
      if (raw is String && raw.isNotEmpty) displayName = raw;
    } on CustomerNotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // profile read が permission-denied の場合は存在確認をスキップ
    }

    await _ref.doc(customerUid).set({
      'displayName': displayName,
      'linkedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCustomer(String customerUid) async {
    await _ref.doc(customerUid).delete();
  }
}

/// ----------------------------
/// GoalSettings + GoalsRepository
/// ----------------------------

class GoalSettings {
  final int targetKcal;
  final double proteinTarget;
  final double fatTarget;
  final double carbTarget;

  const GoalSettings({
    this.targetKcal = 2000,
    this.proteinTarget = 120.0,
    this.fatTarget = 55.0,
    this.carbTarget = 250.0,
  });

  Map<String, dynamic> toMap() => {
        'targetKcal': targetKcal,
        'proteinTarget': proteinTarget,
        'fatTarget': fatTarget,
        'carbTarget': carbTarget,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static GoalSettings fromMap(Map<String, dynamic> m) => GoalSettings(
        targetKcal: (m['targetKcal'] as num?)?.toInt() ?? 2000,
        proteinTarget: (m['proteinTarget'] as num?)?.toDouble() ?? 120.0,
        fatTarget: (m['fatTarget'] as num?)?.toDouble() ?? 55.0,
        carbTarget: (m['carbTarget'] as num?)?.toDouble() ?? 250.0,
      );
}

class GoalsRepository {
  GoalsRepository(this.uid);
  final String uid;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('goals');

  Future<GoalSettings> load() async {
    final doc = await _ref.get();
    final data = doc.data();
    if (data == null) return const GoalSettings();
    return GoalSettings.fromMap(data);
  }

  Future<void> save(GoalSettings goals) async {
    await _ref.set(goals.toMap(), SetOptions(merge: true));
  }
}

/// ----------------------------
/// UserProfile + ProfileRepository
/// ----------------------------

class UserProfile {
  final String uid;
  final String role; // "customer" | "trainer"
  final String? displayName;

  const UserProfile({
    required this.uid,
    required this.role,
    this.displayName,
  });

  // ドキュメントなし or role フィールドなし → 未選択扱い（空文字）
  static UserProfile fromDoc(
      String uid, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return UserProfile(uid: uid, role: '');
    return UserProfile(
      uid: uid,
      role: (data['role'] as String?) ?? '',
      displayName: data['displayName'] as String?,
    );
  }
}

class ProfileRepository {
  ProfileRepository(this.uid);
  final String uid;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('data');

  Future<UserProfile> load() async {
    final doc = await _ref.get();
    return UserProfile.fromDoc(uid, doc);
  }

  Future<void> saveRole(String role) async {
    await _ref.set({'role': role}, SetOptions(merge: true));
  }
}

/// ----------------------------
/// Reward (A+B: 褒め進化) + (C: キラッ)
/// ----------------------------

Future<void> showPraiseRewardDialog(BuildContext context,
    {required int streak}) async {
  // ★B2: streak帯で褒めが進化
  String text;
  if (streak <= 1) {
    text = '初日、完了。ここから整う。';
  } else if (streak <= 3) {
    text = 'いい流れ。静かに続いてる。';
  } else if (streak <= 7) {
    text = '1週間。習慣になり始めた。';
  } else if (streak <= 14) {
    text = '2週間。もう強い。';
  } else if (streak <= 30) {
    text = '1ヶ月。積み上げたね。';
  } else {
    text = '積み上げが、実力になってる。';
  }

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('連続 $streak 日'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('おやすみ'),
        ),
      ],
    ),
  );
}

/// 画面全体に「キラッ」を出す簡易オーバーレイ
class RewardSparkle extends StatefulWidget {
  const RewardSparkle({super.key, required this.child});
  final Widget child;

  static Future<void> play(BuildContext context) async {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(builder: (_) => const _RewardSparkleLayer());
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 750));
    entry.remove();
  }

  @override
  State<RewardSparkle> createState() => _RewardSparkleState();
}

class _RewardSparkleState extends State<RewardSparkle> {
  @override
  Widget build(BuildContext context) => widget.child;
}

class _RewardSparkleLayer extends StatefulWidget {
  const _RewardSparkleLayer();

  @override
  State<_RewardSparkleLayer> createState() => _RewardSparkleLayerState();
}

class _RewardSparkleLayerState extends State<_RewardSparkleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, _) {
          final t = _a.value; // 0→1
          final opacity = (1.0 - t).clamp(0.0, 1.0);
          final scale = 0.85 + (t * 0.35);

          return Stack(
            children: [
              Opacity(
                opacity: opacity * 0.15,
                child: Container(color: Colors.white),
              ),
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, size: 78),
                        SizedBox(height: 10),
                        Icon(Icons.auto_awesome, size: 44),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 80,
                child: Opacity(
                  opacity: opacity * 0.9,
                  child: Transform.scale(
                    scale: 0.7 + (t * 0.2),
                    child: const Icon(Icons.star, size: 28),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: 110,
                child: Opacity(
                  opacity: opacity * 0.9,
                  child: Transform.scale(
                    scale: 0.7 + (t * 0.2),
                    child: const Icon(Icons.star, size: 28),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ----------------------------
/// App
/// ----------------------------

class CalmeeApp extends StatelessWidget {
  const CalmeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'からだ収支',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}

/// ポケスリっぽい「下部タブのシェル」
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  bool _loading = true;
  String? _uid;

  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int _index = 0;

  // 共有データ
  List<MealLogEntry> _mealLogs = [];
  List<ExerciseLogEntry> _exerciseLogs = [];
  List<WeightLogEntry> _weightLogs = [];
  List<WeightLogEntry> _recentWeightLogs = [];
  GoalSettings _goals = const GoalSettings();
  UserProfile? _profile;
  List<TrainerMessage> _trainerMessages = [];
  List<MealLogEntry> _weekMealLogs = [];
  List<ExerciseLogEntry> _weekExerciseLogs = [];
  List<SharedNote> _sharedNotes = [];
  KarteGoals _karteGoals = const KarteGoals();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      await _ensureSignedIn();
      final profile = await _profileRepo!.load();
      setState(() => _profile = profile);
      await NotiTtsService.instance.init();
      await _reloadAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    _uid = auth.currentUser!.uid;
  }

  MealRepository? get _mealRepo => _uid == null ? null : MealRepository(_uid!);
  ExerciseRepository? get _exerciseRepo =>
      _uid == null ? null : ExerciseRepository(_uid!);
  GoalsRepository? get _goalsRepo => _uid == null ? null : GoalsRepository(_uid!);
  WeightRepository? get _weightRepo =>
      _uid == null ? null : WeightRepository(_uid!);
  ProfileRepository? get _profileRepo =>
      _uid == null ? null : ProfileRepository(_uid!);

  DateTime _toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _prevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _reloadAll();
  }

  void _nextDay() {
    final today = _toDateOnly(DateTime.now());
    if (_selectedDate.isBefore(today)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _reloadAll();
    }
  }

  Future<void> _reloadAll() async {
    if (_uid == null) return;

    final today = _toDateOnly(DateTime.now());
    final meals = _mealRepo != null
        ? await _mealRepo!.loadForDate(_selectedDate)
        : <MealLogEntry>[];
    final exercises = _exerciseRepo != null
        ? await _exerciseRepo!.loadForDate(_selectedDate)
        : <ExerciseLogEntry>[];
    final weights = _weightRepo != null
        ? await _weightRepo!.loadForDate(_selectedDate)
        : <WeightLogEntry>[];
    final recentWeights = _weightRepo != null
        ? await _weightRepo!.loadRecent(limit: 7)
        : <WeightLogEntry>[];
    final weekStart = _toDateOnly(today.subtract(const Duration(days: 6)));
    final weekMeals = _mealRepo != null
        ? await _mealRepo!.loadForDateRange(weekStart, today)
        : <MealLogEntry>[];
    final weekExercises = _exerciseRepo != null
        ? await _exerciseRepo!.loadForDateRange(weekStart, today)
        : <ExerciseLogEntry>[];
    final goals = _goalsRepo != null
        ? await _goalsRepo!.load()
        : const GoalSettings();
    final trainerMsgs =
        await TrainerMessageRepository(_uid!).loadRecent(limit: 1);
    final sharedNotes = await SharedNoteRepository(_uid!).loadRecent();
    final karteProfile = await KarteRepository(_uid!).loadProfile();

    setState(() {
      _mealLogs = meals;
      _exerciseLogs = exercises;
      _weightLogs = weights;
      _recentWeightLogs = recentWeights;
      _goals = goals;
      _trainerMessages = trainerMsgs;
      _weekMealLogs = weekMeals;
      _weekExerciseLogs = weekExercises;
      _sharedNotes = sharedNotes;
      _karteGoals = karteProfile.goals;
    });
  }

  Future<void> _addMeal(MealLogEntry entry) async {
    if (_uid == null) return;
    await _mealRepo!.saveMeal(entry);
    await _reloadAll();
  }

  Future<void> _deleteMeal(String id) async {
    if (_uid == null) return;
    await _mealRepo!.deleteMeal(id);
    await _reloadAll();
  }

  Future<void> _addExercise(ExerciseLogEntry entry) async {
    if (_uid == null) return;
    await _exerciseRepo!.saveExercise(entry);
    await _reloadAll();
  }

  Future<void> _deleteExercise(String id) async {
    if (_uid == null) return;
    await _exerciseRepo!.deleteExercise(id);
    await _reloadAll();
  }

  Future<void> _addWeight(WeightLogEntry entry) async {
    if (_uid == null) return;
    await _weightRepo!.saveWeight(entry);
    await _reloadAll();
  }

  Future<void> _deleteWeight(String id) async {
    if (_uid == null) return;
    await _weightRepo!.deleteWeight(id);
    await _reloadAll();
  }

  Future<void> _updateGoals(GoalSettings goals) async {
    if (_uid == null) return;
    await _goalsRepo!.save(goals);
    await _reloadAll();
  }

  Future<void> _setRole(String role) async {
    if (_uid == null) return;
    setState(() => _loading = true);
    try {
      await _profileRepo!.saveRole(role);
      if (mounted) {
        setState(() {
          _profile = UserProfile(
            uid: _uid!,
            role: role,
            displayName: _profile?.displayName,
          );
        });
      }
      if (role == 'customer') await _reloadAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 初期ロード中（profile未取得）
    if (_loading && _profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ロール未選択
    if (_profile == null || _profile!.role.isEmpty) {
      return RoleSelectorScreen(onSelect: _setRole);
    }

    // trainer ロールは専用画面へ
    if (_profile!.role == 'trainer') {
      return TrainerHomeScreen(
        profile: _profile!,
        onSwitchToCustomer: () => _setRole('customer'),
      );
    }

    final screens = <Widget>[
      HomeScreen(
        loading: _loading,
        goals: _goals,
        mealLogs: _mealLogs,
        exerciseLogs: _exerciseLogs,
        weightLogs: _weightLogs,
        recentWeightLogs: _recentWeightLogs,
        onRefresh: () async {
          setState(() => _loading = true);
          await _reloadAll();
          if (mounted) setState(() => _loading = false);
        },
        onDeleteMeal: (id) async {
          setState(() => _loading = true);
          try {
            await _deleteMeal(id);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        onDeleteExercise: (id) async {
          setState(() => _loading = true);
          try {
            await _deleteExercise(id);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        onDeleteWeight: (id) async {
          setState(() => _loading = true);
          try {
            await _deleteWeight(id);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        selectedDate: _selectedDate,
        onPrevDay: _prevDay,
        onNextDay: _nextDay,
        trainerMessages: _trainerMessages,
      ),
      ProgressScreen(
        weekMealLogs: _weekMealLogs,
        weekExerciseLogs: _weekExerciseLogs,
        recentWeightLogs: _recentWeightLogs,
        goals: _goals,
      ),
      SharedNotesScreen(
        loading: _loading,
        mealLogs: _mealLogs,
        exerciseLogs: _exerciseLogs,
        weightLogs: _weightLogs,
        notes: _sharedNotes,
        goals: _goals,
        karteGoals: _karteGoals,
        selectedDate: _selectedDate,
        onRefresh: () async {
          setState(() => _loading = true);
          await _reloadAll();
          if (mounted) setState(() => _loading = false);
        },
      ),
      SettingsScreen(
        goals: _goals,
        onSave: _updateGoals,
        role: _profile?.role ?? 'customer',
        onRoleChange: _setRole,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: screens[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.restaurant_outlined),
                            title: const Text('食事を記録'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (_) => MealInputSheet(
                                  date: _selectedDate,
                                  onSave: (entry) async {
                                    setState(() => _loading = true);
                                    try {
                                      await _addMeal(entry);
                                    } finally {
                                      if (mounted) {
                                        setState(() => _loading = false);
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading:
                                const Icon(Icons.fitness_center_outlined),
                            title: const Text('運動を記録'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (_) => ExerciseInputSheet(
                                  date: _selectedDate,
                                  onSave: (entry) async {
                                    setState(() => _loading = true);
                                    try {
                                      await _addExercise(entry);
                                    } finally {
                                      if (mounted) {
                                        setState(() => _loading = false);
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.monitor_weight_outlined),
                            title: const Text('体重を記録'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (_) => WeightInputSheet(
                                  date: _selectedDate,
                                  onSave: (entry) async {
                                    setState(() => _loading = true);
                                    try {
                                      await _addWeight(entry);
                                    } finally {
                                      if (mounted) {
                                        setState(() => _loading = false);
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFF222222),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFFF0F0F0),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '進捗',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'ノート',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

/// ----------------------------
/// TrainerHomeScreen
/// ----------------------------

class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key, required this.profile, this.onSwitchToCustomer});
  final UserProfile profile;
  final VoidCallback? onSwitchToCustomer;

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  late final TrainerCustomerRepository _repo;
  List<CustomerLink> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = TrainerCustomerRepository(widget.profile.uid);
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    try {
      final customers = await _repo.loadCustomers();
      if (mounted) setState(() => _customers = customers);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCustomer() async {
    final uid = await showDialog<String>(
      context: context,
      builder: (_) => const AddCustomerDialog(),
    );
    if (uid == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.addCustomer(uid);
      await _reload();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('顧客を追加しました')),
        );
      }
    } on CustomerNotFoundException {
      messenger.showSnackBar(
        const SnackBar(content: Text('顧客IDが見つかりません')),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        messenger.showSnackBar(
          const SnackBar(content: Text('権限エラーで顧客を追加できません')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('顧客を追加できませんでした')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('顧客を追加できませんでした')),
      );
    }
  }

  Future<void> _confirmRemove(CustomerLink customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('顧客を削除'),
        content: Text('「${customer.displayName}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除',
                style: TextStyle(color: Color(0xFFE24A4A))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.removeCustomer(customer.customerUid);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'トレーナーホーム',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.onSwitchToCustomer != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF444444)),
              onSelected: (v) {
                if (v == 'switch') widget.onSwitchToCustomer!();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'switch',
                  child: Text('お客さんモードに切り替える'),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        backgroundColor: const Color(0xFF222222),
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _customers.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.group_outlined,
                                  size: 60, color: Color(0xFFCCCCCC)),
                              const SizedBox(height: 16),
                              Text(
                                '担当顧客がいません',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '右下の＋ボタンから顧客を追加してください',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFAAAAAA),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _customers.length,
                      itemBuilder: (_, i) {
                        final customer = _customers[i];
                        return _CustomerCard(
                          customer: customer,
                          onDelete: () => _confirmRemove(customer),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainerCustomerDetailScreen(
                                customer: customer,
                                trainerUid: widget.profile.uid,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onDelete, this.onTap});
  final CustomerLink customer;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  String _shortUid(String uid) =>
      uid.length > 8 ? '${uid.substring(0, 8)}...' : uid;

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF4A90E2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID: ${_shortUid(customer.customerUid)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBBBBBB),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '追加日: ${_formatDate(customer.linkedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFCCCCCC),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// TrainerCustomerDetailScreen
/// ----------------------------

class TrainerCustomerDetailScreen extends StatefulWidget {
  const TrainerCustomerDetailScreen({super.key, required this.customer, required this.trainerUid});
  final CustomerLink customer;
  final String trainerUid;

  @override
  State<TrainerCustomerDetailScreen> createState() =>
      _TrainerCustomerDetailScreenState();
}

class _TrainerCustomerDetailScreenState
    extends State<TrainerCustomerDetailScreen> {
  late final MealRepository _mealRepo;
  late final ExerciseRepository _exerciseRepo;
  late final WeightRepository _weightRepo;
  late final TrainerMessageRepository _msgRepo;
  late final SharedNoteRepository _noteRepo;
  late final KarteRepository _karteRepo;

  List<MealLogEntry> _meals = [];
  List<ExerciseLogEntry> _exercises = [];
  List<WeightLogEntry> _weights = [];
  List<TrainerMessage> _messages = [];
  List<SharedNote> _sharedNotes = [];
  KarteGoals _karteGoals = const KarteGoals();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final uid = widget.customer.customerUid;
    _mealRepo = MealRepository(uid);
    _exerciseRepo = ExerciseRepository(uid);
    _weightRepo = WeightRepository(uid);
    _msgRepo = TrainerMessageRepository(uid);
    _noteRepo = SharedNoteRepository(uid);
    _karteRepo = KarteRepository(uid);
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final meals = await _mealRepo.loadToday();
      final exercises = await _exerciseRepo.loadToday();
      final weights = await _weightRepo.loadRecent(limit: 7);
      final messages = await _msgRepo.loadRecent(limit: 3);
      final notes = await _noteRepo.loadRecent();
      final karteProfile = await _karteRepo.loadProfile();
      if (mounted) {
        setState(() {
          _meals = meals;
          _exercises = exercises;
          _weights = weights;
          _messages = messages;
          _sharedNotes = notes;
          _karteGoals = karteProfile.goals;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF111111),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customer.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            color: const Color(0xFF444444),
            tooltip: 'カルテ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerKarteScreen(
                  customerUid: widget.customer.customerUid,
                  customerName: widget.customer.displayName,
                  trainerUid: widget.trainerUid,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: const Color(0xFF444444),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '読み込みエラー\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF888888)),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'メッセージを送る',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TrainerMessageInputField(
                                onSend: (text) async {
                                  await _msgRepo.sendMessage(
                                    text: text,
                                    trainerUid: widget.trainerUid,
                                  );
                                  await _reload();
                                },
                              ),
                              if (_messages.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  '直近のメッセージ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF999999),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._messages.map((m) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: _TrainerMessageCard(message: m),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _CustomerInfoCard(customer: widget.customer),
                        const SizedBox(height: 22),
                        CustomerGoalCard(
                          goals: _karteGoals,
                          onOpenKarte: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerKarteScreen(
                                customerUid: widget.customer.customerUid,
                                customerName: widget.customer.displayName,
                                trainerUid: widget.trainerUid,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '共有ノート',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SharedNoteInputField(
                          onSave: ({required String title, required String body}) async {
                            await _noteRepo.saveNote(SharedNote(
                              title: title,
                              body: body,
                              trainerUid: widget.trainerUid,
                              createdAt: DateTime.now(),
                            ));
                            await _reload();
                          },
                        ),
                        if (_sharedNotes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ..._sharedNotes.map((n) => _SharedNoteCard(note: n)),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          '今日の食事',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_meals.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '今日の食事記録はありません',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFFAAAAAA)),
                            ),
                          )
                        else
                          ..._meals.map((m) => _MealCard(entry: m)),
                        const SizedBox(height: 22),
                        Text(
                          '今日の運動',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_exercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '今日の運動記録はありません',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFFAAAAAA)),
                            ),
                          )
                        else
                          ..._exercises.map((e) => _ExerciseCard(entry: e)),
                        const SizedBox(height: 22),
                        Text(
                          '体重推移（直近7件）',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _WeightChart(weightLogs: _weights),
                        const SizedBox(height: 10),
                        if (_weights.isNotEmpty)
                          ..._weights.map((w) => _WeightCard(entry: w)),
                      ],
                    ),
        ),
      ),
    );
  }
}

class CustomerGoalCard extends StatelessWidget {
  const CustomerGoalCard({
    super.key,
    required this.goals,
    this.onOpenKarte,
  });
  final KarteGoals goals;
  final VoidCallback? onOpenKarte;

  bool get _hasAnyGoal =>
      goals.finalGoal.isNotEmpty ||
      goals.threeMonthGoal.isNotEmpty ||
      goals.oneMonthGoal.isNotEmpty ||
      goals.goalReason.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 18, color: Color(0xFF5CB8B2)),
              const SizedBox(width: 6),
              Text(
                '目標',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF444444),
                ),
              ),
              const Spacer(),
              if (onOpenKarte != null)
                TextButton(
                  onPressed: onOpenKarte,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'カルテを開く',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          if (!_hasAnyGoal) ...[
            const SizedBox(height: 14),
            const Center(
              child: Text(
                '目標はまだ設定されていません',
                style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
              ),
            ),
            if (onOpenKarte != null) ...[
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton(
                  onPressed: onOpenKarte,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5CB8B2),
                    side: const BorderSide(color: Color(0xFF5CB8B2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('カルテで設定する'),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            if (goals.finalGoal.isNotEmpty)
              _GoalRow(label: '最終目標', value: goals.finalGoal),
            if (goals.threeMonthGoal.isNotEmpty)
              _GoalRow(label: '3ヶ月目標', value: goals.threeMonthGoal),
            if (goals.oneMonthGoal.isNotEmpty)
              _GoalRow(label: '1ヶ月目標', value: goals.oneMonthGoal),
            if (goals.goalReason.isNotEmpty)
              _GoalRow(label: '目標の理由', value: goals.goalReason),
            if (goals.eventSchedule.isNotEmpty)
              _GoalRow(label: 'イベント予定', value: goals.eventSchedule),
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
          ),
        ],
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({required this.customer});
  final CustomerLink customer;

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF4A90E2),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'UID: ${customer.customerUid}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBBBBBB),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '追加日: ${_formatDate(customer.linkedAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------
/// AddCustomerDialog
/// ----------------------------

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_uidCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('顧客を追加'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _uidCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '顧客のUID',
            hintText: '顧客IDを貼り付け、または入力してください',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'UIDを入力してください' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF222222),
          ),
          child: const Text('追加'),
        ),
      ],
    );
  }
}

/// ----------------------------
/// Screens
/// ----------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.loading,
    required this.goals,
    required this.mealLogs,
    required this.exerciseLogs,
    required this.weightLogs,
    required this.recentWeightLogs,
    required this.onRefresh,
    required this.onDeleteMeal,
    required this.onDeleteExercise,
    required this.onDeleteWeight,
    required this.selectedDate,
    required this.onPrevDay,
    required this.onNextDay,
    this.trainerMessages = const [],
  });

  final bool loading;
  final GoalSettings goals;
  final List<MealLogEntry> mealLogs;
  final List<ExerciseLogEntry> exerciseLogs;
  final List<WeightLogEntry> weightLogs;
  final List<WeightLogEntry> recentWeightLogs;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id) onDeleteMeal;
  final Future<void> Function(String id) onDeleteExercise;
  final Future<void> Function(String id) onDeleteWeight;
  final DateTime selectedDate;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final List<TrainerMessage> trainerMessages;

  int get _intake => mealLogs.fold(0, (s, m) => s + m.kcal);
  int get _burn => exerciseLogs.fold(0, (s, e) => s + e.kcal);
  double get _proteinIntake => mealLogs.fold(0.0, (s, m) => s + m.protein);
  double get _fatIntake => mealLogs.fold(0.0, (s, m) => s + m.fat);
  double get _carbIntake => mealLogs.fold(0.0, (s, m) => s + m.carb);
  DailyCalorieSummary get _summary =>
      DailyCalorieSummary(intake: _intake, burn: _burn, target: goals.targetKcal);

  WeightLogEntry? get _selectedDateWeight {
    return weightLogs.isNotEmpty ? weightLogs.first : null;
  }

  bool get _isToday {
    final today = DateTime.now();
    return selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── ヘッダー ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'からだ収支',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                    fontSize: 22,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF888888),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DateNavBar(
              selectedDate: selectedDate,
              onPrevDay: onPrevDay,
              onNextDay: onNextDay,
            ),
            const SizedBox(height: 12),

            // ── トレーナーメッセージ ──
            if (trainerMessages.isNotEmpty) ...[
              _TrainerMessageCard(message: trainerMessages.first),
              const SizedBox(height: 14),
            ],

            // ── 今日の収支カード ──
            _SummaryCard(summary: _summary),

            const SizedBox(height: 14),

            // ── PFC カード ──
            Row(
              children: [
                Expanded(
                  child: _PfcCard(
                    shortLabel: 'P',
                    label: 'たんぱく質',
                    value: _proteinIntake,
                    target: goals.proteinTarget,
                    color: const Color(0xFF5CB8B2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PfcCard(
                    shortLabel: 'C',
                    label: '炭水化物',
                    value: _carbIntake,
                    target: goals.carbTarget,
                    color: const Color(0xFFE8A838),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PfcCard(
                    shortLabel: 'F',
                    label: '脂質',
                    value: _fatIntake,
                    target: goals.fatTarget,
                    color: const Color(0xFFE27B4A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── 最近の食事 ──
            Text(
              '最近の食事',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 10),

            if (mealLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '+ ボタンから食事を記録しよう',
                  style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                ),
              )
            else
              ...mealLogs.map((m) => _MealCard(
                    entry: m,
                    onDelete: m.id != null ? () => onDeleteMeal(m.id!) : null,
                  )),

            const SizedBox(height: 22),

            // ── 最近の運動 ──
            Text(
              '最近の運動',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 10),

            if (exerciseLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '+ ボタンから運動を記録しよう',
                  style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                ),
              )
            else
              ...exerciseLogs.map((e) => _ExerciseCard(
                    entry: e,
                    onDelete:
                        e.id != null ? () => onDeleteExercise(e.id!) : null,
                  )),

            const SizedBox(height: 22),

            // ── 体重 ──
            Row(
              children: [
                Text(
                  '体重',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF444444),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _selectedDateWeight != null
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _selectedDateWeight != null
                        ? '${_isToday ? '今日' : 'この日'} ${_selectedDateWeight!.weight.toStringAsFixed(1)} kg'
                        : '${_isToday ? '今日' : 'この日の体重'} 未記録',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedDateWeight != null
                          ? const Color(0xFF388E3C)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _WeightChart(weightLogs: recentWeightLogs),

            const SizedBox(height: 10),

            if (weightLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '+ ボタンから体重を記録しよう',
                  style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                ),
              )
            else
              ...weightLogs.map((w) => _WeightCard(
                    entry: w,
                    onDelete:
                        w.id != null ? () => onDeleteWeight(w.id!) : null,
                  )),
          ],
        ),
      ),
    );
  }
}

class _DateNavBar extends StatelessWidget {
  const _DateNavBar({
    required this.selectedDate,
    required this.onPrevDay,
    required this.onNextDay,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;

  String _label() {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return '${selectedDate.month}月${selectedDate.day}日（${weekdays[selectedDate.weekday - 1]}）';
  }

  bool get _isToday {
    final today = DateTime.now();
    return selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevDay,
        ),
        Text(
          _label(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: _isToday ? Colors.grey.shade300 : null,
          ),
          onPressed: _isToday ? null : onNextDay,
        ),
      ],
    );
  }
}

// ── 収支カード ──
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final DailyCalorieSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = summary.remaining < 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日の収支',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 摂取 + 支出
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('摂取',
                      style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.intake}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                          height: 1.0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4, left: 4),
                        child: Text('kcal',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF888888))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('支出 ',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      Text(
                        '${summary.burn}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE27B4A),
                          height: 1.0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2, left: 2),
                        child: Text(' kcal',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF888888))),
                      ),
                    ],
                  ),
                ],
              ),
              // 目標・収支・残り
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatLine(
                      label: '目標', value: '${summary.target}', unit: 'kcal'),
                  const SizedBox(height: 6),
                  _StatLine(
                      label: '収支', value: '${summary.balance}', unit: 'kcal'),
                  const SizedBox(height: 6),
                  _StatLine(
                    label: '残り',
                    value: isOver
                        ? '+${-summary.remaining}'
                        : '${summary.remaining}',
                    unit: 'kcal',
                    valueColor: isOver
                        ? const Color(0xFFE24A4A)
                        : const Color(0xFF4A90E2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation(
                summary.progress >= 1.0
                    ? const Color(0xFFE24A4A)
                    : const Color(0xFF4A90E2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(summary.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor = const Color(0xFF333333),
  });
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2, left: 2),
          child: Text(
            ' $unit',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ),
      ],
    );
  }
}

// ── PFC カード ──
class _PfcCard extends StatelessWidget {
  const _PfcCard({
    required this.shortLabel,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });
  final String shortLabel;
  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value / target).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    shortLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(1)}g',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF222222),
            ),
          ),
          Text(
            '/ ${target.toStringAsFixed(0)}g',
            style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 食事ログカード ──
class _MealCard extends StatelessWidget {
  const _MealCard({required this.entry, this.onDelete});
  final MealLogEntry entry;
  final VoidCallback? onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('食事を削除'),
        content: Text('「${entry.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Color(0xFFE24A4A))),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.loggedAt.hour.toString().padLeft(2, '0')}:${entry.loggedAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.kcal} kcal',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'P${entry.protein.toStringAsFixed(0)} F${entry.fat.toStringAsFixed(0)} C${entry.carb.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFCCCCCC),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 運動ログカード ──
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.entry, this.onDelete});
  final ExerciseLogEntry entry;
  final VoidCallback? onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('運動を削除'),
        content: Text('「${entry.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除',
                style: TextStyle(color: Color(0xFFE24A4A))),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.loggedAt.hour.toString().padLeft(2, '0')}:${entry.loggedAt.minute.toString().padLeft(2, '0')}';
    final categoryLabel =
        entry.category == 'trainer_session' ? 'トレーナー' : '自主';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(timeStr,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF999999))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categoryLabel,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFE27B4A)),
                        ),
                      ),
                    ],
                  ),
                  if (entry.memo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.memo,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${entry.kcal} kcal',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE27B4A),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFCCCCCC),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 体重グラフ ──
class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.weightLogs});
  final List<WeightLogEntry> weightLogs;

  @override
  Widget build(BuildContext context) {
    if (weightLogs.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '体重を2件以上記録すると推移グラフが表示されます',
          style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
        ),
      );
    }

    // 降順 → 昇順に並べ替え
    final sorted = weightLogs.reversed.toList();
    final weights = sorted.map((e) => e.weight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final minY = minW - 1.0;
    final maxY = maxW + 1.0;

    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: const Color(0xFFF0F0F0),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFAAAAAA)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final d = sorted[i].loggedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${d.month}/${d.day}',
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFFAAAAAA)),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(1)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF388E3C),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF388E3C),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF388E3C).withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 体重ログカード ──
class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.entry, this.onDelete});
  final WeightLogEntry entry;
  final VoidCallback? onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('体重を削除'),
        content: Text(
            '${entry.weight.toStringAsFixed(1)} kg の記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除',
                style: TextStyle(color: Color(0xFFE24A4A))),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.loggedAt.hour.toString().padLeft(2, '0')}:${entry.loggedAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                color: Color(0xFF388E3C),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF999999)),
                  ),
                  if (entry.memo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.memo,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFCCCCCC),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PlanScreen extends StatefulWidget {
  const PlanScreen({
    super.key,
    required this.loading,
    required this.items,
    required this.onSave,
    required this.onTestSpeak,
  });

  final bool loading;
  final List<PlanItem> items;
  final Future<void> Function(List<PlanItem>) onSave;
  final Future<void> Function(String) onTestSpeak;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late List<PlanItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((e) => e).toList();
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = widget.items.map((e) => e).toList();
    }
  }

  void _add() {
    setState(() {
      _items.add(PlanItem(
        type: 'stretch',
        time: '12:00',
        title: '呼吸とストレッチ',
        enabled: true,
      ));
    });
  }

  void _addPreset(String type) {
    late PlanItem item;

    switch (type) {
      case 'meal':
        item = PlanItem(type: 'meal', time: '08:00', title: '食事', enabled: true);
        break;
      case 'stretch':
        item = PlanItem(
          type: 'stretch',
          time: '12:00',
          title: 'ストレッチ3分',
          enabled: true,
        );
        break;
      case 'workout':
        item = PlanItem(
          type: 'workout',
          time: '18:00',
          title: '家トレ5分',
          enabled: true,
        );
        break;
      case 'sleep':
        item = PlanItem(
          type: 'sleep',
          time: '23:30',
          title: '寝る準備',
          enabled: true,
        );
        break;
      default:
        item = PlanItem(type: 'stretch', time: '12:00', title: '予定', enabled: true);
    }

    setState(() => _items.add(item));
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _pickTime(int index) async {
    final parts = _items[index].time.split(':');
    final init = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final t = await showTimePicker(context: context, initialTime: init);
    if (t == null) return;

    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');

    setState(() {
      _items[index] = _items[index].copyWith(time: '$hh:$mm');
    });
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'meal':
        return '食事';
      case 'stretch':
        return 'ストレッチ';
      case 'workout':
        return '家トレ';
      case 'sleep':
        return '睡眠';
      default:
        return '予定';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '予定',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(onPressed: _add, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 8),

          // ★ テンプレボタン（ポケスリっぽく“すぐ押せる”）
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _addPreset('meal'),
                icon: const Icon(Icons.restaurant_outlined),
                label: const Text('食事'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addPreset('stretch'),
                icon: const Icon(Icons.self_improvement_outlined),
                label: const Text('ストレッチ'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addPreset('workout'),
                icon: const Icon(Icons.fitness_center_outlined),
                label: const Text('家トレ'),
              ),
              OutlinedButton.icon(
                onPressed: () => _addPreset('sleep'),
                icon: const Icon(Icons.nightlight_round),
                label: const Text('睡眠'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (kIsWeb)
            Text(
              '※ Web(Chrome)は通知が制限されます。音声テストは使えます。',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 12),

          if (widget.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final it = entry.value;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Text(_typeLabel(it.type)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: it.title,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                labelText: '内容',
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _items[i] = _items[i].copyWith(title: v);
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => _remove(i),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _pickTime(i),
                            child: Text(it.time),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: it.type,
                            items: const [
                              DropdownMenuItem(value: 'meal', child: Text('食事')),
                              DropdownMenuItem(
                                  value: 'stretch', child: Text('ストレッチ')),
                              DropdownMenuItem(
                                  value: 'workout', child: Text('家トレ')),
                              DropdownMenuItem(value: 'sleep', child: Text('睡眠')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _items[i] = _items[i].copyWith(type: v);
                              });
                            },
                          ),
                          const Spacer(),
                          Switch(
                            value: it.enabled,
                            onChanged: (b) {
                              setState(() {
                                _items[i] = _items[i].copyWith(enabled: b);
                              });
                            },
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final test =
                                '${_typeLabel(it.type)}：${it.title}。時間です。';
                            await widget.onTestSpeak(test);
                          },
                          icon: const Icon(Icons.volume_up_outlined),
                          label: const Text('音声テスト'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async => widget.onSave(_items),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('保存して通知をセット', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('※ 予定を変えたら保存して通知を貼り直す',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.enabled,
    required this.habitOptions,
    required this.onSubmit,
  });

  final bool enabled;
  final List<String> habitOptions;
  final Future<void> Function(String habit) onSubmit;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.habitOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'きろく',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'トレーニング以外の「食事・ストレッチ・睡眠」など、\n今日できた「小さな積み重ね」を1つだけ選んで記録しよう。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selected,
            items: widget.habitOptions
                .map((h) => DropdownMenuItem<String>(value: h, child: Text(h)))
                .toList(),
            onChanged: widget.enabled
                ? (v) => setState(() => _selected = v ?? _selected)
                : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.enabled ? () => widget.onSubmit(_selected) : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('保存する', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          if (!widget.enabled) ...[
            const SizedBox(height: 12),
            Text('今日はもう記録済みだよ。', style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// ----------------------------
/// SharedNotesScreen (顧客側「ノート」タブ)
/// ----------------------------

class SharedNotesScreen extends StatelessWidget {
  const SharedNotesScreen({
    super.key,
    required this.loading,
    required this.mealLogs,
    required this.exerciseLogs,
    required this.weightLogs,
    required this.notes,
    required this.goals,
    required this.onRefresh,
    required this.selectedDate,
    this.karteGoals = const KarteGoals(),
  });

  final bool loading;
  final List<MealLogEntry> mealLogs;
  final List<ExerciseLogEntry> exerciseLogs;
  final List<WeightLogEntry> weightLogs;
  final List<SharedNote> notes;
  final GoalSettings goals;
  final Future<void> Function() onRefresh;
  final DateTime selectedDate;
  final KarteGoals karteGoals;

  int get _intake => mealLogs.fold(0, (s, m) => s + m.kcal);
  int get _burn => exerciseLogs.fold(0, (s, e) => s + e.kcal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(
              'ノート',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111111),
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _TodaySummaryCard(
                intake: _intake,
                burn: _burn,
                selectedDate: selectedDate,
              ),
              const SizedBox(height: 22),
              CustomerGoalCard(goals: karteGoals),
              const SizedBox(height: 22),
              Text(
                '今日の食事',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 10),
              if (mealLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '食事記録はありません',
                    style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                )
              else
                ...mealLogs.map((m) => _MealCard(entry: m)),
              const SizedBox(height: 22),
              Text(
                '今日の運動',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 10),
              if (exerciseLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '運動記録はありません',
                    style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                )
              else
                ...exerciseLogs.map((e) => _ExerciseCard(entry: e)),
              const SizedBox(height: 22),
              Text(
                '今日の体重',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 10),
              if (weightLogs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '体重記録はありません',
                    style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                )
              else
                ...weightLogs.map((w) => _WeightCard(entry: w)),
              const SizedBox(height: 22),
              Text(
                'トレーナーノート',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 10),
              if (notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'トレーナーからのノートはまだありません',
                    style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  ),
                )
              else
                ...notes.map((note) => _SharedNoteCard(note: note)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SharedNoteCard extends StatelessWidget {
  const _SharedNoteCard({required this.note});
  final SharedNote note;

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 16,
                  color: Color(0xFF4A90E2),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatDate(note.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.intake,
    required this.burn,
    required this.selectedDate,
  });

  final int intake;
  final int burn;
  final DateTime selectedDate;

  bool get _isToday {
    final today = DateTime.now();
    return selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
  }

  String get _dateLabel =>
      _isToday ? '今日のまとめ' : '${selectedDate.month}/${selectedDate.day} のまとめ';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: '摂取',
                  value: intake,
                  color: const Color(0xFF5CB8B2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  label: '消費',
                  value: burn,
                  color: const Color(0xFFE27B4A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value kcal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SharedNoteInputField extends StatefulWidget {
  const SharedNoteInputField({super.key, required this.onSave});
  final Future<void> Function({required String title, required String body}) onSave;

  @override
  State<SharedNoteInputField> createState() => _SharedNoteInputFieldState();
}

class _SharedNoteInputFieldState extends State<SharedNoteInputField> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _expanded = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(title: title, body: body);
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        setState(() => _expanded = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ノートを投稿しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _expanded = true),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('ノートを追加'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A90E2),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleCtrl,
          maxLength: 50,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'タイトル',
            border: OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyCtrl,
          minLines: 3,
          maxLines: 8,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: '内容',
            border: OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _expanded = false;
                _titleCtrl.clear();
                _bodyCtrl.clear();
              }),
              child: const Text('キャンセル'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: (_titleCtrl.text.trim().isEmpty ||
                        _bodyCtrl.text.trim().isEmpty ||
                        _saving)
                    ? null
                    : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('投稿', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ----------------------------
/// CustomerKarteScreen
/// ----------------------------

class CustomerKarteScreen extends StatefulWidget {
  const CustomerKarteScreen({
    super.key,
    required this.customerUid,
    required this.customerName,
    required this.trainerUid,
  });
  final String customerUid;
  final String customerName;
  final String trainerUid;

  @override
  State<CustomerKarteScreen> createState() => _CustomerKarteScreenState();
}

class _CustomerKarteScreenState extends State<CustomerKarteScreen>
    with SingleTickerProviderStateMixin {
  late final KarteRepository _repo;
  late final TabController _tabController;
  KarteProfile _profile = const KarteProfile();
  KartePrivate _private = const KartePrivate();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _repo = KarteRepository(widget.customerUid);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final profile = await _repo.loadProfile();
      final private = await _repo.loadPrivate();
      if (mounted) {
        setState(() {
          _profile = profile;
          _private = private;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _saveProfile(KarteProfile profile) async {
    await _repo.saveProfile(profile);
    if (mounted) {
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存しました'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF5CB8B2),
        ),
      );
    }
  }

  Future<void> _savePrivate(KartePrivate private) async {
    await _repo.savePrivate(private);
    if (mounted) {
      setState(() => _private = private);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存しました'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF5CB8B2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF111111),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.customerName} のカルテ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            fontSize: 17,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5CB8B2),
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: const Color(0xFF5CB8B2),
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '基本情報'),
            Tab(text: 'ヒアリング'),
            Tab(text: 'ゴール'),
            Tab(text: 'メモ'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '読み込みエラー\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888)),
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    KarteBasicInfoTab(
                      info: _profile.basicInfo,
                      onSave: (info) => _saveProfile(KarteProfile(
                        basicInfo: info,
                        hearing: _profile.hearing,
                        goals: _profile.goals,
                      )),
                    ),
                    KarteHearingTab(
                      hearing: _profile.hearing,
                      onSave: (hearing) => _saveProfile(KarteProfile(
                        basicInfo: _profile.basicInfo,
                        hearing: hearing,
                        goals: _profile.goals,
                      )),
                    ),
                    KarteGoalsTab(
                      goals: _profile.goals,
                      onSave: (goals) => _saveProfile(KarteProfile(
                        basicInfo: _profile.basicInfo,
                        hearing: _profile.hearing,
                        goals: goals,
                      )),
                    ),
                    KarteTrainerMemoTab(
                      memo: _private,
                      onSave: _savePrivate,
                    ),
                  ],
                ),
    );
  }
}

// ── Karte ヘルパーウィジェット ──────────────────────────────────────

class _KarteField extends StatelessWidget {
  const _KarteField({
    required this.label,
    required this.controller,
    this.hint = '',
    this.keyboardType,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType:
                maxLines > 1 ? TextInputType.multiline : keyboardType,
            maxLines: maxLines,
            textInputAction: maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF5CB8B2), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KarteSectionHeader extends StatelessWidget {
  const _KarteSectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5CB8B2),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '性別',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _chip('male', '男性'),
              _chip('female', '女性'),
              _chip('other', 'その他'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String v, String label) {
    final selected = value == v;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onChanged(v),
      selectedColor: const Color(0xFFD7EFEE),
      labelStyle: TextStyle(
        color:
            selected ? const Color(0xFF5CB8B2) : const Color(0xFF666666),
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      side: BorderSide(
        color: selected
            ? const Color(0xFF5CB8B2)
            : const Color(0xFFE0E0E0),
      ),
    );
  }
}

class _KarteSaveButton extends StatelessWidget {
  const _KarteSaveButton(
      {required this.saving, required this.onPressed});
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5CB8B2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('保存する',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── KarteBasicInfoTab ──────────────────────────────────────────────

class KarteBasicInfoTab extends StatefulWidget {
  const KarteBasicInfoTab(
      {super.key, required this.info, required this.onSave});
  final KarteBasicInfo info;
  final Future<void> Function(KarteBasicInfo) onSave;

  @override
  State<KarteBasicInfoTab> createState() => _KarteBasicInfoTabState();
}

class _KarteBasicInfoTabState extends State<KarteBasicInfoTab> {
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _currentWeightCtrl;
  late final TextEditingController _targetWeightCtrl;
  late final TextEditingController _bodyFatCtrl;
  late final TextEditingController _lifestyleCtrl;
  String _gender = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.info;
    _ageCtrl = TextEditingController(text: i.age?.toString() ?? '');
    _heightCtrl = TextEditingController(text: i.height?.toString() ?? '');
    _currentWeightCtrl =
        TextEditingController(text: i.currentWeight?.toString() ?? '');
    _targetWeightCtrl =
        TextEditingController(text: i.targetWeight?.toString() ?? '');
    _bodyFatCtrl =
        TextEditingController(text: i.bodyFatPct?.toString() ?? '');
    _lifestyleCtrl = TextEditingController(text: i.lifestyleRhythm);
    _gender = i.gender;
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _lifestyleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(KarteBasicInfo(
        age: int.tryParse(_ageCtrl.text),
        gender: _gender,
        height: double.tryParse(_heightCtrl.text),
        currentWeight: double.tryParse(_currentWeightCtrl.text),
        targetWeight: double.tryParse(_targetWeightCtrl.text),
        bodyFatPct: double.tryParse(_bodyFatCtrl.text),
        lifestyleRhythm: _lifestyleCtrl.text.trim(),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _KarteSectionHeader('基本スペック'),
          _KarteField(
              label: '年齢',
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              hint: '例：25'),
          _GenderSelector(
              value: _gender,
              onChanged: (v) => setState(() => _gender = v)),
          _KarteField(
              label: '身長 (cm)',
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              hint: '例：165.0'),
          _KarteField(
              label: '現在体重 (kg)',
              controller: _currentWeightCtrl,
              keyboardType: TextInputType.number,
              hint: '例：60.0'),
          _KarteField(
              label: '目標体重 (kg)',
              controller: _targetWeightCtrl,
              keyboardType: TextInputType.number,
              hint: '例：55.0'),
          _KarteField(
              label: '体脂肪率 (%)',
              controller: _bodyFatCtrl,
              keyboardType: TextInputType.number,
              hint: '例：25.0'),
          const _KarteSectionHeader('生活習慣'),
          _KarteField(
              label: '生活リズム',
              controller: _lifestyleCtrl,
              maxLines: 3,
              hint: '例：平日9-18時勤務、週末は活動的'),
          const SizedBox(height: 8),
          _KarteSaveButton(saving: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ── KarteHearingTab ────────────────────────────────────────────────

class KarteHearingTab extends StatefulWidget {
  const KarteHearingTab(
      {super.key, required this.hearing, required this.onSave});
  final KarteHearing hearing;
  final Future<void> Function(KarteHearing) onSave;

  @override
  State<KarteHearingTab> createState() => _KarteHearingTabState();
}

class _KarteHearingTabState extends State<KarteHearingTab> {
  late final TextEditingController _referralCtrl;
  late final TextEditingController _motivationCtrl;
  late final TextEditingController _concernsCtrl;
  late final TextEditingController _dietHistoryCtrl;
  late final TextEditingController _exerciseHistoryCtrl;
  late final TextEditingController _dietChallengesCtrl;
  late final TextEditingController _medicalNotesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hearing;
    _referralCtrl = TextEditingController(text: h.referralSource);
    _motivationCtrl = TextEditingController(text: h.motivation);
    _concernsCtrl = TextEditingController(text: h.concerns);
    _dietHistoryCtrl = TextEditingController(text: h.dietHistory);
    _exerciseHistoryCtrl = TextEditingController(text: h.exerciseHistory);
    _dietChallengesCtrl = TextEditingController(text: h.dietChallenges);
    _medicalNotesCtrl = TextEditingController(text: h.medicalNotes);
  }

  @override
  void dispose() {
    _referralCtrl.dispose();
    _motivationCtrl.dispose();
    _concernsCtrl.dispose();
    _dietHistoryCtrl.dispose();
    _exerciseHistoryCtrl.dispose();
    _dietChallengesCtrl.dispose();
    _medicalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(KarteHearing(
        referralSource: _referralCtrl.text.trim(),
        motivation: _motivationCtrl.text.trim(),
        concerns: _concernsCtrl.text.trim(),
        dietHistory: _dietHistoryCtrl.text.trim(),
        exerciseHistory: _exerciseHistoryCtrl.text.trim(),
        dietChallenges: _dietChallengesCtrl.text.trim(),
        medicalNotes: _medicalNotesCtrl.text.trim(),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _KarteSectionHeader('きっかけ・動機'),
          _KarteField(
              label: 'どこから問い合わせたか',
              controller: _referralCtrl,
              hint: '例：Instagram広告、友人の紹介'),
          _KarteField(
              label: 'なぜ始めたいのか',
              controller: _motivationCtrl,
              maxLines: 3,
              hint: '例：結婚式が3ヶ月後に控えているため'),
          _KarteField(
              label: '何に悩んでいるのか',
              controller: _concernsCtrl,
              maxLines: 3,
              hint: '例：食欲が抑えられない、運動が続かない'),
          const _KarteSectionHeader('過去の経験'),
          _KarteField(
              label: '過去のダイエット歴',
              controller: _dietHistoryCtrl,
              maxLines: 3,
              hint: '例：2年前にライザップ、-8kg→リバウンド'),
          _KarteField(
              label: '運動経験',
              controller: _exerciseHistoryCtrl,
              maxLines: 3,
              hint: '例：学生時代はサッカー部、ここ5年は運動なし'),
          const _KarteSectionHeader('食事・健康'),
          _KarteField(
              label: '食事の課題',
              controller: _dietChallengesCtrl,
              maxLines: 3,
              hint: '例：外食が多い、夜遅く食べる癖がある'),
          _KarteField(
              label: '既往歴・注意事項',
              controller: _medicalNotesCtrl,
              maxLines: 3,
              hint: '例：高血圧、膝に古傷あり'),
          const SizedBox(height: 8),
          _KarteSaveButton(saving: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ── KarteGoalsTab ──────────────────────────────────────────────────

class KarteGoalsTab extends StatefulWidget {
  const KarteGoalsTab(
      {super.key, required this.goals, required this.onSave});
  final KarteGoals goals;
  final Future<void> Function(KarteGoals) onSave;

  @override
  State<KarteGoalsTab> createState() => _KarteGoalsTabState();
}

class _KarteGoalsTabState extends State<KarteGoalsTab> {
  late final TextEditingController _finalGoalCtrl;
  late final TextEditingController _threeMonthCtrl;
  late final TextEditingController _oneMonthCtrl;
  late final TextEditingController _eventCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _avoidCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goals;
    _finalGoalCtrl = TextEditingController(text: g.finalGoal);
    _threeMonthCtrl = TextEditingController(text: g.threeMonthGoal);
    _oneMonthCtrl = TextEditingController(text: g.oneMonthGoal);
    _eventCtrl = TextEditingController(text: g.eventSchedule);
    _reasonCtrl = TextEditingController(text: g.goalReason);
    _avoidCtrl = TextEditingController(text: g.avoidState);
  }

  @override
  void dispose() {
    _finalGoalCtrl.dispose();
    _threeMonthCtrl.dispose();
    _oneMonthCtrl.dispose();
    _eventCtrl.dispose();
    _reasonCtrl.dispose();
    _avoidCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(KarteGoals(
        finalGoal: _finalGoalCtrl.text.trim(),
        threeMonthGoal: _threeMonthCtrl.text.trim(),
        oneMonthGoal: _oneMonthCtrl.text.trim(),
        eventSchedule: _eventCtrl.text.trim(),
        goalReason: _reasonCtrl.text.trim(),
        avoidState: _avoidCtrl.text.trim(),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _KarteSectionHeader('目標'),
          _KarteField(
              label: '最終目標',
              controller: _finalGoalCtrl,
              maxLines: 2,
              hint: '例：ウェディングドレスを着られる体型になる'),
          _KarteField(
              label: '3ヶ月目標',
              controller: _threeMonthCtrl,
              maxLines: 2,
              hint: '例：体重 -5kg、体脂肪率 -3%'),
          _KarteField(
              label: '1ヶ月目標',
              controller: _oneMonthCtrl,
              maxLines: 2,
              hint: '例：体重 -1.5kg、食事記録を毎日つける'),
          _KarteField(
              label: '大会/イベント予定',
              controller: _eventCtrl,
              hint: '例：2026年9月 結婚式'),
          const _KarteSectionHeader('背景・制約'),
          _KarteField(
              label: '目標になった理由',
              controller: _reasonCtrl,
              maxLines: 3,
              hint: '例：毎年夏に着られる服が減っていて自信を失っていた'),
          _KarteField(
              label: '絶対に避けたい状態',
              controller: _avoidCtrl,
              maxLines: 2,
              hint: '例：急激な減量による筋肉減少、食事制限によるストレス'),
          const SizedBox(height: 8),
          _KarteSaveButton(saving: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ── KarteTrainerMemoTab ────────────────────────────────────────────

class KarteTrainerMemoTab extends StatefulWidget {
  const KarteTrainerMemoTab(
      {super.key, required this.memo, required this.onSave});
  final KartePrivate memo;
  final Future<void> Function(KartePrivate) onSave;

  @override
  State<KarteTrainerMemoTab> createState() => _KarteTrainerMemoTabState();
}

class _KarteTrainerMemoTabState extends State<KarteTrainerMemoTab> {
  late final TextEditingController _challengesCtrl;
  late final TextEditingController _cautionsCtrl;
  late final TextEditingController _nextCheckCtrl;
  late final TextEditingController _motivationCtrl;
  late final TextEditingController _coachingCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.memo;
    _challengesCtrl = TextEditingController(text: m.currentChallenges);
    _cautionsCtrl = TextEditingController(text: m.cautions);
    _nextCheckCtrl = TextEditingController(text: m.nextCheckItems);
    _motivationCtrl = TextEditingController(text: m.motivationTrend);
    _coachingCtrl = TextEditingController(text: m.coachingStyle);
  }

  @override
  void dispose() {
    _challengesCtrl.dispose();
    _cautionsCtrl.dispose();
    _nextCheckCtrl.dispose();
    _motivationCtrl.dispose();
    _coachingCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(KartePrivate(
        currentChallenges: _challengesCtrl.text.trim(),
        cautions: _cautionsCtrl.text.trim(),
        nextCheckItems: _nextCheckCtrl.text.trim(),
        motivationTrend: _motivationCtrl.text.trim(),
        coachingStyle: _coachingCtrl.text.trim(),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 14, color: Color(0xFFE67E22)),
                SizedBox(width: 6),
                Text(
                  'このタブはトレーナーのみ閲覧できます',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFE67E22)),
                ),
              ],
            ),
          ),
          const _KarteSectionHeader('現状把握'),
          _KarteField(
              label: '現在の課題',
              controller: _challengesCtrl,
              maxLines: 3,
              hint: '例：夜の食欲コントロールが難しい、筋トレのフォームが崩れやすい'),
          _KarteField(
              label: '注意点',
              controller: _cautionsCtrl,
              maxLines: 3,
              hint: '例：左膝に痛みが出やすい、急かすと続かなくなる'),
          _KarteField(
              label: '次回確認すること',
              controller: _nextCheckCtrl,
              maxLines: 3,
              hint: '例：先週の食事記録の振り返り、スクワットのフォーム確認'),
          const _KarteSectionHeader('コミュニケーション'),
          _KarteField(
              label: 'モチベーション傾向',
              controller: _motivationCtrl,
              maxLines: 3,
              hint: '例：数字で結果が出ると頑張れる、記録を褒めると嬉しそう'),
          _KarteField(
              label: '声かけ方',
              controller: _coachingCtrl,
              maxLines: 3,
              hint: '例：厳しい言い方より共感ベースで話す、具体的なアドバイスを好む'),
          const SizedBox(height: 8),
          _KarteSaveButton(saving: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

/// ----------------------------
/// RoleSelectorScreen
/// ----------------------------

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key, required this.onSelect});
  final Future<void> Function(String role) onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'からだ収支へようこそ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '利用方法を選択してください',
                style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.person_outline,
                title: 'お客さんとして使う',
                description: '食事・運動・体重を記録します',
                onTap: () => onSelect('customer'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.fitness_center_outlined,
                title: 'トレーナーとして使う',
                description: '担当顧客の記録・ノート・カルテを確認します',
                onTap: () => onSelect('trainer'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF5CB8B2), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.loading, required this.recent});

  final bool loading;
  final List<HabitEntry> recent;

  DateTime _toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...recent]..sort((a, b) => b.date.compareTo(a.date));
    final today = _toDateOnly(DateTime.now());

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'りれき（7日）',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (sorted.isEmpty)
            Text('まだ履歴がありません。', style: theme.textTheme.bodyMedium)
          else
            ...sorted.map((e) {
              final isToday = _toDateOnly(e.date) == today;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _formatDate(e.date) + (isToday ? '（今日）' : ''),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(e.habit, style: theme.textTheme.bodySmall),
              );
            }),
          const SizedBox(height: 8),
          Text('※ Firestoreに保存されるので、アプリを閉じても履歴は残るよ。',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// ----------------------------
/// ProgressScreen
/// ----------------------------

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.weekMealLogs,
    required this.weekExerciseLogs,
    required this.recentWeightLogs,
    required this.goals,
  });

  final List<MealLogEntry> weekMealLogs;
  final List<ExerciseLogEntry> weekExerciseLogs;
  final List<WeightLogEntry> recentWeightLogs;
  final GoalSettings goals;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _dateOnly(DateTime.now());
    final weekStart = _dateOnly(today.subtract(const Duration(days: 6)));
    final List<DateTime> days =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final rows = days.map((d) {
      final intake = weekMealLogs
          .where((m) => _dateOnly(m.date) == d)
          .fold(0, (s, m) => s + m.kcal);
      final burn = weekExerciseLogs
          .where((e) => _dateOnly(e.date) == d)
          .fold(0, (s, e) => s + e.kcal);
      return (date: d, intake: intake, burn: burn, balance: intake - burn);
    }).toList();

    final totalIntake = rows.fold(0, (s, r) => s + r.intake);
    final avgIntake = totalIntake ~/ 7;
    final achievedDays = rows
        .where((r) => r.intake > 0 && r.balance <= goals.targetKcal)
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            '週次進捗',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          // ── 週次サマリーカード ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryCell(
                  label: '7日摂取合計',
                  value: '$totalIntake kcal',
                ),
                _SummaryCell(
                  label: '1日平均',
                  value: '$avgIntake kcal',
                ),
                _SummaryCell(
                  label: '目標内日数',
                  value: '$achievedDays/7日',
                  color: achievedDays >= 5
                      ? const Color(0xFF388E3C)
                      : const Color(0xFF333333),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '日別カロリー',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 10),
          // ── 日別テーブルカード ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: const [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '日付',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF888888)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '摂取',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF888888)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '消費',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF888888)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '収支',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                ...rows.map((r) {
                  final isToday = r.date == today;
                  final isOver =
                      r.balance > goals.targetKcal && r.intake > 0;
                  final dateLabel = '${r.date.month}/${r.date.day}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isToday
                                  ? const Color(0xFF111111)
                                  : const Color(0xFF555555),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${r.intake}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333)),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${r.burn}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE27B4A)),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${r.balance}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isOver
                                  ? const Color(0xFFE24A4A)
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '体重推移',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 10),
          _WeightChart(weightLogs: recentWeightLogs),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    this.color = const Color(0xFF333333),
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.goals,
    required this.onSave,
    this.role = 'customer',
    this.onRoleChange,
  });

  final GoalSettings goals;
  final Future<void> Function(GoalSettings) onSave;
  final String role;
  final Future<void> Function(String)? onRoleChange;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _carbCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kcalCtrl = TextEditingController(text: '${widget.goals.targetKcal}');
    _proteinCtrl = TextEditingController(text: '${widget.goals.proteinTarget}');
    _fatCtrl = TextEditingController(text: '${widget.goals.fatTarget}');
    _carbCtrl = TextEditingController(text: '${widget.goals.carbTarget}');
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goals != widget.goals) {
      _kcalCtrl.text = '${widget.goals.targetKcal}';
      _proteinCtrl.text = '${widget.goals.proteinTarget}';
      _fatCtrl.text = '${widget.goals.fatTarget}';
      _carbCtrl.text = '${widget.goals.carbTarget}';
    }
  }

  @override
  void dispose() {
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmRoleChange() async {
    if (widget.onRoleChange == null) return;
    final newRole = widget.role == 'trainer' ? 'customer' : 'trainer';
    final newLabel = newRole == 'trainer' ? 'トレーナーモード' : 'お客さんモード';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('利用モードを切り替える'),
        content: Text('$newLabel に切り替えますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF222222)),
            child: const Text('切り替える'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onRoleChange!(newRole);
  }

  Future<void> _confirmReturnToTop() async {
    if (widget.onRoleChange == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('トップ画面に戻りますか？'),
        content: const Text(
          '現在の利用モードを未選択に戻します。記録データは削除されません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE24A4A)),
            child: const Text('戻る'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onRoleChange!('');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(GoalSettings(
        targetKcal: int.parse(_kcalCtrl.text.trim()),
        proteinTarget: double.parse(_proteinCtrl.text.trim()),
        fatTarget: double.parse(_fatCtrl.text.trim()),
        carbTarget: double.parse(_carbCtrl.text.trim()),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('目標を保存しました')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _goalField({
    required TextEditingController ctrl,
    required String label,
    required String unit,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '入力してください';
        final n = num.tryParse(v.trim());
        if (n == null || n <= 0) return '0より大きい数値を入力';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? '（取得できません）';
    } catch (_) {
      uid = '（取得できません）';
    }

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'せってい',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Text(
              '1日の目標値',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 12),
            _goalField(ctrl: _kcalCtrl, label: '目標カロリー', unit: 'kcal'),
            const SizedBox(height: 12),
            _goalField(ctrl: _proteinCtrl, label: '目標たんぱく質', unit: 'g'),
            const SizedBox(height: 12),
            _goalField(ctrl: _fatCtrl, label: '目標脂質', unit: 'g'),
            const SizedBox(height: 12),
            _goalField(ctrl: _carbCtrl, label: '目標炭水化物', unit: 'g'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '保存する',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '利用モード',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.role == 'trainer'
                              ? 'トレーナーモード'
                              : 'お客さんモード',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.role == 'trainer'
                              ? '担当顧客の記録・ノート・カルテを確認します'
                              : '食事・運動・体重を記録します',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onRoleChange != null
                        ? _confirmRoleChange
                        : null,
                    child: const Text('切り替える'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'あなたの顧客ID',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      uid,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: uid));
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('顧客IDをコピーしました')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    color: const Color(0xFF4A90E2),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'トレーナーに共有してください',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFAAAAAA),
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton(
              onPressed: widget.onRoleChange != null
                  ? _confirmReturnToTop
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE24A4A),
                side: const BorderSide(color: Color(0xFFE24A4A)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'デモ用：トップ画面に戻る',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '利用モード選択画面に戻ります',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// MealInputSheet
/// ----------------------------

class MealInputSheet extends StatefulWidget {
  const MealInputSheet({super.key, required this.date, required this.onSave});
  final DateTime date;
  final Future<void> Function(MealLogEntry) onSave;

  @override
  State<MealInputSheet> createState() => _MealInputSheetState();
}

class _MealInputSheetState extends State<MealInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  bool _saving = false;

  List<FoodSuggestion> _suggestions = [];
  FoodSuggestion? _pickedSuggestion;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbCtrl.dispose();
    super.dispose();
  }

  void _pickFoodSuggestion(FoodSuggestion s) {
    _nameCtrl.text = '${s.name} ${s.baseAmount}${s.baseUnit}';
    _kcalCtrl.text = s.kcal.toString();
    _proteinCtrl.text = s.protein.toString();
    _fatCtrl.text = s.fat.toString();
    _carbCtrl.text = s.carb.toString();
    setState(() {
      _suggestions = [];
      _pickedSuggestion = s;
    });
  }

  void _applyAmountOption(FoodSuggestion s, AmountOption opt) {
    final factor = opt.amount / s.baseAmount;
    _nameCtrl.text = '${s.name} ${opt.label}';
    _kcalCtrl.text = (s.kcal * factor).round().toString();
    _proteinCtrl.text = (s.protein * factor).toStringAsFixed(1);
    _fatCtrl.text = (s.fat * factor).toStringAsFixed(1);
    _carbCtrl.text = (s.carb * factor).toStringAsFixed(1);
    setState(() {});
  }

  Widget _buildAmountOptions() {
    final s = _pickedSuggestion;
    if (s == null || s.amountOptions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: s.amountOptions
            .map((opt) => OutlinedButton(
                  onPressed: () => _applyAmountOption(s, opt),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(opt.label, style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFoodSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return InkWell(
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : i == _suggestions.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(8))
                    : BorderRadius.zero,
            onTap: () => _pickFoodSuggestion(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: i > 0
                    ? const Border(top: BorderSide(color: Color(0xFFEEEEEE)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.name, style: const TextStyle(fontSize: 14)),
                  ),
                  Text(
                    '${s.kcal} kcal/${s.baseAmount}${s.baseUnit}  P${s.protein}  F${s.fat}  C${s.carb}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final dateOnly = DateTime(widget.date.year, widget.date.month, widget.date.day);
      final entry = MealLogEntry(
        name: _nameCtrl.text.trim(),
        kcal: int.parse(_kcalCtrl.text.trim()),
        protein: double.tryParse(_proteinCtrl.text.trim()) ?? 0.0,
        fat: double.tryParse(_fatCtrl.text.trim()) ?? 0.0,
        carb: double.tryParse(_carbCtrl.text.trim()) ?? 0.0,
        loggedAt: now,
        date: dateOnly,
      );
      await widget.onSave(entry);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _numField({
    required TextEditingController ctrl,
    required String label,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return '入力してください';
              final n = num.tryParse(v.trim());
              if (n == null || n <= 0) return '0より大きい数値を入力';
              return null;
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '食事を記録',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              onChanged: (text) => setState(() {
                _suggestions = searchFoodSuggestions(text);
                _pickedSuggestion = null;
              }),
              decoration: const InputDecoration(
                labelText: '食事名（例：朝食、ランチ）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '食事名を入力してください' : null,
            ),
            _buildFoodSuggestions(),
            _buildAmountOptions(),
            const SizedBox(height: 12),
            _numField(ctrl: _kcalCtrl, label: 'カロリー (kcal)※参考値', required: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child:
                        _numField(ctrl: _proteinCtrl, label: 'たんぱく質 (g)')),
                const SizedBox(width: 8),
                Expanded(child: _numField(ctrl: _fatCtrl, label: '脂質 (g)')),
                const SizedBox(width: 8),
                Expanded(
                    child: _numField(ctrl: _carbCtrl, label: '炭水化物 (g)')),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '保存する',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// ExerciseInputSheet
/// ----------------------------

class ExerciseInputSheet extends StatefulWidget {
  const ExerciseInputSheet({super.key, required this.date, required this.onSave});
  final DateTime date;
  final Future<void> Function(ExerciseLogEntry) onSave;

  @override
  State<ExerciseInputSheet> createState() => _ExerciseInputSheetState();
}

class _ExerciseInputSheetState extends State<ExerciseInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  String _category = 'self';
  bool _saving = false;

  List<ExerciseSuggestion> _suggestions = [];
  ExerciseSuggestion? _pickedSuggestion;
  bool _showStrengthInputs = false;

  @override
  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _setsCtrl.dispose();
    _kcalCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _recalcKcal() {
    final s = _pickedSuggestion;
    if (s == null || !s.isStrengthTraining) return;
    final weight = double.tryParse(_weightCtrl.text.trim());
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 10;
    final sets = int.tryParse(_setsCtrl.text.trim()) ?? 3;
    final base = calcEstimatedKcal(s, weight);
    _kcalCtrl.text = (base * reps / 10 * sets / 3).round().toString();
  }

  void _pickExerciseSuggestion(ExerciseSuggestion s) {
    _nameCtrl.text = s.name;
    _kcalCtrl.text = s.referenceKcal.toString();
    _weightCtrl.clear();
    if (s.isStrengthTraining) {
      _repsCtrl.text = '10';
      _setsCtrl.text = '3';
    } else {
      _repsCtrl.clear();
      _setsCtrl.clear();
    }
    setState(() {
      _category = s.category;
      _pickedSuggestion = s;
      _showStrengthInputs = s.isStrengthTraining;
      _suggestions = [];
    });
  }

  Widget _buildExerciseSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return InkWell(
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(8))
                : i == _suggestions.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(8))
                    : BorderRadius.zero,
            onTap: () => _pickExerciseSuggestion(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: i > 0
                    ? const Border(top: BorderSide(color: Color(0xFFEEEEEE)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.name, style: const TextStyle(fontSize: 14)),
                  ),
                  Text(
                    '参考 ${s.referenceKcal} kcal',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStrengthInputs() {
    if (!_showStrengthInputs) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextFormField(
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _recalcKcal(),
          decoration: const InputDecoration(
            labelText: '重量 kg',
            hintText: '例：60',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _repsCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => _recalcKcal(),
          decoration: const InputDecoration(
            labelText: '回数',
            hintText: '例：10',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'セット数',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ...List.generate(5, (i) {
              final n = i + 1;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: OutlinedButton(
                  onPressed: () {
                    _setsCtrl.text = n.toString();
                    _recalcKcal();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('$n', style: const TextStyle(fontSize: 13)),
                ),
              );
            }),
            const SizedBox(width: 4),
            Expanded(
              child: TextFormField(
                controller: _setsCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _recalcKcal(),
                decoration: const InputDecoration(
                  labelText: 'セット数',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final dateOnly = DateTime(widget.date.year, widget.date.month, widget.date.day);
      final entry = ExerciseLogEntry(
        name: _nameCtrl.text.trim(),
        kcal: int.parse(_kcalCtrl.text.trim()),
        category: _category,
        memo: _memoCtrl.text.trim(),
        loggedAt: now,
        date: dateOnly,
        createdByRole: 'customer',
      );
      await widget.onSave(entry);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '運動を記録',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              onChanged: (text) => setState(() {
                _suggestions = searchExerciseSuggestions(text);
                _pickedSuggestion = null;
                _showStrengthInputs = false;
              }),
              decoration: const InputDecoration(
                labelText: '運動名（例：ウォーキング、筋トレ）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '運動名を入力してください' : null,
            ),
            _buildExerciseSuggestions(),
            _buildStrengthInputs(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kcalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '推定消費カロリー (kcal)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '入力してください';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return '0より大きい整数を入力';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('種別',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('自主運動'),
                  selected: _category == 'self',
                  onSelected: (_) => setState(() => _category = 'self'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('トレーナー'),
                  selected: _category == 'trainer_session',
                  onSelected: (_) =>
                      setState(() => _category = 'trainer_session'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE27B4A),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '保存する',
                          style:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// WeightInputSheet
/// ----------------------------

class WeightInputSheet extends StatefulWidget {
  const WeightInputSheet({super.key, required this.date, required this.onSave});
  final DateTime date;
  final Future<void> Function(WeightLogEntry) onSave;

  @override
  State<WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<WeightInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final dateOnly = DateTime(widget.date.year, widget.date.month, widget.date.day);
      final entry = WeightLogEntry(
        weight: double.parse(_weightCtrl.text.trim()),
        memo: _memoCtrl.text.trim(),
        loggedAt: now,
        date: dateOnly,
        createdByRole: 'customer',
      );
      await widget.onSave(entry);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '体重を記録',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '体重 (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '体重を入力してください';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return '0より大きい数値を入力してください';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoCtrl,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '保存する',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// TrainerMessageInputField
/// ----------------------------

class TrainerMessageInputField extends StatefulWidget {
  const TrainerMessageInputField({super.key, required this.onSend});
  final Future<void> Function(String text) onSend;

  @override
  State<TrainerMessageInputField> createState() =>
      _TrainerMessageInputFieldState();
}

class _TrainerMessageInputFieldState extends State<TrainerMessageInputField> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _ctrl.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メッセージを送信しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          minLines: 1,
          maxLines: 3,
          maxLength: 200,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'ひとこと送る',
            border: OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: (_ctrl.text.trim().isEmpty || _sending) ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
          ),
          child: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('送信', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// ----------------------------
/// _TrainerMessageCard
/// ----------------------------

class _TrainerMessageCard extends StatelessWidget {
  const _TrainerMessageCard({required this.message});
  final TrainerMessage message;

  String _formatTime(DateTime dt) =>
      '${dt.month}/${dt.day} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF4A90E2), width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'トレーナーより',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A90E2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF222222),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatTime(message.createdAt),
              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }
}


