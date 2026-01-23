import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Web判定
import 'package:flutter/foundation.dart';

// 画像選択
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;

// 通知 + TTS + timezone
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'firebase_options.dart';
import 'screens/home_page.dart';
import 'screens/camera_page.dart';
import 'screens/progress_page.dart';
import 'screens/groups_page.dart';
import 'screens/compare_page.dart';
import 'screens/meal_detail_sheet.dart';
import 'widgets/centered_content.dart';

// 【デバッグ】UI切り分け用フラグ
// debugGallery=true のとき：UIギャラリー画面を表示（全画面へ遷移可能）
// debugUseNewHome=true のとき：起動直後に新Home UI（`HomePage`）を直接表示
// 両方false のとき：今まで通り `RootShell` から始まる挙動
const bool debugGallery = true; // ギャラリー画面で全UI確認用
const bool debugUseNewHome = false; // 個別確認用（debugGallery優先）

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 匿名ログインしてuidを取得
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
  final uid = auth.currentUser!.uid;

  // エミュレータを使用する場合（開発環境のみ）
  if (kDebugMode) {
    try {
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    } catch (e) {
      // エミュレータが起動していない場合は無視
      print('Functions emulator not available: $e');
    }
  }

  // Repositoryを生成
  final habitRepo = HabitRepository(uid);
  final planRepo = PlanRepository(uid);
  final weightRepo = WeightRepository(uid);
  final profileRepo = ProfileRepository(uid);

  runApp(CalmeeApp(
    habitRepo: habitRepo,
    planRepo: planRepo,
    weightRepo: weightRepo,
    profileRepo: profileRepo,
  ));
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
  final int? kcal; // カロリー（オプショナル）
  final int? protein; // タンパク質（オプショナル）
  final String? mealState; // 食事の状態（しっかり/ちょうど/軽め）

  PlanItem({
    required this.type,
    required this.time,
    required this.title,
    required this.enabled,
    this.kcal,
    this.protein,
    this.mealState,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'time': time,
        'title': title,
        'enabled': enabled,
        if (kcal != null) 'kcal': kcal,
        if (protein != null) 'protein': protein,
        if (mealState != null) 'mealState': mealState,
      };

  static PlanItem fromMap(Map<String, dynamic> m) => PlanItem(
        type: (m['type'] as String?) ?? 'meal',
        time: (m['time'] as String?) ?? '08:00',
        title: (m['title'] as String?) ?? '',
        enabled: (m['enabled'] as bool?) ?? true,
        kcal: (m['kcal'] as num?)?.toInt(),
        protein: (m['protein'] as num?)?.toInt(),
        mealState: m['mealState'] as String?,
      );

  PlanItem copyWith({
    String? type,
    String? time,
    String? title,
    bool? enabled,
    int? kcal,
    int? protein,
    String? mealState,
  }) {
    return PlanItem(
      type: type ?? this.type,
      time: time ?? this.time,
      title: title ?? this.title,
      enabled: enabled ?? this.enabled,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      mealState: mealState ?? this.mealState,
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
        'Calmee：${it.title}',
        'タップして音声でサポートします',
        tz.TZDateTime.from(when, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'calmee_plan',
            'Calmee Plan',
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

  /// 過去7日のデータを取得（日付とPlanItemのリストのマップ）
  Future<Map<DateTime, List<PlanItem>>> loadLast7Days() async {
    final now = DateTime.now();
    final Map<DateTime, List<PlanItem>> result = {};

    for (int i = 0; i < 7; i++) {
      final date = _dateOnly(now.subtract(Duration(days: i)));
      final doc = await _ref.doc(_docId(date)).get();
      final data = doc.data();

      if (data != null) {
        final raw = (data['items'] as List?) ?? [];
        result[date] = raw
            .map((e) => PlanItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        result[date] = [];
      }
    }

    return result;
  }
}

class WeightRepository {
  WeightRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('weights');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _docId(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// 今日の体重を取得（なければnull）
  Future<double?> loadToday() async {
    final today = _dateOnly(DateTime.now());
    final doc = await _ref.doc(_docId(today)).get();
    final data = doc.data();
    if (data == null) return null;

    final weight = data['weight'] as num?;
    return weight?.toDouble();
  }

  /// 今日の体重を保存（上書き）
  Future<void> saveToday({required double weight}) async {
    final today = _dateOnly(DateTime.now());
    await _ref.doc(_docId(today)).set({
      'date': Timestamp.fromDate(today),
      'weight': weight,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class ProfileRepository {
  ProfileRepository(this.uid);
  final String uid;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('profile').doc('main');

  Future<Map<String, dynamic>?> load() async {
    final snap = await _ref.get();
    return snap.data();
  }

  Future<void> save({
    double? heightCm,
    double? weightKg,
    double? bodyFatPct,
    double? targetWeightKg,
    int? targetDays,
    String? policyText,
    String? fitType,
    String? fitAxis,
  }) async {
    await _ref.set({
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (bodyFatPct != null) 'bodyFatPct': bodyFatPct,
      if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
      if (targetDays != null) 'targetDays': targetDays,
      if (policyText != null) 'policyText': policyText,
      if (fitType != null) 'fitType': fitType,
      if (fitAxis != null) 'fitAxis': fitAxis,
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

/// 【デバッグ】UIギャラリー画面（プレビューモード対応）
class _DebugGalleryPage extends StatefulWidget {
  const _DebugGalleryPage();

  @override
  State<_DebugGalleryPage> createState() => _DebugGalleryPageState();
}

class _DebugGalleryPageState extends State<_DebugGalleryPage> {
  // モード切替：false=一覧モード（リスト遷移）、true=プレビューモード（同一画面表示）
  bool _isPreviewMode = true;
  
  // 選択中のページ（プレビューモード用）
  _GalleryPageType _selectedPage = _GalleryPageType.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('UIギャラリー（デバッグ）'),
        backgroundColor: Colors.white,
        actions: [
          // モード切替トグル
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('一覧'),
                  icon: Icon(Icons.list, size: 18),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('プレビュー'),
                  icon: Icon(Icons.preview, size: 18),
                ),
              ],
              selected: {_isPreviewMode},
              onSelectionChanged: (Set<bool> selected) {
                setState(() {
                  _isPreviewMode = selected.first;
                });
              },
            ),
          ),
        ],
      ),
      body: _isPreviewMode ? _buildPreviewMode() : _buildListMode(),
    );
  }

  /// プレビューモード（同一画面に表示）
  Widget _buildPreviewMode() {
    return Column(
      children: [
        // 上部：ページ選択セグメント
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_GalleryPageType>(
              segments: [
                const ButtonSegment<_GalleryPageType>(
                  value: _GalleryPageType.home,
                  label: Text('ホーム'),
                  icon: Icon(Icons.home, size: 18),
                ),
                const ButtonSegment<_GalleryPageType>(
                  value: _GalleryPageType.camera,
                  label: Text('カメラ'),
                  icon: Icon(Icons.camera_alt, size: 18),
                ),
                const ButtonSegment<_GalleryPageType>(
                  value: _GalleryPageType.progress,
                  label: Text('進捗'),
                  icon: Icon(Icons.trending_up, size: 18),
                ),
                const ButtonSegment<_GalleryPageType>(
                  value: _GalleryPageType.groups,
                  label: Text('グループ'),
                  icon: Icon(Icons.group, size: 18),
                ),
                const ButtonSegment<_GalleryPageType>(
                  value: _GalleryPageType.compare,
                  label: Text('比較'),
                  icon: Icon(Icons.compare, size: 18),
                ),
                const ButtonSegment<_GalleryPageType>(
                  value: _GalleryPageType.sheet,
                  label: Text('シート'),
                  icon: Icon(Icons.restaurant_menu, size: 18),
                ),
              ],
              selected: {_selectedPage},
              onSelectionChanged: (Set<_GalleryPageType> selected) {
                setState(() {
                  _selectedPage = selected.first;
                });
              },
            ),
          ),
        ),
        
        // 下部：選択中のページをプレビュー表示
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRect(
              child: CenteredContent(
                scroll: false, // 各ページが既にスクロールを持つため
                padding: EdgeInsets.zero, // 各ページが既にpaddingを持つため
                child: _buildPreviewContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// プレビューコンテンツ（選択されたページを返す）
  Widget _buildPreviewContent() {
    switch (_selectedPage) {
      case _GalleryPageType.home:
        return const HomePage();
      case _GalleryPageType.camera:
        return const CameraPage();
      case _GalleryPageType.progress:
        return const ProgressPage();
      case _GalleryPageType.groups:
        return const GroupsPage();
      case _GalleryPageType.compare:
        return const ComparePage();
      case _GalleryPageType.sheet:
        // MealDetailSheetは埋め込みが難しいため、ボタンで表示
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 64, color: Color(0xFF9A9AA5)),
              const SizedBox(height: 16),
              const Text(
                '食事詳細シート',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ボトムシート形式のため、\n「表示」ボタンから開いてください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9A9AA5),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  MealDetailSheet.show(context);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('表示'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );
    }
  }

  /// 一覧モード（リスト遷移）
  Widget _buildListMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGalleryButton(
          context: context,
            title: 'ホーム',
            subtitle: '新Home',
          icon: Icons.home,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGalleryButton(
          context: context,
            title: 'カメラ',
            subtitle: '撮影UI',
          icon: Icons.camera_alt,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGalleryButton(
          context: context,
            title: '進捗',
            subtitle: 'ダッシュボード',
          icon: Icons.trending_up,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGalleryButton(
          context: context,
            title: 'グループ',
            subtitle: 'フィード',
          icon: Icons.group,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupsPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGalleryButton(
          context: context,
            title: '比較',
            subtitle: 'ビフォー/アフター',
          icon: Icons.compare,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComparePage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGalleryButton(
          context: context,
            title: '食事詳細',
            subtitle: 'ボトムシート',
          icon: Icons.restaurant_menu,
          color: Colors.red,
          onTap: () {
            MealDetailSheet.show(context);
          },
        ),
      ],
    );
  }

  Widget _buildGalleryButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9E9EF), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9A9AA5),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9A9AA5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ギャラリーページタイプ（プレビュー用）
enum _GalleryPageType {
  home,
  camera,
  progress,
  groups,
  compare,
  sheet,
}

class CalmeeApp extends StatelessWidget {
  const CalmeeApp({
    super.key,
    required this.habitRepo,
    required this.planRepo,
    required this.weightRepo,
    required this.profileRepo,
  });

  final HabitRepository habitRepo;
  final PlanRepository planRepo;
  final WeightRepository weightRepo;
  final ProfileRepository profileRepo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calmee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        useMaterial3: true,
      ),
      home: debugGallery
          ? const _DebugGalleryPage() // ギャラリー画面（全UI確認用）
          : debugUseNewHome
              ? const HomePage() // 新UI確認用（デバッグ）
              : RootShell(
                  habitRepo: habitRepo,
                  planRepo: planRepo,
                  weightRepo: weightRepo,
                  profileRepo: profileRepo,
                ),
    );
  }
}

/// ポケスリっぽい「下部タブのシェル」
class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.habitRepo,
    required this.planRepo,
    required this.weightRepo,
    required this.profileRepo,
  });

  final HabitRepository habitRepo;
  final PlanRepository planRepo;
  final WeightRepository weightRepo;
  final ProfileRepository profileRepo;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  bool _loading = true;

  int _index = 0;

  // 共有データ
  TodayStatus _today =
      TodayStatus(doneToday: false, todayEntry: null, streak: 0);
  List<PlanItem> _planItems = [];
  Map<DateTime, List<PlanItem>> _last7DaysPlans = {};

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
      await NotiTtsService.instance.init();
      await _reloadAll();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    final recent = await widget.habitRepo.loadRecent(limit: 7);
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
    final plan = await widget.planRepo.loadToday();
    final last7Days = await widget.planRepo.loadLast7Days();

    setState(() {
      _today = TodayStatus(
        doneToday: doneToday,
        todayEntry: doneToday ? todayEntry : null,
        streak: streak,
      );
      _planItems = plan;
      _last7DaysPlans = last7Days;
    });
  }

  /// 今日記録 → Firestoreで正確streak更新 → reload → newStreak返す
  Future<int> _recordToday(String habit) async {
    await widget.habitRepo.saveToday(habit: habit);
    final newStreak = await widget.habitRepo.updateStreakOnCompleteToday();
    await _reloadAll();
    return newStreak;
  }

  Future<void> _savePlan(List<PlanItem> items) async {
    await widget.planRepo.saveToday(items);
    await NotiTtsService.instance.scheduleTodayPlan(items);
    await _reloadAll();
  }

  void _clearNotiPayload() {
    NotiTtsService.instance.lastPayload = null;
    setState(() {});
  }

  /// リワードとダイアログを表示（context使用をState内に閉じ込める）
  Future<void> _handleRewardAndDialog(int streak) async {
    if (!mounted) return;
    await RewardSparkle.play(context);
    if (!mounted) return;
    await showPraiseRewardDialog(context, streak: streak);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        loading: _loading,
        today: _today,
        planItems: _planItems,
        last7DaysPlans: _last7DaysPlans,
        profileRepo: widget.profileRepo,
        lastNotiPayload: NotiTtsService.instance.lastPayload,
        onClearNoti: _clearNotiPayload,
        onRefresh: () async {
          setState(() => _loading = true);
          await _reloadAll();
          if (mounted) setState(() => _loading = false);
        },
        onGoPlan: () => setState(() => _index = 1),
        onGoRecord: () => setState(() => _index = 2),
        onSavePlan: (items) async {
          setState(() => _loading = true);
          try {
            await _savePlan(items);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
      PlanScreen(
        loading: _loading,
        items: _planItems,
        onSave: (items) async {
          setState(() => _loading = true);
          try {
            await _savePlan(items);
            setState(() => _index = 0);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        onTestSpeak: (text) async {
          await NotiTtsService.instance.speak(text);
        },
      ),
      RecordScreen(
        enabled: !_today.doneToday,
        habitOptions: habitOptions,
        last7DaysPlans: _last7DaysPlans,
        planItems: _planItems,
        onAddMeal: () {
          // RecordScreen内でダイアログを開くため、ここでは何もしない
        },
        onAddWorkout: () {
          // RecordScreen内でダイアログを開くため、ここでは何もしない
        },
        onSavePlan: (items) async {
          setState(() => _loading = true);
          try {
            await _savePlan(items);
            setState(() => _index = 2);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
        onSubmit: (habit) async {
          setState(() => _loading = true);
          try {
            final newStreak = await _recordToday(habit);
            if (!mounted) return;
            await _handleRewardAndDialog(newStreak);
            if (!mounted) return;
            setState(() => _index = 0);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
      ProfileScreen(
        profileRepo: widget.profileRepo,
      ),
      SettingsScreen(
        weightRepo: widget.weightRepo,
      ),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: '予定',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: '記録',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'My Page',
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
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.loading,
    required this.today,
    required this.planItems,
    required this.last7DaysPlans,
    required this.profileRepo,
    required this.lastNotiPayload,
    required this.onClearNoti,
    required this.onRefresh,
    required this.onGoPlan,
    required this.onGoRecord,
    required this.onSavePlan,
  });

  final bool loading;
  final TodayStatus today;
  final List<PlanItem> planItems;
  final Map<DateTime, List<PlanItem>> last7DaysPlans;
  final ProfileRepository profileRepo;

  final String? lastNotiPayload;
  final VoidCallback onClearNoti;

  final Future<void> Function() onRefresh;
  final VoidCallback onGoPlan;
  final VoidCallback onGoRecord;
  final Future<void> Function(List<PlanItem>) onSavePlan;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fitType;
  bool _fitTypeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFitType();
  }

  Future<void> _loadFitType() async {
    try {
      final data = await widget.profileRepo.load();
      if (mounted) {
        setState(() {
          _fitType = data?['fitType'] as String?;
          _fitTypeLoaded = true;
        });
      }
    } catch (e) {
      // エラーは無視（デフォルト値で続行）
      if (mounted) {
        setState(() => _fitTypeLoaded = true);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が表示されるたびにfitTypeを再読み込み（診断結果保存後に対応）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFitType();
    });
  }

  static const Map<String, String> fitTypeGuide = {
    'ISTJ': '今日やることを1つ決めて、淡々と進めよう。',
    'ISFJ': '無理しなくていい。できる分だけで十分。',
    'INFJ': '今日の行動が、少し先の自分を整える。',
    'INTJ': '最短の一手を選べば、それでいい。',
    'ISTP': 'まず動いて、あとで整えればいい。',
    'ISFP': '心地いいペースを大事にしよう。',
    'INFP': '小さくても、続けた事実は残る。',
    'INTP': '考えすぎたら、まず1回だけやってみよう。',
    'ESTP': '今できることを、さっと終わらせよう。',
    'ESFP': '楽しめる形に変えて続けよう。',
    'ENFP': '全部やらなくていい。1つで十分。',
    'ENTP': '今日は試す日。正解はあとでいい。',
    'ESTJ': '決めたことを1つ、確実に。',
    'ESFJ': '自分を気にかける時間も大切に。',
    'ENFJ': '今日の一歩は、ちゃんと意味がある。',
    'ENTJ': '前に進んでいる。それだけでOK。',
  };

  static const String defaultGuide = '今日できることを、ひとつだけ。';

  String get _guideText {
    if (!_fitTypeLoaded) return defaultGuide;
    if (_fitType == null || _fitType!.isEmpty || _fitType == '未診断') {
      return defaultGuide;
    }
    return fitTypeGuide[_fitType!] ?? defaultGuide;
  }

  PlanItem? _nextPlan(List<PlanItem> items) {
    if (items.isEmpty) return null;
    
    final now = DateTime.now();
    DateTime? bestAt;
    PlanItem? best;

    for (final it in items.where((e) => e.enabled)) {
      final parts = it.time.split(':');
      final hh = int.tryParse(parts[0]) ?? 0;
      final mm = int.tryParse(parts[1]) ?? 0;
      final t = DateTime(now.year, now.month, now.day, hh, mm);

      if (t.isAfter(now) && (bestAt == null || t.isBefore(bestAt))) {
        bestAt = t;
        best = it;
      }
    }
    return best;
  }

  int _countRemainingPlans(List<PlanItem> items) {
    if (items.isEmpty) return 0;
    
    final now = DateTime.now();
    int count = 0;

    for (final it in items.where((e) => e.enabled)) {
      final parts = it.time.split(':');
      final hh = int.tryParse(parts[0]) ?? 0;
      final mm = int.tryParse(parts[1]) ?? 0;
      final t = DateTime(now.year, now.month, now.day, hh, mm);

      if (t.isAfter(now)) {
        count++;
      }
    }
    return count;
  }

  String _buildTodayStateText(List<PlanItem> todayItems) {
    final mealItems = todayItems.where((item) => item.type == 'meal').toList();
    
    if (mealItems.isEmpty) {
      return 'まだ食事を記録していません。';
    }

    // 状態別の集計
    final stateCounts = <String, int>{};
    for (final item in mealItems) {
      if (item.mealState != null) {
        stateCounts[item.mealState!] = (stateCounts[item.mealState!] ?? 0) + 1;
      }
    }

    if (stateCounts.isEmpty) {
      // 状態選択がない場合は、カロリーから判定
      final totalKcal = mealItems.fold<int>(0, (sum, item) => sum + (item.kcal ?? 0));
      if (totalKcal >= 2000) {
        return 'しっかり食べています。';
      } else if (totalKcal >= 1200) {
        return 'ちょうどいい感じです。';
      } else {
        return '軽めに進めています。';
      }
    }

    // 状態選択がある場合
    final states = stateCounts.keys.toList();
    if (states.length == 1) {
      final state = states[0];
      final count = stateCounts[state]!;
      if (count == 1) {
        return '$state食べました。';
      } else {
        return '$stateを${count}回食べました。';
      }
    } else {
      // 複数の状態がある場合
      final stateTexts = states.map((state) {
        final count = stateCounts[state]!;
        return count == 1 ? state : '$state${count}回';
      }).join('、');
      return '$stateTextsを食べました。';
    }
  }

  String _buildSummaryText(int mealKcal, int mealTarget, int workoutKcal, int workoutTarget, int proteinCurrent, int proteinTarget, int remainingCount) {
    final mealProgress = mealKcal >= mealTarget ? '目標達成' : 'あと${mealTarget - mealKcal}kcal';
    final workoutProgress = workoutKcal >= workoutTarget ? '目標達成' : 'あと${workoutTarget - workoutKcal}kcal';
    final proteinProgress = proteinCurrent >= proteinTarget ? '目標達成' : 'あと${proteinTarget - proteinCurrent}g';
    
    return '摂取カロリーは$mealProgress。消費カロリーは$workoutProgress。たんぱく質は$proteinProgress。残り予定は${remainingCount}件です。';
  }

  /// Firebase Storageへ画像をアップロード
  Future<String> _uploadImageToStorage(XFile image) async {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid ?? 'anonymous';
    final storage = FirebaseStorage.instance;
    
    // ファイル名を生成（タイムスタンプ + ランダム）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'meal_images/$uid/${timestamp}_${image.name}';
    
    // アップロード
    final ref = storage.ref().child(fileName);
    
    if (kIsWeb) {
      // Webの場合
      final bytes = await image.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      // モバイルの場合
      await ref.putFile(File(image.path));
    }
    
    // ダウンロードURLを取得
    final url = await ref.getDownloadURL();
    return url;
  }

  /// Cloud FunctionsでAI解析（エミュレータ対応）
  Future<String?> _analyzeMealImage(String imageUrl) async {
    try {
      // cloud_functionsパッケージを使用（エミュレータ対応）
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('analyzeMealImage');
      
      final result = await callable.call({
        'imageUrl': imageUrl,
      });
      
      final data = result.data as Map<String, dynamic>?;
      final level = data?['level'] as String?;
      
      // levelを日本語に変換（light/normal/heavy → 軽め/ちょうど/しっかり）
      if (level == 'light') return '軽め';
      if (level == 'heavy') return 'しっかり';
      return 'ちょうど'; // normal または デフォルト
    } catch (e) {
      // エラー時はnullを返す（フォールバック用）
      print('Exception in _analyzeMealImage: $e');
      return null;
    }
  }

  Future<void> _pickImageAndShowEstimate() async {
    final picker = ImagePicker();
    XFile? image;
    
    try {
      // Webではカメラが使えない場合があるので、ギャラリーから選択
      if (kIsWeb) {
        image = await picker.pickImage(source: ImageSource.gallery);
      } else {
        // モバイルではカメラとギャラリーの選択肢を提供
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('写真を選択'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('カメラで撮影'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ギャラリーから選択'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        
        if (source != null) {
          image = await picker.pickImage(source: source);
        }
      }
      
      if (image != null && mounted) {
        // 解析中画面を表示（キャンセル可能）
        if (!mounted) return;
        bool cancelled = false;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            const mintColorLight = Color(0xFFB2DFDB);
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  cancelled = true;
                }
              },
              child: Center(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: mintColorLight.withValues(alpha:0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'AIで解析中...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () {
                            cancelled = true;
                            Navigator.pop(context);
                          },
                          child: const Text('キャンセル'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

        if (cancelled) return;

        try {
          // Firebase Storageへアップロード
          final imageUrl = await _uploadImageToStorage(image);
          
          // Cloud FunctionsでAI解析
          String? aiLevel = await _analyzeMealImage(imageUrl);
          bool hasError = aiLevel == null;
          
          // ローディングを閉じる
          if (mounted) Navigator.pop(context);
          
          // 推定結果画面へ遷移
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealEstimateScreen(
                  imagePath: image?.path ?? '',
                  initialState: aiLevel ?? 'ちょうど',
                  hasError: hasError,
                  onSave: (String state, int kcal, int protein) async {
                    await _saveMealFromEstimate(state, kcal, protein);
                  },
                ),
              ),
            );
          }
        } catch (e) {
          // ローディングを閉じる
          if (mounted) Navigator.pop(context);
          
          // エラー時はデフォルト（ちょうど）で続行
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealEstimateScreen(
                  imagePath: image?.path ?? '',
                  initialState: 'ちょうど',
                  hasError: true,
                  onSave: (String state, int kcal, int protein) async {
                    await _saveMealFromEstimate(state, kcal, protein);
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真の選択に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _saveMealFromEstimate(String state, int kcal, int protein) async {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final currentItems = List<PlanItem>.from(widget.planItems);
    currentItems.add(PlanItem(
      type: 'meal',
      time: time,
      title: '写真で記録',
      enabled: true,
      kcal: kcal,
      protein: protein,
      mealState: state,
    ));

    await widget.onSavePlan(currentItems);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録しました')),
      );
      // Home画面を更新
      await widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);

    // 今日のデータを集計
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayItems = widget.last7DaysPlans.containsKey(today)
        ? (widget.last7DaysPlans[today] ?? <PlanItem>[])
        : <PlanItem>[];
    final mealItems = todayItems.where((item) => item.type == 'meal').toList();
    final workoutItems = todayItems.where((item) => item.type == 'workout').toList();
    
    final mealKcal = mealItems.fold<int>(0, (sum, item) => sum + (item.kcal ?? 0));
    final workoutKcal = workoutItems.fold<int>(0, (sum, item) => sum + (item.kcal ?? 0));
    const mealTarget = 2400;
    const workoutTarget = 400;
    const proteinTarget = 100; // 仮の値
    const proteinCurrent = 0; // 仮の値（PlanItemにproteinフィールドがないため）
    
    // 残りたんぱく質（マイナス表示しない）
    final proteinRemaining = (proteinTarget - proteinCurrent).clamp(0, proteinTarget);

    final remainingCount = _countRemainingPlans(widget.planItems);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 今日の予定（チェック式）
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: mintColorLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '今日の予定',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 20),
                          onPressed: widget.onGoPlan,
                          tooltip: '予定画面へ',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.planItems.isEmpty)
                      Text(
                        '予定を追加しましょう',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      )
                    else
                      ...widget.planItems.take(5).map((item) {
                        final now = DateTime.now();
                        final parts = item.time.split(':');
                        final hh = int.tryParse(parts[0]) ?? 0;
                        final mm = int.tryParse(parts[1]) ?? 0;
                        final itemTime = DateTime(now.year, now.month, now.day, hh, mm);
                        final isPast = itemTime.isBefore(now);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isPast || !item.enabled,
                                onChanged: null, // 読み取り専用
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.time}  ${item.title}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: isPast || !item.enabled
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isPast || !item.enabled
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                                        : null,
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
            ),

            const SizedBox(height: 24),

            // 写真で記録ボタン
            FilledButton.icon(
              onPressed: () => _pickImageAndShowEstimate(),
              icon: const Text('📸', style: TextStyle(fontSize: 18)),
              label: const Text('写真で記録'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: mintColorLight.withValues(alpha: 0.3),
                foregroundColor: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 24),

            // 今日の状態
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: mintColorLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日の状態',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _buildTodayStateText(todayItems),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 今日の摂取状況
            _IntakeGaugeCard(
              intake: mealKcal,
              target: mealTarget,
            ),

            const SizedBox(height: 24),

            // ドーナツ3連（補助的）
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: mintColorLight.withValues(alpha:0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _ExtraLargeDonutChart(
                            value: mealKcal,
                            max: mealTarget,
                            label: 'kcal',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '摂取',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$mealKcal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _ExtraLargeDonutChart(
                            value: workoutKcal,
                            max: workoutTarget,
                            label: 'kcal',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '消費',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$workoutKcal',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _ExtraLargeDonutChart(
                            value: proteinCurrent,
                            max: proteinTarget,
                            label: 'g',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '残りP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$proteinRemaining',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 今日のガイド
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: mintColorLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_fitType != null && _fitType!.isNotEmpty && _fitType != '未診断')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'For $_fitType',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 24,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _guideText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 今日のまとめテキスト
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: mintColorLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日のまとめ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _buildSummaryText(mealKcal, mealTarget, workoutKcal, workoutTarget, proteinCurrent, proteinTarget, remainingCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 200),
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
    _showAddDialog();
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

  Future<void> _showAddDialog() async {
    bool instantSave = false;
    String type = 'meal';
    String time = '08:00';
    String title = '';
    int? kcal;
    final titleController = TextEditingController();
    final kcalController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('食事/運動追加'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡即保存', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Switch(
                    value: instantSave,
                    onChanged: (value) {
                      setDialogState(() => instantSave = value);
                  },
                  ),
                ],
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // テンプレボタン
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        setDialogState(() {
                          type = 'meal';
                          title = '食事';
                          kcal = 500;
                          titleController.text = title;
                          kcalController.text = kcal.toString();
                        });
                        if (instantSave) {
                          Navigator.pop(context);
                          await _applyTemplateAndSave(type, title, kcal, time);
                        }
                      },
                      icon: const Icon(Icons.restaurant_outlined),
                      label: const Text('食事'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        setDialogState(() {
                          type = 'workout';
                          title = '運動';
                          kcal = 200;
                          titleController.text = title;
                          kcalController.text = kcal.toString();
                        });
                        if (instantSave) {
                          Navigator.pop(context);
                          await _applyTemplateAndSave(type, title, kcal, time);
                        }
                      },
                      icon: const Icon(Icons.fitness_center_outlined),
                      label: const Text('運動'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // タイトル入力
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'タイトル',
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 12),
                // カロリー入力
                TextFormField(
                  controller: kcalController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'カロリー（kcal）',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    kcal = int.tryParse(value);
                  },
                ),
                const SizedBox(height: 12),
                // 時間選択
                Row(
                  children: [
                    const Text('時間: '),
                    OutlinedButton(
                      onPressed: () async {
                        final parts = time.split(':');
                        final init = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 8,
                          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                        );
                        final t = await showTimePicker(
                          context: context,
                          initialTime: init,
                        );
                        if (t != null) {
                          setDialogState(() {
                            final hh = t.hour.toString().padLeft(2, '0');
                            final mm = t.minute.toString().padLeft(2, '0');
                            time = '$hh:$mm';
                          });
                        }
                      },
                      child: Text(time),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // タイプ選択
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'タイプ',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'meal', child: Text('食事')),
                    DropdownMenuItem(value: 'workout', child: Text('運動')),
                    DropdownMenuItem(value: 'stretch', child: Text('ストレッチ')),
                    DropdownMenuItem(value: 'sleep', child: Text('睡眠')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => type = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final finalTitle = titleController.text.trim();
                if (finalTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }
                final finalKcal = int.tryParse(kcalController.text);
                setState(() {
                  _items.add(PlanItem(
                    type: type,
                    time: time,
                    title: finalTitle,
                    enabled: true,
                    kcal: finalKcal,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTemplateAndSave(String type, String title, int? kcal, String time) async {
    setState(() {
      _items.add(PlanItem(
        type: type,
        time: time,
        title: title,
        enabled: true,
        kcal: kcal,
      ));
    });
    // 即保存がONの場合は保存処理を実行
    await widget.onSave(_items);
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
    required this.last7DaysPlans,
    required this.planItems,
    required this.onAddMeal,
    required this.onAddWorkout,
    required this.onSavePlan,
    required this.onSubmit,
  });

  final bool enabled;
  final List<String> habitOptions;
  final Map<DateTime, List<PlanItem>> last7DaysPlans;
  final List<PlanItem> planItems;
  final VoidCallback onAddMeal;
  final VoidCallback onAddWorkout;
  final Future<void> Function(List<PlanItem>) onSavePlan;
  final Future<void> Function(String habit) onSubmit;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  @override
  void initState() {
    super.initState();
  }

  /// Firebase Storageへ画像をアップロード
  Future<String> _uploadImageToStorage(XFile image) async {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid ?? 'anonymous';
    final storage = FirebaseStorage.instance;
    
    // ファイル名を生成（タイムスタンプ + ランダム）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'meal_images/$uid/${timestamp}_${image.name}';
    
    // アップロード
    final ref = storage.ref().child(fileName);
    
    if (kIsWeb) {
      // Webの場合
      final bytes = await image.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      // モバイルの場合
      await ref.putFile(File(image.path));
    }
    
    // ダウンロードURLを取得
    final url = await ref.getDownloadURL();
    return url;
  }

  /// Cloud FunctionsでAI解析（エミュレータ対応）
  Future<String?> _analyzeMealImage(String imageUrl) async {
    try {
      // エミュレータのCallable Function URL
      const emulatorUrl = 'http://127.0.0.1:5001/calmee-8011c/us-central1/analyzeMealImage';
      
      // 認証トークンを取得
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      String? idToken;
      if (user != null) {
        idToken = await user.getIdToken();
      }
      
      // HTTP POSTリクエスト（エミュレータのCallable Function形式）
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }
      
      // エミュレータのCallable Functionは data フィールドでラップ
      final body = jsonEncode({
        'data': {
          'imageUrl': imageUrl,
        },
      });
      
      final response = await http.post(
        Uri.parse(emulatorUrl),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        // エミュレータのレスポンス形式を確認
        // 成功時: { "result": { "level": "..." } }
        // エラー時: { "error": { ... } }
        if (json.containsKey('error')) {
          print('Functions error: ${json['error']}');
          return null;
        }
        
        final result = json['result'] as Map<String, dynamic>?;
        final level = result?['level'] as String?;
        
        // levelを日本語に変換（light/normal/heavy → 軽め/ちょうど/しっかり）
        if (level == 'light') return '軽め';
        if (level == 'heavy') return 'しっかり';
        return 'ちょうど'; // normal または デフォルト
      } else {
        // HTTPエラー時はnullを返す（フォールバック用）
        print('HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // エラー時はnullを返す（フォールバック用）
      print('Exception in _analyzeMealImage: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 過去7日の食事データを集計
    final now = DateTime.now();
    final dailyKcals = <({DateTime date, int kcal})>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final items = widget.last7DaysPlans[date] ?? [];
      
      // 食事（meal）タイプのkcalを合計
      int totalKcal = 0;
      for (final item in items) {
        if (item.type == 'meal' && item.kcal != null) {
          totalKcal += item.kcal!;
        }
      }
      
      dailyKcals.add((date: date, kcal: totalKcal));
    }

    // 今日のデータを集計
    final today = DateTime(now.year, now.month, now.day);
    final todayItems = widget.last7DaysPlans[today] ?? [];
    final mealItems = todayItems.where((item) => item.type == 'meal').toList();
    final workoutItems = todayItems.where((item) => item.type == 'workout').toList();
    
    final mealKcal = mealItems.fold<int>(0, (sum, item) => sum + (item.kcal ?? 0));
    final workoutKcal = workoutItems.fold<int>(0, (sum, item) => sum + (item.kcal ?? 0));
    const mealTarget = 2400;
    const workoutTarget = 400;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // クイック追加エリア
          _buildQuickAddSection(theme),
          
          const SizedBox(height: 16),
          
          // 食事ログ
          _buildMealSection(theme, mealKcal, mealTarget, mealItems),
          
          // 運動ログ
          const SizedBox(height: 16),
          _buildWorkoutSection(theme, workoutKcal, workoutTarget, workoutItems),
          
          // 週間ミニグラフ
          const SizedBox(height: 16),
          WeeklyKcalMiniGraph(dailyKcals: dailyKcals),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(ThemeData theme) {
    const mintColorLight = Color(0xFFB2DFDB);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: mintColorLight.withValues(alpha:0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'クイック追加',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // 写真で記録ボタン
            FilledButton.icon(
              onPressed: () => _pickImageAndShowEstimate(),
              icon: const Text('📸', style: TextStyle(fontSize: 18)),
              label: const Text('写真で記録'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: mintColorLight.withValues(alpha: 0.3),
                foregroundColor: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // 食事テンプレ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickAddMeal(100, 20),
                    icon: const Icon(Icons.restaurant_outlined, size: 18),
                    label: const Text('+100kcal / +P20g'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 運動テンプレ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickAddWorkout('家トレ10分', 50),
                    icon: const Icon(Icons.fitness_center_outlined, size: 18),
                    label: const Text('家トレ10分'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickAddWorkout('ストレッチ5分', 20),
                    icon: const Icon(Icons.self_improvement_outlined, size: 18),
                    label: const Text('ストレッチ5分'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageAndShowEstimate() async {
    final picker = ImagePicker();
    XFile? image;
    
    try {
      // Webではカメラが使えない場合があるので、ギャラリーから選択
      if (kIsWeb) {
        image = await picker.pickImage(source: ImageSource.gallery);
      } else {
        // モバイルではカメラとギャラリーの選択肢を提供
        final source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('写真を選択'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('カメラで撮影'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ギャラリーから選択'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        
        if (source != null) {
          image = await picker.pickImage(source: source);
        }
      }
      
      if (image != null && mounted) {
        // 解析中画面を表示（キャンセル可能）
        if (!mounted) return;
        bool cancelled = false;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            const mintColorLight = Color(0xFFB2DFDB);
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  cancelled = true;
                }
              },
              child: Center(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: mintColorLight.withValues(alpha:0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'AIで解析中...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () {
                            cancelled = true;
                            Navigator.pop(context);
                          },
                          child: const Text('キャンセル'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

        if (cancelled) return;

        try {
          // Firebase Storageへアップロード
          final imageUrl = await _uploadImageToStorage(image);
          
          // Cloud FunctionsでAI解析
          String? aiLevel = await _analyzeMealImage(imageUrl);
          bool hasError = aiLevel == null;
          
          // ローディングを閉じる
          if (mounted) Navigator.pop(context);
          
          // 推定結果画面へ遷移
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealEstimateScreen(
                  imagePath: image?.path ?? '',
                  initialState: aiLevel ?? 'ちょうど',
                  hasError: hasError,
                  onSave: (String state, int kcal, int protein) async {
                    await _saveMealFromEstimate(state, kcal, protein);
                  },
                ),
              ),
            );
          }
        } catch (e) {
          // ローディングを閉じる
          if (mounted) Navigator.pop(context);
          
          // エラー時はデフォルト（ちょうど）で続行
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealEstimateScreen(
                  imagePath: image?.path ?? '',
                  initialState: 'ちょうど',
                  hasError: true,
                  onSave: (String state, int kcal, int protein) async {
                    await _saveMealFromEstimate(state, kcal, protein);
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真の選択に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _saveMealFromEstimate(String state, int kcal, int protein) async {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final currentItems = List<PlanItem>.from(widget.planItems);
    currentItems.add(PlanItem(
      type: 'meal',
      time: time,
      title: '写真で記録',
      enabled: true,
      kcal: kcal,
      protein: protein,
      mealState: state,
    ));

    await widget.onSavePlan(currentItems);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録しました')),
      );
    }
  }

  Future<void> _quickAddMeal(int kcal, int protein) async {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final currentItems = List<PlanItem>.from(widget.planItems);
    currentItems.add(PlanItem(
      type: 'meal',
      time: time,
      title: '食事',
      enabled: true,
      kcal: kcal,
    ));

    await widget.onSavePlan(currentItems);
  }

  Future<void> _quickAddMealState(String state) async {
    // 状態別のkcal/Pマッピング
    final stateMap = {
      'しっかり': {'kcal': 800, 'protein': 45},
      'ちょうど': {'kcal': 600, 'protein': 35},
      '軽め': {'kcal': 400, 'protein': 25},
    };

    final values = stateMap[state];
    if (values == null) return;

    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final currentItems = List<PlanItem>.from(widget.planItems);
    currentItems.add(PlanItem(
      type: 'meal',
      time: time,
      title: state,
      enabled: true,
      kcal: values['kcal'] as int,
      protein: values['protein'] as int,
      mealState: state,
    ));

    await widget.onSavePlan(currentItems);
  }

  Future<void> _quickAddWorkout(String title, int kcal) async {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final currentItems = List<PlanItem>.from(widget.planItems);
    currentItems.add(PlanItem(
      type: 'workout',
      time: time,
      title: title,
      enabled: true,
      kcal: kcal,
    ));

    await widget.onSavePlan(currentItems);
  }

  Widget _buildMealSection(ThemeData theme, int totalKcal, int targetKcal, List<PlanItem> items) {
    const mintColorLight = Color(0xFFB2DFDB);
    final remaining = (targetKcal - totalKcal).clamp(0, targetKcal);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: mintColorLight.withValues(alpha:0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日の食事は？（3択クイック記録）
            Text(
              '今日の食事は？',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _quickAddMealState('しっかり'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('しっかり'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _quickAddMealState('ちょうど'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ちょうど'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _quickAddMealState('軽め'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('軽め'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // 見出し行
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  MiniDonutChart(
                    value: totalKcal,
                    max: targetKcal,
                    label: 'kcal',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$totalKcal',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' / $targetKcal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remaining > 0
                              ? 'あと${remaining}kcal'
                              : '目標達成',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    onPressed: () => _showAddMealDialog(),
                    tooltip: '食事を追加',
                  ),
                ],
              ),
            ),
            // 食事リスト
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (item.kcal != null)
                              Text(
                                '${item.kcal} kcal',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        item.time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSection(ThemeData theme, int totalKcal, int targetKcal, List<PlanItem> items) {
    const mintColorLight = Color(0xFFB2DFDB);
    final remaining = (targetKcal - totalKcal).clamp(0, targetKcal);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: mintColorLight.withValues(alpha:0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 見出し行
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  MiniDonutChart(
                    value: totalKcal,
                    max: targetKcal,
                    label: 'kcal',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$totalKcal',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' / $targetKcal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remaining > 0
                              ? 'あと${remaining}kcal'
                              : '目標達成',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    onPressed: () => _showAddWorkoutDialog(),
                    tooltip: '運動を追加',
                  ),
                ],
              ),
            ),
            // 運動リスト
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (item.kcal != null)
                              Text(
                                '${item.kcal} kcal',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        item.time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMealDialog() async {
    String? selectedState;
    String time = '08:00';
    String title = '';
    int? kcal;
    final titleController = TextEditingController();
    final kcalController = TextEditingController();

    // 状態選択のマッピング
    final stateMap = {
      'しっかり': {'kcal': 800, 'protein': 30},
      'ちょうど': {'kcal': 500, 'protein': 20},
      '軽め': {'kcal': 300, 'protein': 10},
    };

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('食事追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 状態選択（3択）
                const Text(
                  '状態を選択',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedState = 'しっかり';
                            kcal = stateMap[selectedState]!['kcal'] as int;
                            kcalController.text = kcal.toString();
                            title = selectedState!;
                            titleController.text = title;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedState == 'しっかり'
                              ? const Color(0xFFB2DFDB).withValues(alpha:0.2)
                              : null,
                        ),
                        child: const Text('しっかり'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedState = 'ちょうど';
                            kcal = stateMap[selectedState]!['kcal'] as int;
                            kcalController.text = kcal.toString();
                            title = selectedState!;
                            titleController.text = title;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedState == 'ちょうど'
                              ? const Color(0xFFB2DFDB).withValues(alpha:0.2)
                              : null,
                        ),
                        child: const Text('ちょうど'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedState = '軽め';
                            kcal = stateMap[selectedState]!['kcal'] as int;
                            kcalController.text = kcal.toString();
                            title = selectedState!;
                            titleController.text = title;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selectedState == '軽め'
                              ? const Color(0xFFB2DFDB).withValues(alpha:0.2)
                              : null,
                        ),
                        child: const Text('軽め'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // タイトル入力
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'タイトル',
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 12),
                // カロリー入力
                TextFormField(
                  controller: kcalController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'カロリー（kcal）',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    kcal = int.tryParse(value);
                  },
                ),
                const SizedBox(height: 12),
                // 時間選択
                Row(
                  children: [
                    const Text('時間: '),
                    OutlinedButton(
                      onPressed: () async {
                        final parts = time.split(':');
                        final init = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 8,
                          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                        );
                        final t = await showTimePicker(
                          context: context,
                          initialTime: init,
                        );
                        if (t != null) {
                          setDialogState(() {
                            final hh = t.hour.toString().padLeft(2, '0');
                            final mm = t.minute.toString().padLeft(2, '0');
                            time = '$hh:$mm';
                          });
                        }
                      },
                      child: Text(time),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final finalTitle = titleController.text.trim();
                if (finalTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }
                final finalKcal = int.tryParse(kcalController.text);

                // 今日のplanItemsを更新
                final currentItems = List<PlanItem>.from(widget.planItems);
                currentItems.add(PlanItem(
                  type: 'meal',
                  time: time,
                  title: finalTitle,
                  enabled: true,
                  kcal: finalKcal,
                  mealState: selectedState,
                ));

                Navigator.pop(context);
                widget.onSavePlan(currentItems);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddWorkoutDialog() async {
    await _showAddItemDialog(type: 'workout', defaultTitle: '運動', defaultKcal: 200);
  }

  Future<void> _showAddItemDialog({
    required String type,
    required String defaultTitle,
    required int defaultKcal,
  }) async {
    String time = '08:00';
    String title = '';
    int? kcal;
    final titleController = TextEditingController();
    final kcalController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(type == 'meal' ? '食事追加' : '運動追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // テンプレボタン
                OutlinedButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      title = defaultTitle;
                      kcal = defaultKcal;
                      titleController.text = title;
                      kcalController.text = kcal.toString();
                    });
                  },
                  icon: Icon(type == 'meal' ? Icons.restaurant_outlined : Icons.fitness_center_outlined),
                  label: Text(defaultTitle),
                ),
                const SizedBox(height: 16),
                // タイトル入力
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'タイトル',
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 12),
                // カロリー入力
                TextFormField(
                  controller: kcalController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'カロリー（kcal）',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    kcal = int.tryParse(value);
                  },
                ),
                const SizedBox(height: 12),
                // 時間選択
                Row(
                  children: [
                    const Text('時間: '),
                    OutlinedButton(
                      onPressed: () async {
                        final parts = time.split(':');
                        final init = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 8,
                          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                        );
                        final t = await showTimePicker(
                          context: context,
                          initialTime: init,
                        );
                        if (t != null) {
                          setDialogState(() {
                            final hh = t.hour.toString().padLeft(2, '0');
                            final mm = t.minute.toString().padLeft(2, '0');
                            time = '$hh:$mm';
                          });
                        }
                      },
                      child: Text(time),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final finalTitle = titleController.text.trim();
                if (finalTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }
                final finalKcal = int.tryParse(kcalController.text);

                // 今日のplanItemsを更新
                final currentItems = List<PlanItem>.from(widget.planItems);
                currentItems.add(PlanItem(
                  type: type,
                  time: time,
                  title: finalTitle,
                  enabled: true,
                  kcal: finalKcal,
                ));

                Navigator.pop(context);
                widget.onSavePlan(currentItems);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 食事推定結果画面（AIダミー）
class MealEstimateScreen extends StatefulWidget {
  const MealEstimateScreen({
    super.key,
    required this.imagePath,
    this.initialState,
    this.hasError = false,
    required this.onSave,
  });

  final String imagePath;
  final String? initialState; // AI解析結果（軽め/ちょうど/しっかり）
  final bool hasError; // AI解析が失敗したかどうか
  final void Function(String state, int kcal, int protein) onSave;

  @override
  State<MealEstimateScreen> createState() => _MealEstimateScreenState();
}

class _MealEstimateScreenState extends State<MealEstimateScreen> {
  late String _selectedState; // AI解析結果またはデフォルト
  
  // 状態別のkcal/Pマッピング
  final Map<String, Map<String, int>> _stateMap = {
    '軽め': {'kcal': 400, 'protein': 25},
    'ちょうど': {'kcal': 600, 'protein': 35},
    'しっかり': {'kcal': 800, 'protein': 45},
  };

  @override
  void initState() {
    super.initState();
    // AI解析結果があればそれを使用、なければデフォルト「ちょうど」
    _selectedState = widget.initialState ?? 'ちょうど';
  }

  int get _currentKcal => _stateMap[_selectedState]!['kcal']!;
  int get _currentProtein => _stateMap[_selectedState]!['protein']!;

  void _handleSave() {
    widget.onSave(_selectedState, _currentKcal, _currentProtein);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('推定結果'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 選択した写真を表示
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: kIsWeb
                  ? Image.network(
                      widget.imagePath,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(widget.imagePath),
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 32),
            
            // 失敗時の説明
            if (widget.hasError)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: mintColorLight.withValues(alpha:0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI解析に失敗したため、デフォルト値で表示しています。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (widget.hasError) const SizedBox(height: 24),
            
            // 3択UI（SegmentedButton）
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: mintColorLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '食事の量を選択',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: '軽め',
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('軽め'),
                              const SizedBox(height: 2),
                              Text(
                                '少なめ・間食・軽食',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ButtonSegment(
                          value: 'ちょうど',
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('ちょうど'),
                              const SizedBox(height: 2),
                              Text(
                                '通常の1食',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ButtonSegment(
                          value: 'しっかり',
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('しっかり'),
                              const SizedBox(height: 2),
                              Text(
                                '外食・ボリューム多め',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      selected: {_selectedState},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedState = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: mintColorLight.withValues(alpha:0.4),
                        selectedForegroundColor: theme.colorScheme.onSurface,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // kcal/P表示（小さめ）
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: mintColorLight.withValues(alpha:0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$_currentKcal',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Text(
                          '$_currentProtein',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'P',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // OKボタン
            FilledButton(
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: mintColorLight.withValues(alpha:0.4),
                foregroundColor: theme.colorScheme.onSurface,
              ),
              child: const Text(
                'OK（記録する）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// 今日の摂取状況用半円メーターカード
class _IntakeGaugeCard extends StatelessWidget {
  const _IntakeGaugeCard({
    required this.intake,
    required this.target,
  });

  final int intake;
  final int target;

  Color _getStatusColor() {
    final ratio = target > 0 ? (intake / target) : 0.0;
    if (ratio <= 0.8) {
      // 順調: 0-80% (基本ミント)
      return const Color(0xFF80CBC4);
    } else if (ratio <= 1.0) {
      // 注意: 80-100% (少し濃いめ)
      return const Color(0xFF4DB6AC);
    } else {
      // オーバー: 100%超 (警告トーン、派手すぎない)
      return const Color(0xFFE57373);
    }
  }

  String _getStatusText() {
    final ratio = target > 0 ? (intake / target) : 0.0;
    if (ratio <= 0.8) {
      return '順調';
    } else if (ratio <= 1.0) {
      return '注意';
    } else {
      return 'オーバー';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);
    final remaining = (target - intake).clamp(0, target);
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: mintColorLight.withValues(alpha:0.15),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 半円メーター
            SizedBox(
              width: 260.0, // 200 * 1.3
              height: 130.0, // 半円なので高さは半分
              child: CustomPaint(
                painter: _SemiCircleGaugePainter(
                  progress: target > 0 ? (intake / target).clamp(0.0, 1.0) : 0.0,
                  statusColor: statusColor,
                  backgroundColor: mintColorLight.withValues(alpha:0.2),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 残り kcal（大きめ）
                      Text(
                        '残り $remaining',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 16,
                          color: statusColor.withValues(alpha:0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 摂取 / 目標（小さめ）
                      Text(
                        '$intake / $target',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 状態ラベル（小さく）
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

/// 半円ゲージのCustomPainter
class _SemiCircleGaugePainter extends CustomPainter {
  _SemiCircleGaugePainter({
    required this.progress,
    required this.statusColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color statusColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20; // ストローク幅の余白
    const strokeWidth = 24.0;

    // 背景アーク（半円）
    paint
      ..color = backgroundColor
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // 180度から開始
      math.pi, // 180度描画（半円）
      false,
      paint,
    );

    // プログレスアーク
    paint
      ..color = statusColor.withValues(alpha:0.8)
      ..strokeWidth = strokeWidth;
    final sweepAngle = math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // 180度から開始
      sweepAngle, // 進捗に応じた角度
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileRepo,
  });

  final ProfileRepository profileRepo;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // データ
  double _height = 170.0; // cm
  double _weight = 65.0; // kg
  double _bodyFat = 18.5; // %
  double _targetWeight = 60.0; // kg
  int _targetPeriod = 90; // 日
  String _targetPolicy = '健康的に減量';
  String _fitnessType = '未診断';
  String _fitnessTypeDescription = '診断を完了すると表示されます。';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await widget.profileRepo.load();
      if (data != null && mounted) {
        setState(() {
          _height = (data['heightCm'] as num?)?.toDouble() ?? 170.0;
          _weight = (data['weightKg'] as num?)?.toDouble() ?? 65.0;
          _bodyFat = (data['bodyFatPct'] as num?)?.toDouble() ?? 18.5;
          _targetWeight = (data['targetWeightKg'] as num?)?.toDouble() ?? 60.0;
          _targetPeriod = (data['targetDays'] as num?)?.toInt() ?? 90;
          _targetPolicy = (data['policyText'] as String?) ?? '健康的に減量';
          _fitnessType = (data['fitType'] as String?) ?? '未診断';
          if (_fitnessType != '未診断') {
            _fitnessTypeDescription = _getFitnessTypeDescription(_fitnessType);
          }
        });
      }
    } catch (e) {
      // エラーは無視（デフォルト値で続行）
    }
  }

  String _getFitnessTypeDescription(String type) {
    final descriptions = {
      'ENFP': 'エネルギッシュで創造的なタイプ。多様な運動を楽しみ、柔軟にアプローチします。',
      'ENFJ': 'リーダーシップがあり、他者と協力して目標を達成するタイプ。',
      'ENTP': '革新的で挑戦的なタイプ。新しい運動方法を試すのが好きです。',
      'ENTJ': '戦略的で目標達成に集中するタイプ。効率的な運動計画を立てます。',
      'ESFP': '楽しく社交的なタイプ。グループで運動することを好みます。',
      'ESFJ': '協調性が高く、他者と一緒に運動することを楽しみます。',
      'ESTP': '行動力があり、実践的な運動を好みます。',
      'ESTJ': '組織的で計画的。ルーティンを守って継続します。',
      'INFP': '内省的で創造的なタイプ。自分なりの運動スタイルを大切にします。',
      'INFJ': '深く考え、長期的な視点で運動に取り組みます。',
      'INTP': '分析的で理論的なタイプ。運動のメカニズムを理解したいです。',
      'INTJ': '戦略的で独立心が強いタイプ。自分で計画を立てて実行します。',
      'ISFP': '柔軟で感受性が高いタイプ。自然な流れで運動を楽しみます。',
      'ISFJ': '責任感が強く、継続的な努力を大切にします。',
      'ISTP': '実践的で独立心が強いタイプ。自分で試行錯誤します。',
      'ISTJ': '規則正しく、計画的に運動を継続します。',
    };
    return descriptions[type] ?? 'あなたのフィットネスタイプです。';
  }

  /// Navigator.popとSnackBarを表示（context使用をState内に閉じ込める）
  Future<void> _handlePopAndSnackBar({required String successMessage, String? errorMessage}) async {
    if (!mounted) return;
    Navigator.pop(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? successMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'My Page',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // 基本情報カード
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: mintColorLight.withValues(alpha:0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '基本情報',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditBasicInfoSheet(context, theme),
                        tooltip: '編集',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: '身長',
                    value: '${_height.toStringAsFixed(1)} cm',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: '体重',
                    value: '${_weight.toStringAsFixed(1)} kg',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: '体脂肪率',
                    value: '${_bodyFat.toStringAsFixed(1)} %',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 目標情報カード
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: mintColorLight.withValues(alpha:0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '目標情報',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditTargetInfoSheet(context, theme),
                        tooltip: '編集',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: '目標体重',
                    value: '${_targetWeight.toStringAsFixed(1)} kg',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: '期間',
                    value: '$_targetPeriod 日',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: '方針',
                    value: _targetPolicy,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // フィットネスタイプ診断カード（ExpansionTile）
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: mintColorLight.withValues(alpha:0.15),
            child: ExpansionTile(
              title: Text(
                'フィットネスタイプ診断',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: _fitnessType != '未診断' && _fitnessType.isNotEmpty
                  ? Text(
                      _fitnessType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
              trailing: _fitnessType != '未診断' && _fitnessType.isNotEmpty
                  ? FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiagnosisScreen(
                              profileRepo: widget.profileRepo,
                            ),
                          ),
                        ).then((_) {
                          // 診断画面から戻ったら、fitTypeを再読み込み
                          _loadProfile();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('再診断する'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiagnosisScreen(
                              profileRepo: widget.profileRepo,
                            ),
                          ),
                        ).then((_) {
                          // 診断画面から戻ったら、fitTypeを再読み込み
                          _loadProfile();
                        });
                      },
                      icon: const Icon(Icons.psychology_outlined, size: 16),
                      label: const Text('診断する'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
              children: [
                if (_fitnessType != '未診断') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      _fitnessTypeDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      '診断を完了すると表示されます。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBasicInfoSheet(BuildContext context, ThemeData theme) async {
    final heightController = TextEditingController(text: _height.toStringAsFixed(1));
    final weightController = TextEditingController(text: _weight.toStringAsFixed(1));
    final bodyFatController = TextEditingController(text: _bodyFat.toStringAsFixed(1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '基本情報を編集',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: heightController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '身長 (cm)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: weightController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '体重 (kg)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bodyFatController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '体脂肪率 (%)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final height = double.tryParse(heightController.text);
                final weight = double.tryParse(weightController.text);
                final bodyFat = double.tryParse(bodyFatController.text);

                if (height != null && weight != null && bodyFat != null) {
                  try {
                    await widget.profileRepo.save(
                      heightCm: height,
                      weightKg: weight,
                      bodyFatPct: bodyFat,
                    );
                    if (!mounted) return;
                    setState(() {
                      _height = height;
                      _weight = weight;
                      _bodyFat = bodyFat;
                    });
                    if (!mounted) return;
                    await _handlePopAndSnackBar(successMessage: '保存しました');
                  } catch (e) {
                    if (!mounted) return;
                    await _handlePopAndSnackBar(
                      successMessage: '',
                      errorMessage: '保存に失敗しました: $e',
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('有効な数値を入力してください')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTargetInfoSheet(BuildContext context, ThemeData theme) async {
    final targetWeightController = TextEditingController(text: _targetWeight.toStringAsFixed(1));
    final targetPeriodController = TextEditingController(text: _targetPeriod.toString());
    final targetPolicyController = TextEditingController(text: _targetPolicy);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '目標情報を編集',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: targetWeightController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '目標体重 (kg)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: targetPeriodController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '期間 (日)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: targetPolicyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '方針',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final targetWeight = double.tryParse(targetWeightController.text);
                final targetPeriod = int.tryParse(targetPeriodController.text);
                final targetPolicy = targetPolicyController.text.trim();

                if (targetWeight != null && targetPeriod != null && targetPolicy.isNotEmpty) {
                  try {
                    await widget.profileRepo.save(
                      targetWeightKg: targetWeight,
                      targetDays: targetPeriod,
                      policyText: targetPolicy,
                    );
                    if (!mounted) return;
                    setState(() {
                      _targetWeight = targetWeight;
                      _targetPeriod = targetPeriod;
                      _targetPolicy = targetPolicy;
                    });
                    if (!mounted) return;
                    await _handlePopAndSnackBar(successMessage: '保存しました');
                  } catch (e) {
                    if (!mounted) return;
                    await _handlePopAndSnackBar(
                      successMessage: '',
                      errorMessage: '保存に失敗しました: $e',
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('有効な値を入力してください')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

}

/// ----------------------------
/// Diagnosis Screens
/// ----------------------------

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({
    super.key,
    required this.profileRepo,
  });

  final ProfileRepository profileRepo;

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  int _questionIndex = 0;
  int _eScore = 0;
  int _sScore = 0;
  int _tScore = 0;
  int _jScore = 0;

  static const List<(String, String, String, String)> _questions = [
    ('運動は一人でする方が好きですか？', 'グループでする方が好きですか？', 'I', 'E'),
    ('運動の計画は事前に立てますか？', 'その日の気分で決めますか？', 'J', 'P'),
    ('運動の効果を数値で確認しますか？', '体感で判断しますか？', 'S', 'N'),
    ('運動中は集中して黙々と取り組みますか？', '楽しみながら会話もしますか？', 'I', 'E'),
    ('同じ運動を続けるのが好きですか？', '新しい運動に挑戦するのが好きですか？', 'S', 'N'),
    ('運動の目標は明確に設定しますか？', '大まかな方向性で進めますか？', 'J', 'P'),
    ('運動の結果を論理的に分析しますか？', '感覚的に理解しますか？', 'T', 'F'),
    ('運動は計画的に継続しますか？', '気が向いたときにしますか？', 'J', 'P'),
    ('運動のモチベーションは目標達成ですか？', '運動そのものを楽しみますか？', 'T', 'F'),
    ('運動の時間は固定しますか？', '柔軟に調整しますか？', 'J', 'P'),
  ];

  void _answer(String axis) {
    setState(() {
      // スコアを更新
      if (axis == 'E') _eScore++;
      if (axis == 'I') _eScore--;
      if (axis == 'S') _sScore++;
      if (axis == 'N') _sScore--;
      if (axis == 'T') _tScore++;
      if (axis == 'F') _tScore--;
      if (axis == 'J') _jScore++;
      if (axis == 'P') _jScore--;

      _questionIndex++;
    });

    // 最後の質問の後、結果画面へ遷移
    if (_questionIndex >= _questions.length) {
      final type = '${_eScore >= 3 ? 'E' : 'I'}${_sScore >= 3 ? 'S' : 'N'}${_tScore >= 3 ? 'T' : 'F'}${_jScore >= 3 ? 'J' : 'P'}';
      final fitAxis = 'E:$_eScore,I:${5-_eScore} S:$_sScore,N:${5-_sScore} T:$_tScore,F:${5-_tScore} J:$_jScore,P:${5-_jScore}';
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosisResultScreen(
            profileRepo: widget.profileRepo,
            fitType: type,
            fitAxis: fitAxis,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);

    if (_questionIndex >= _questions.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_questionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('フィットネスタイプ診断'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 進捗表示
              Text(
                '質問 ${_questionIndex + 1} / ${_questions.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_questionIndex + 1) / _questions.length,
                backgroundColor: mintColorLight.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(mintColorLight),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 32),

              // 質問文
              Text(
                'どちらに近いですか？',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 選択肢A
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: mintColorLight.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: () => _answer(question.$3),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: mintColorLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question.$1,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 選択肢B
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: mintColorLight.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: () => _answer(question.$4),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: mintColorLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'B',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            question.$2,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosisResultScreen extends StatelessWidget {
  const DiagnosisResultScreen({
    super.key,
    required this.profileRepo,
    required this.fitType,
    required this.fitAxis,
  });

  final ProfileRepository profileRepo;
  final String fitType;
  final String fitAxis;

  static const Map<String, String> _descriptions = {
    'ENFP': 'エネルギッシュで創造的なタイプ。多様な運動を楽しみ、柔軟にアプローチします。',
    'ENFJ': 'リーダーシップがあり、他者と協力して目標を達成するタイプ。',
    'ENTP': '革新的で挑戦的なタイプ。新しい運動方法を試すのが好きです。',
    'ENTJ': '戦略的で目標達成に集中するタイプ。効率的な運動計画を立てます。',
    'ESFP': '楽しく社交的なタイプ。グループで運動することを好みます。',
    'ESFJ': '協調性が高く、他者と一緒に運動することを楽しみます。',
    'ESTP': '行動力があり、実践的な運動を好みます。',
    'ESTJ': '組織的で計画的。ルーティンを守って継続します。',
    'INFP': '内省的で創造的なタイプ。自分なりの運動スタイルを大切にします。',
    'INFJ': '深く考え、長期的な視点で運動に取り組みます。',
    'INTP': '分析的で理論的なタイプ。運動のメカニズムを理解したいです。',
    'INTJ': '戦略的で独立心が強いタイプ。自分で計画を立てて実行します。',
    'ISFP': '柔軟で感受性が高いタイプ。自然な流れで運動を楽しみます。',
    'ISFJ': '責任感が強く、継続的な努力を大切にします。',
    'ISTP': '実践的で独立心が強いタイプ。自分で試行錯誤します。',
    'ISTJ': '規則正しく、計画的に運動を継続します。',
  };

  Future<void> _saveAndReturn(BuildContext context) async {
    try {
      await profileRepo.save(
        fitType: fitType,
        fitAxis: fitAxis,
      );
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('診断結果を保存しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);
    final description = _descriptions[fitType] ?? 'あなたのフィットネスタイプです。';

    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タイプ表示
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: mintColorLight.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        fitType,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'このタイプで、しばらく進めてみよう。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 保存して戻るボタン
              FilledButton(
                onPressed: () => _saveAndReturn(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('このスタイルで始める'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.weightRepo,
  });

  final WeightRepository weightRepo;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _weightController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayWeight();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayWeight() async {
    try {
      final weight = await widget.weightRepo.loadToday();
      if (weight != null && mounted) {
        _weightController.text = weight.toString();
      }
    } catch (e) {
      // エラーは無視（初期値なしで続行）
    }
  }

  Future<void> _saveWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('体重を入力してください')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('有効な体重を入力してください')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await widget.weightRepo.saveToday(weight: weight);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const mintColorLight = Color(0xFFB2DFDB);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            '設定',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          
          // 今日の体重を記録
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: mintColorLight.withValues(alpha:0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日の体重を記録',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: '体重（kg）',
                      hintText: '例: 72.3',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha:0.7),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveWeight(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _saveWeight,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存する', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
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

/// 特大ドーナツチャート（3連用、1.4倍）
class _ExtraLargeDonutChart extends StatelessWidget {
  const _ExtraLargeDonutChart({
    required this.value,
    required this.max,
    required this.label,
  });

  final int value;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    const diameter = 156.0; // 120.0 * 1.3（横並び3連用）
    const strokeWidth = 18.2; // 14.0 * 1.3
    const mintColor = Color(0xFF80CBC4);
    const mintColorLight = Color(0xFFB2DFDB);

    final progress = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景円
          SizedBox(
            width: diameter,
            height: diameter,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                mintColorLight.withValues(alpha:0.2),
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
          // プログレス円
          SizedBox(
            width: diameter,
            height: diameter,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                mintColor.withValues(alpha:0.6),
              ),
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
          // 中央テキスト
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ミニドーナツチャート
class MiniDonutChart extends StatelessWidget {
  const MiniDonutChart({
    super.key,
    required this.value,
    required this.max,
    required this.label,
  });

  final int value;
  final int max;
  final String label; // "kcal" など

  @override
  Widget build(BuildContext context) {
    const diameter = 120.0;
    const strokeWidth = 14.0;
    const mintColor = Color(0xFF80CBC4);
    const mintColorLight = Color(0xFFB2DFDB);

    final progress = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景円
          SizedBox(
            width: diameter,
            height: diameter,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                mintColorLight.withValues(alpha:0.2),
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
          // プログレス円
          SizedBox(
            width: diameter,
            height: diameter,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                mintColor.withValues(alpha:0.6),
              ),
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
          // 中央テキスト
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 週間ミニグラフ（摂取kcal）
class WeeklyKcalMiniGraph extends StatelessWidget {
  const WeeklyKcalMiniGraph({
    super.key,
    required this.dailyKcals,
  });

  /// 過去7日の日付とkcalのリスト（古い順）
  final List<({DateTime date, int kcal})> dailyKcals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const targetKcal = 2400;
    const mintColor = Color(0xFF80CBC4); // ミント基調
    const mintColorLight = Color(0xFFB2DFDB); // 薄いミント

    // 最大値を計算（目標kcalと実際の最大値の大きい方）
    int maxKcal = targetKcal;
    if (dailyKcals.isNotEmpty) {
      final max = dailyKcals.map((e) => e.kcal).reduce((a, b) => a > b ? a : b);
      maxKcal = max > targetKcal ? max : targetKcal;
    }
    final graphMax = maxKcal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '週間摂取kcal',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  // 目標補助線（2400kcal）
                  if (graphMax >= targetKcal)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 120 - (targetKcal / graphMax) * 120,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: mintColorLight.withValues(alpha:0.4),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '2400',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mintColorLight.withValues(alpha:0.6),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // バーグラフ
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: dailyKcals.asMap().entries.map((entry) {
                        final data = entry.value;
                        final barHeight = (data.kcal / graphMax) * 120;
                        final dayLabel = _getDayLabel(data.date);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: barHeight.clamp(0.0, 120.0),
                                  decoration: BoxDecoration(
                                    color: mintColor.withValues(alpha:0.5),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dayLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '${data.kcal}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha:0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return '今日';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return '昨日';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}


