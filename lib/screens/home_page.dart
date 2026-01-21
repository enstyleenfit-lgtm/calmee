import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/centered_content.dart';

/// Cal AI風Home UI
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();

  // ダミーデータ
  final int caloriesEaten = 1250;
  final int caloriesTarget = 2500;
  
  final int proteinEaten = 75;
  final int proteinTarget = 150;
  
  final int carbsEaten = 138;
  final int carbsTarget = 275;
  
  final int fatEaten = 35;
  final int fatTarget = 70;

  final int streak = 15;

  // 最近の食事（ダミー）
  final List<Map<String, dynamic>> recentMeals = [
    {
      'name': 'サーモンのグリル',
      'calories': 550,
      'protein': 35,
      'carbs': 40,
      'fat': 28,
      'time': '12:37',
      'imageUrl': null,
    },
  ];

  // 曜日リストを生成（今日を中心に前後3日）
  List<DateTime> get _weekDates {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday % 7));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  String _getDayName(DateTime date) {
    // 表示文字列（i18n未導入のため直書き）
    const days = ['日', '月', '火', '水', '木', '金', '土'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // 上部ヘッダー
            _buildHeader(),
            
            // 曜日ストリップ
            _buildWeekStrip(),
            
            const SizedBox(height: 16),
            
            // メインコンテンツ（PC幅でもスマホ幅で中央表示）
            Expanded(
              child: CenteredContent(
                padding: const EdgeInsets.symmetric(horizontal: 16), // vertical paddingは不要
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 大きなCaloriesカード
                    _buildCaloriesCard(),
                    
                    const SizedBox(height: 14),
                    
                    // マクロ3カード
                    _buildMacroCards(),
                    
                    const SizedBox(height: 18),
                    
                    // Recently uploaded
                    _buildRecentlyUploaded(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 上部ヘッダー（アプリアイコン + タイトル + 炎アイコンのピル）
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // アプリアイコン + タイトル
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    '🍎',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cal AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          
          // 炎アイコンのピル
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 18,
                  color: Color(0xFFFF9500),
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 曜日ストリップ（丸い日付、選択状態あり）
  Widget _buildWeekStrip() {
    final dates = _weekDates;
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final dayName = _getDayName(date);
          final dayNumber = date.day;
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.black
                          : const Color(0xFF9A9AA5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.black : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? Colors.black
                            : const Color(0xFFE9E9EF),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 大きなCaloriesカード（左数値 + 右リング）
  Widget _buildCaloriesCard() {
    final progress = (caloriesEaten / caloriesTarget).clamp(0.0, 1.0);
    
    // 【最終調整】数値と説明文の間を10pxに（情報密度の最適化）
    return _StyledCard(
      useSubtleBorder: true, // より薄いborderを使用
      child: Row(
        children: [
          // 左：数値
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$caloriesEaten/$caloriesTarget',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10), // 8px → 10px（最終調整：数値周りの呼吸）
                Text(
                  '摂取カロリー',
                  style: _TextStyles.description,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 右：リング
          // 【最終調整】リングサイズを控えめに（視線誘導最適化）
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景円
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 7,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFE9E9EF),
                    ),
                  ),
                ),
                // プログレス円
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF007AFF),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // 中央アイコン
                const Icon(
                  Icons.water_drop,
                  size: 26,
                  color: Color(0xFF007AFF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// マクロ3カード（Protein / Carbs / Fat）
  Widget _buildMacroCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            label: 'たんぱく質',
            current: proteinEaten,
            target: proteinTarget,
            unit: 'g',
            color: const Color(0xFFE53935),
            icon: Icons.restaurant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroCard(
            label: '炭水化物',
            current: carbsEaten,
            target: carbsTarget,
            unit: 'g',
            color: const Color(0xFFFF9500),
            icon: Icons.grain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroCard(
            label: '脂質',
            current: fatEaten,
            target: fatTarget,
            unit: 'g',
            color: const Color(0xFF007AFF),
            icon: Icons.circle,
          ),
        ),
      ],
    );
  }

  /// 個別マクロカード（半円メーター）
  Widget _buildMacroCard({
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return _StyledCard(
      padding: const EdgeInsets.all(16),
      useSubtleBorder: true, // より薄いborderを使用
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 半円メーター
          SizedBox(
            height: 70,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 70),
                  painter: _SemiCircleProgressPainter(
                    progress: progress,
                    color: color,
                    backgroundColor: const Color(0xFFE9E9EF),
                  ),
                ),
                Positioned(
                  top: 20,
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          
          // 【最終調整】メーターと数値の間を14px維持
          const SizedBox(height: 14),
          
          // 数値
          Text(
            '$current/$target$unit',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          
          // 【最終調整】数値とラベルの間を8pxに（6px → 8px：情報密度の最適化）
          const SizedBox(height: 8),
          
          // ラベル
          Text(
            label,
            style: _TextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Recently uploaded食事カードリスト
  Widget _buildRecentlyUploaded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近追加した食事',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        // 【最終調整】見出し下の余白を10pxに（8〜12pxの最適値）
        const SizedBox(height: 10),
        
        ...recentMeals.map((meal) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMealCard(meal),
        )),
      ],
    );
  }

  /// 個別食事カード
  Widget _buildMealCard(Map<String, dynamic> meal) {
    // 【最終調整】InkWell化でクリック感を向上（リップル効果）
    return InkWell(
      onTap: () {
        // ダミー処理
      },
      borderRadius: BorderRadius.circular(22),
      child: _StyledCard(
        padding: const EdgeInsets.all(16),
        // 食事カードは標準のborderで（浮き感のバランス）
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像プレースホルダー
            // 【最終調整】画像部分のborder無し（カードのborderで十分、浮き感向上）
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: meal['imageUrl'] != null
                    ? Image.network(
                        meal['imageUrl'],
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 36,
                          color: Color(0xFF9A9AA5),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // 情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          meal['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          meal['time'],
                          style: _TextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: Color(0xFFFF9500),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${meal['calories']} kcal',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // マクロ情報
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _buildMacroInfo(
                        Icons.restaurant,
                        '${meal['protein']}g',
                        const Color(0xFFE53935),
                      ),
                      _buildMacroInfo(
                        Icons.grain,
                        '${meal['carbs']}g',
                        const Color(0xFFFF9500),
                      ),
                      _buildMacroInfo(
                        Icons.circle,
                        '${meal['fat']}g',
                        const Color(0xFF007AFF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInfo(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: _TextStyles.caption,
        ),
      ],
    );
  }
}

/// 共通スタイルカード
class _StyledCard extends StatelessWidget {
  const _StyledCard({
    required this.child,
    this.padding,
    this.useSubtleBorder = false, // 【最終調整】より薄いborderオプション
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool useSubtleBorder; // 浮き感を最適化するための薄いborder

  @override
  Widget build(BuildContext context) {
    // 【最終調整】浮き感の最適化：useSubtleBorder=trueの場合はより薄いborder、falseの場合は標準
    final borderColor = useSubtleBorder
        ? const Color(0xFFE9E9EF).withValues(alpha: 0.6) // より薄く（60%）
        : const Color(0xFFE9E9EF).withValues(alpha: 0.8); // 標準（80%）
    
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// 共通テキストスタイル
class _TextStyles {
  static const description = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Color(0xFF7A7A86),
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF9A9AA5),
  );
}

/// 半円プログレスメーターのCustomPainter
class _SemiCircleProgressPainter extends CustomPainter {
  _SemiCircleProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    const strokeWidth = 8.0;

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
      ..color = color
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
  bool shouldRepaint(_SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
