import 'package:flutter/material.dart';

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
    const backgroundColor = Color(0xFFF6F6F8);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              // 上部カード2枚（Weight / Day Streak）
              Row(
                children: [
                  Expanded(
                    child: _buildWeightCard(cardColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDayStreakCard(cardColor),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Weight Progressカード
              _buildWeightProgressCard(cardColor),

              const SizedBox(height: 20),

              // Daily Average Caloriesカード
              _buildDailyAverageCaloriesCard(cardColor),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Weightカード
  Widget _buildWeightCard(Color cardColor) {
    final progress = (currentWeight / goalWeight).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Weight',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.6),
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
                  color: Colors.black.withOpacity(0.1),
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
            'Goal ${goalWeight.toStringAsFixed(0)} lbs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.5),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Log Weight',
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
  Widget _buildDayStreakCard(Color cardColor) {
    // 曜日のチェック状態（ダミー）
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final checkedDays = [0, 1]; // 最初の2日がチェック済み

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 炎アイコン＋ストリーク数
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
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
            'Day Streak',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.6),
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
                      : Colors.black.withOpacity(0.05),
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.4),
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
  Widget _buildWeightProgressCard(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（タイトル＋目標進捗）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight Progress',
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
                    '${goalProgress.toStringAsFixed(0)}% of goal',
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

          const SizedBox(height: 24),

          // グラフエリア（プレースホルダー）
          _buildGraphPlaceholder(),

          const SizedBox(height: 16),

          // 期間切替ボタン
          Row(
            children: [
              _buildTimeRangeButton('90D', '90D'),
              const SizedBox(width: 8),
              _buildTimeRangeButton('6M', '6M'),
              const SizedBox(width: 8),
              _buildTimeRangeButton('1Y', '1Y'),
              const SizedBox(width: 8),
              _buildTimeRangeButton('ALL', 'ALL'),
            ],
          ),

          const SizedBox(height: 20),

          // 成功メッセージ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34C759),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Great job! Consistency is key, and you\'re mastering it!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF34C759),
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
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.4),
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
                children: ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'].map((label) {
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.4),
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
                borderRadius: BorderRadius.circular(8),
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
                    'Sep 9, 2025',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
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
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTimeRange = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.black
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Daily Average Caloriesカード
  Widget _buildDailyAverageCaloriesCard(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Average Calories',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
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
                  'cal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
              const Spacer(),
              // 上矢印＋パーセンテージ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
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

