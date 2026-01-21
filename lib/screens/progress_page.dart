import 'package:flutter/material.dart';
import '../widgets/centered_content.dart';

/// Cal AI風Progress UI
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String selectedTimeRange = '6M'; // 90D / 6M / 1Y / ALL

  // ダミーデータ
  final double currentWeight = 132.1; // lbs
  final double goalWeight = 140.0; // lbs
  final int dayStreak = 21;
  final double dailyAverageCalories = 2861;
  final double caloriesPercent = 90.0; // %
  final double goalProgress = 80.0; // %

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8), // 【Home準拠】背景色
      body: SafeArea(
        // メインコンテンツ（PC幅でもスマホ幅で中央表示）
        child: CenteredContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              const Text(
                '進捗',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 18), // 【Home準拠】セクション上下18px

              // 上部カード2枚（Weight / Day Streak）
              Row(
                children: [
                  Expanded(
                    child: _buildWeightCard(),
                  ),
                  const SizedBox(width: 12), // 【Home準拠】カード間12px
                  Expanded(
                    child: _buildDayStreakCard(),
                  ),
                ],
              ),

              const SizedBox(height: 14), // 【Home準拠】カード間14px

              // Weight Progressカード
              _buildWeightProgressCard(),

              const SizedBox(height: 14), // 【Home準拠】カード間14px

              // Daily Average Caloriesカード
              _buildDailyAverageCaloriesCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Weightカード
  Widget _buildWeightCard() {
    final progress = (currentWeight / goalWeight).clamp(0.0, 1.0);

    return _StyledCard(
      padding: const EdgeInsets.all(20),
      useSubtleBorder: false, // 【最終調整】主要カードは0.8（標準border）
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '現在の体重',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9AA5), // 【Home準拠】caption色
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${currentWeight.toStringAsFixed(1)} lbs',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          // プログレスバー
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9EF), // 【Home準拠】border色
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: progress * 100 - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '目標 ${goalWeight.toStringAsFixed(0)} lb',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9AA5), // 【Home準拠】caption色
            ),
          ),
          const SizedBox(height: 16),
          // Log Weightボタン
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '体重を記録',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Day Streakカード
  Widget _buildDayStreakCard() {
    // 曜日のチェック状態（ダミー）
    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    final checkedDays = [0, 1]; // 最初の2日がチェック済み

    return _StyledCard(
      padding: const EdgeInsets.all(20),
      useSubtleBorder: false, // 【最終調整】主要カードは0.8（標準border）
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 炎アイコン＋ストリーク数
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 32,
                  color: Color(0xFFFF9500),
                ),
                Positioned(
                  bottom: 8,
                  child: Text(
                    '$dayStreak',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '連続日数',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9AA5), // 【Home準拠】caption色
            ),
          ),
          const SizedBox(height: 12),
          // 曜日の円
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final isChecked = checkedDays.contains(index);

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isChecked
                      ? const Color(0xFF34C759)
                      : const Color(0xFFF6F6F8), // 【Home準拠】背景色
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isChecked
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A9AA5), // 【Home準拠】caption色
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Weight Progressカード
  Widget _buildWeightProgressCard() {
    return _StyledCard(
      useSubtleBorder: false, // 【最終調整】主要カードは0.8（標準border）
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（タイトル＋目標進捗）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '体重の推移',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.flag,
                    size: 18,
                    color: Color(0xFF34C759),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '目標の${goalProgress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18), // 【Home準拠】セクション上下18px

          // グラフエリア（プレースホルダー）
          _buildGraphPlaceholder(),

          const SizedBox(height: 16),

          // 期間切替ボタン
          Row(
            children: [
              Expanded(child: _buildTimeRangeButton('90日', '90D')),
              const SizedBox(width: 8),
              Expanded(child: _buildTimeRangeButton('6か月', '6M')),
              const SizedBox(width: 8),
              Expanded(child: _buildTimeRangeButton('1年', '1Y')),
              const SizedBox(width: 8),
              Expanded(child: _buildTimeRangeButton('全期間', 'ALL')),
            ],
          ),

          const SizedBox(height: 18), // 【Home準拠】セクション上下18px

          // 成功メッセージ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // 【最終調整】グリーンを薄く上品に（背景/線/文字が浮かない）
              color: const Color(0xFF34C759).withValues(alpha: 0.08), // より薄く
              borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
              border: Border.all(
                color: const Color(0xFF34C759).withValues(alpha: 0.12), // 【最終調整】より薄く
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF34C759).withValues(alpha: 0.7), // 【最終調整】薄め
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'いい調子！このまま続けましょう。',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF34C759).withValues(alpha: 0.7), // 【最終調整】薄め
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// グラフプレースホルダー
  Widget _buildGraphPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F8), // 【Home準拠】背景色
        borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
      ),
      child: Stack(
        children: [
          // Y軸ラベル
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['140', '135', '130', '125', '120'].map((label) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9A9AA5), // 【Home準拠】caption色
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // X軸ラベル
          Positioned(
            left: 40,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['6月', '7月', '8月', '9月', '10月', '11月'].map((label) {
                  return Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9A9AA5), // 【Home準拠】caption色
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // グラフエリア（簡易的な線グラフのプレースホルダー）
          Positioned.fill(
            left: 40,
            top: 20,
            right: 20,
            bottom: 30,
            child: CustomPaint(
              painter: _SimpleLineGraphPainter(),
            ),
          ),
          // ツールチップ（ダミー）
          Positioned(
            left: 200,
            top: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '131.2 lbs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '2025/9/9',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 期間切替ボタン
  Widget _buildTimeRangeButton(String label, String value) {
    final isSelected = selectedTimeRange == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeRange = value;
        });
      },
      child: Container(
        // 【最終調整】余白を+2px（詰まって見えないように）
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          // 【最終調整】選択中：白背景＋線薄め、非選択：透明寄り
          color: isSelected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE9E9EF).withValues(alpha: 0.6) // 【最終調整】選択中は線薄め
                : const Color(0xFFE9E9EF), // 非選択は標準
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700, // 【Home準拠】太め
              color: isSelected ? Colors.black : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Daily Average Caloriesカード
  Widget _buildDailyAverageCaloriesCard() {
    return _StyledCard(
      useSubtleBorder: false, // 【最終調整】主要カードは0.8（標準border）
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1日の平均カロリー',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7A7A86), // 【Home準拠】description色
            ),
          ),
          const SizedBox(height: 10), // 【Home準拠】数値周りの呼吸
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${dailyAverageCalories.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kcal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A7A86), // 【Home準拠】description色
                  ),
                ),
              ),
              const Spacer(),
              // 上矢印＋パーセンテージ（ピル型）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999), // 【Home準拠】ピル999
                  border: Border.all(
                    color: const Color(0xFF34C759).withValues(alpha: 0.25), // 【最終調整】ピル周りは0.6相当に
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: Color(0xFF34C759),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${caloriesPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 共通スタイルカード（Home準拠）
class _StyledCard extends StatelessWidget {
  const _StyledCard({
    required this.child,
    this.padding,
    this.useSubtleBorder = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool useSubtleBorder;

  @override
  Widget build(BuildContext context) {
    // 【Home準拠】浮き感の最適化：useSubtleBorder=trueの場合はより薄いborder
    final borderColor = useSubtleBorder
        ? const Color(0xFFE9E9EF).withValues(alpha: 0.6) // より薄く（60%）
        : const Color(0xFFE9E9EF).withValues(alpha: 0.8); // 標準（80%）
    
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22), // 【Home準拠】カード角丸22px
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// シンプルな線グラフのPainter（プレースホルダー）
class _SimpleLineGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF34C759)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // 簡単な波形を描画（ダミー）
    final path = Path();
    final width = size.width;
    final height = size.height;

    // 開始点
    path.moveTo(0, height * 0.7);

    // 波状の線を描画
    path.quadraticBezierTo(width * 0.2, height * 0.6, width * 0.4, height * 0.65);
    path.quadraticBezierTo(width * 0.6, height * 0.7, width * 0.8, height * 0.55);
    path.lineTo(width, height * 0.6);

    canvas.drawPath(path, paint);

    // データポイント（円）
    final dotPaint = Paint()
      ..color = const Color(0xFF34C759)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, height * 0.7),
      Offset(width * 0.2, height * 0.6),
      Offset(width * 0.4, height * 0.65),
      Offset(width * 0.6, height * 0.7),
      Offset(width * 0.8, height * 0.55),
      Offset(width, height * 0.6),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SimpleLineGraphPainter oldDelegate) => false;
}
