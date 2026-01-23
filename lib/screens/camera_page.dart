import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Cal AI風Camera UI
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // 表示文字列（i18n未導入のため直書き）
  String selectedMode = '食事を撮影'; // 食事を撮影 / バーコード / 成分表示

  // 食材ラベルのデータ（ダミー）
  final List<FoodLabel> foodLabels = [
    FoodLabel(
      name: 'レタス',
      position: Offset(0.25, 0.35), // 相対位置（0.0-1.0）
      anchorPosition: Offset(0.3, 0.4), // ラベルが指す位置
    ),
    FoodLabel(
      name: 'パルメザン',
      position: Offset(0.65, 0.3),
      anchorPosition: Offset(0.6, 0.35),
    ),
    FoodLabel(
      name: 'ミニトマト',
      position: Offset(0.45, 0.55),
      anchorPosition: Offset(0.5, 0.6),
    ),
    FoodLabel(
      name: 'クルトン',
      position: Offset(0.75, 0.6),
      anchorPosition: Offset(0.7, 0.65),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // メインコンテンツ
            Column(
              children: [
                // 上部コントロールバー
                _buildTopBar(),
                
                // 中央の料理写真エリア（ダミー）
                Expanded(
                  child: _buildFoodViewArea(),
                ),
                
                // 下部コントロールバー
                _buildBottomControls(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 上部コントロールバー（× / Cal AIロゴ / ?）
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 【Home準拠】左右16px
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ×ボタン（閉じる）
          _buildCircleButton(
            icon: Icons.close,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          
          // Cal AIロゴ
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    '🍎',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Cal AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700, // 【Home準拠】太め
                ),
              ),
            ],
          ),
          
          // ?ボタン（ヘルプ）
          _buildCircleButton(
            icon: Icons.help_outline,
            onTap: () {
              // ダミー処理
            },
          ),
        ],
      ),
    );
  }

  /// 円形ボタン
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), // 黒半透明
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 料理写真エリア（ダミー背景）
  Widget _buildFoodViewArea() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16), // 【Home準拠】左右16px
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // 暗い背景
        borderRadius: BorderRadius.circular(18), // 【Home準拠】内側角丸18px
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18), // 【Home準拠】内側角丸18px
        child: LayoutBuilder(
          builder: (context, constraints) {
            final areaWidth = constraints.maxWidth;
            final areaHeight = constraints.maxHeight;
            
            return Stack(
              fit: StackFit.expand,
              children: [
                // ダミー背景（シーザーサラダ風）
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF2C2C2C),
                        const Color(0xFF1A1A1A),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // サラダのアイコン表示
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            size: 80,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'シーザーサラダ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                            fontWeight: FontWeight.w600, // 【Home準拠】太め
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 食材ラベルのオーバーレイ
                ...foodLabels.map((label) {
                  final labelX = label.position.dx * areaWidth;
                  final labelY = label.position.dy * areaHeight;
                  final anchorX = label.anchorPosition.dx * areaWidth;
                  final anchorY = label.anchorPosition.dy * areaHeight;
                  
                  return Positioned(
                    left: labelX,
                    top: labelY,
                    child: _FoodLabelWidget(
                      label: label.name,
                      anchorPoint: Offset(
                        anchorX - labelX,
                        anchorY - labelY,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 下部コントロールバー
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // 【Home準拠】左右16px、下部18px
      child: Column(
        children: [
          // モード切替
          _buildModeSelector(),
          
          const SizedBox(height: 24),
          
          // アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 左：フラッシュボタン
              _buildActionButton(
                icon: Icons.flash_on,
                onTap: () {},
              ),
              
              // 中央：シャッターボタン
              _buildShutterButton(),
              
              // 右：ギャラリーボタン
              _buildActionButton(
                icon: Icons.photo_library_outlined,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// モード切替（食事を撮影 / バーコード / 成分表示）
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3), // 【Home準拠】黒半透明背景
        borderRadius: BorderRadius.circular(999), // 【Home準拠】ピル999
        border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), // 【Home準拠】薄い線（#E9E9EF相当の白版）
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('食事を撮影', Icons.camera_alt, '食事を撮影'),
          const SizedBox(width: 4),
          _buildModeButton('バーコード', Icons.qr_code_scanner, 'バーコード'),
          const SizedBox(width: 4),
          _buildModeButton('成分表示', Icons.description, '成分表示'),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, IconData icon, String mode) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // 【Home準拠】選択中：白地、非選択：黒半透明
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999), // 【Home準拠】ピル999
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              // 【Home準拠】選択中：黒文字、非選択：白文字
              color: isSelected ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                // 【Home準拠】選択中：黒文字、非選択：白文字
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700, // 【Home準拠】太め
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// アクションボタン（フラッシュ/ギャラリー）
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), // 黒半透明
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// シャッターボタン（白外枠＋黒内円）
  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: () {
        // ダミー処理
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// 食材ラベルのデータモデル
class FoodLabel {
  final String name;
  final Offset position; // ラベルの位置（相対座標 0.0-1.0）
  final Offset anchorPosition; // ラベルが指す位置（相対座標 0.0-1.0）

  FoodLabel({
    required this.name,
    required this.position,
    required this.anchorPosition,
  });
}

/// 食材ラベルウィジェット（吹き出し型）
class _FoodLabelWidget extends StatelessWidget {
  final String label;
  final Offset anchorPoint; // ラベルからアンカーポイントへの相対オフセット

  const _FoodLabelWidget({
    required this.label,
    required this.anchorPoint,
  });

  @override
  Widget build(BuildContext context) {
    // アンカーポイントの方向を計算
    final angle = math.atan2(anchorPoint.dy, anchorPoint.dx);
    final distance = math.sqrt(
      anchorPoint.dx * anchorPoint.dx + anchorPoint.dy * anchorPoint.dy,
    );
    
    // ラベルの位置を調整（アンカーポイントから離す）
    final labelOffset = Offset(
      -math.cos(angle) * (distance + 10),
      -math.sin(angle) * (distance + 10),
    );
    
    return Transform.translate(
      offset: labelOffset,
      child: CustomPaint(
        painter: _LabelPainter(
          anchorPoint: anchorPoint,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // 【Home準拠】白っぽい半透明＋薄い線
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999), // 【Home準拠】ピル型（radius 999）
            border: Border.all(
              color: const Color(0xFFE9E9EF).withValues(alpha: 0.5), // 【Home準拠】薄い線
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w700, // 【Home準拠】太め
            ),
          ),
        ),
      ),
    );
  }
}

/// ラベルからアンカーポイントへの線を描画するPainter
class _LabelPainter extends CustomPainter {
  final Offset anchorPoint;

  _LabelPainter({required this.anchorPoint});

  @override
  void paint(Canvas canvas, Size size) {
    // 【Home準拠】線の色を薄く
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final endPoint = center + anchorPoint;

    // 線を描画
    canvas.drawLine(center, endPoint, paint);

    // アンカーポイントに円を描画
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(endPoint, 4, circlePaint);
  }

  @override
  bool shouldRepaint(_LabelPainter oldDelegate) {
    return oldDelegate.anchorPoint != anchorPoint;
  }
}
