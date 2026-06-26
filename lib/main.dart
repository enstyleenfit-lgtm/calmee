import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Web判定
import 'package:flutter/foundation.dart';

// 通知 + TTS + timezone
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'firebase_options.dart';

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
  final int target;

  const DailyCalorieSummary({required this.intake, required this.target});

  int get remaining => target - intake;
  double get progress => (intake / target).clamp(0.0, 1.0);
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
          lastDone = toDateOnly(lastDone!);
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
    if (overlay == null) return;

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
        builder: (_, __) {
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

  int _index = 0;

  // 共有データ
  List<HabitEntry> _recent = [];
  TodayStatus _today =
      TodayStatus(doneToday: false, todayEntry: null, streak: 0);
  List<PlanItem> _planItems = [];

  final List<String> habitOptions = const [
    '食事：バランスを意識した',
    'ストレッチ：身体をほぐした',
    '睡眠：早めに寝る準備をした',
    'メンタル：深呼吸・瞑想をした',
    'その他：自分をいたわる行動をした',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      await _ensureSignedIn();
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

  HabitRepository get _habitRepo => HabitRepository(_uid!);
  PlanRepository get _planRepo => PlanRepository(_uid!);

  DateTime _toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calcStreakFromRecent(List<HabitEntry> recent) {
    if (recent.isEmpty) return 0;

    final dates = recent.map((e) => _toDateOnly(e.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final today = _toDateOnly(DateTime.now());
    int streak = 0;
    DateTime cursor = today;

    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _reloadAll() async {
    if (_uid == null) return;

    final recent = await _habitRepo.loadRecent(limit: 7);
    final today = _toDateOnly(DateTime.now());

    final todayEntry = recent.firstWhere(
      (e) => _toDateOnly(e.date) == today,
      orElse: () => HabitEntry(
        date: DateTime.fromMillisecondsSinceEpoch(0),
        habit: '',
      ),
    );

    final doneToday = todayEntry.date.millisecondsSinceEpoch != 0;
    final streak = _calcStreakFromRecent(recent);
    final plan = await _planRepo.loadToday();

    setState(() {
      _recent = recent;
      _today = TodayStatus(
        doneToday: doneToday,
        todayEntry: doneToday ? todayEntry : null,
        streak: streak,
      );
      _planItems = plan;
    });
  }

  /// 今日記録 → Firestoreで正確streak更新 → reload → newStreak返す
  Future<int> _recordToday(String habit) async {
    if (_uid == null) return 0;

    await _habitRepo.saveToday(habit: habit);
    final newStreak = await _habitRepo.updateStreakOnCompleteToday();
    await _reloadAll();
    return newStreak;
  }

  Future<void> _savePlan(List<PlanItem> items) async {
    if (_uid == null) return;

    await _planRepo.saveToday(items);
    await NotiTtsService.instance.scheduleTodayPlan(items);
    await _reloadAll();
  }

  void _clearNotiPayload() {
    NotiTtsService.instance.lastPayload = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        loading: _loading,
        onRefresh: () async {
          setState(() => _loading = true);
          await _reloadAll();
          if (mounted) setState(() => _loading = false);
        },
      ),
      HistoryScreen(
        loading: _loading,
        recent: _recent,
      ),
      RecordScreen(
        enabled: !_today.doneToday,
        habitOptions: habitOptions,
        onSubmit: (habit) async {
          setState(() => _loading = true);
          try {
            final newStreak = await _recordToday(habit);
            await RewardSparkle.play(context);
            await showPraiseRewardDialog(context, streak: newStreak);
            setState(() => _index = 0);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: screens[_index],
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('食事を記録 → 近日実装')),
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
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: '記録',
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
/// Screens
/// ----------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.loading,
    required this.onRefresh,
  });

  final bool loading;
  final Future<void> Function() onRefresh;

  static const _summary = DailyCalorieSummary(intake: 1340, target: 2000);
  static const _proteinIntake = 68.0;
  static const _fatIntake = 41.0;
  static const _carbIntake = 173.0;
  static const _proteinTarget = 120.0;
  static const _fatTarget = 55.0;
  static const _carbTarget = 250.0;
  static const _meals = [
    MealLog(name: '朝食', kcal: 480, protein: 22.0, fat: 15.0, carb: 60.0, time: '07:30'),
    MealLog(name: 'ランチ', kcal: 620, protein: 30.0, fat: 18.0, carb: 75.0, time: '12:15'),
    MealLog(name: 'おやつ', kcal: 240, protein: 5.0, fat: 8.0, carb: 38.0, time: '15:00'),
  ];

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return '${now.month}月${now.day}日（${weekdays[now.weekday - 1]}）';
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'からだ収支',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111111),
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _todayLabel(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
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

            const SizedBox(height: 20),

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
                    target: _proteinTarget,
                    color: const Color(0xFF5CB8B2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PfcCard(
                    shortLabel: 'C',
                    label: '炭水化物',
                    value: _carbIntake,
                    target: _carbTarget,
                    color: const Color(0xFFE8A838),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PfcCard(
                    shortLabel: 'F',
                    label: '脂質',
                    value: _fatIntake,
                    target: _fatTarget,
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

            ..._meals.map((m) => _MealCard(meal: m)),
          ],
        ),
      ),
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
              // 摂取（大きく）
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '摂取',
                    style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.intake}',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                          height: 1.0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5, left: 4),
                        child: Text(
                          'kcal',
                          style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // 目標・残り
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatLine(label: '目標', value: '${summary.target}', unit: 'kcal'),
                  const SizedBox(height: 10),
                  _StatLine(
                    label: '残り',
                    value: isOver
                        ? '+${-summary.remaining}'
                        : '${summary.remaining}',
                    unit: 'kcal',
                    valueColor:
                        isOver ? const Color(0xFFE24A4A) : const Color(0xFF4A90E2),
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
  const _MealCard({required this.meal});
  final MealLog meal;

  @override
  Widget build(BuildContext context) {
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
                    meal.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.time,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.kcal} kcal',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'P${meal.protein.toStringAsFixed(0)} F${meal.fat.toStringAsFixed(0)} C${meal.carb.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
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
            value: _selected,
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'せってい',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ここは後で拡張（例：通知、テーマ、音声）'),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------
/// Widgets
/// ----------------------------

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text('$label $value', style: theme.textTheme.labelMedium),
      ),
    );
  }
}

