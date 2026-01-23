import 'package:flutter/material.dart';
import '../theme/ui_constants.dart';
import '../widgets/tappable.dart';

/// Cal AI風食事詳細ボトムシート
class MealDetailSheet extends StatelessWidget {
  const MealDetailSheet({super.key});

  // ダミーデータ
  static const mealName = 'シーザーサラダ（ミニトマト）';
  static const timestamp = '18:21';
  static const calories = 330;
  static const protein = 8; // g
  static const carbs = 20; // g
  static const fats = 18; // g
  static const quantity = 1;

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MealDetailSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: UIConstants.colorBackground, // 【Home準拠】背景色を#F6F6F8に
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // ドラッグハンドル
              _buildDragHandle(),
              
              // スクロール可能なコンテンツ
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16), // 【Home準拠】左右16px
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 上部の料理画像
                      _buildFoodImage(context),
                      
                      const SizedBox(height: UIConstants.spacingSection), // 【Home準拠】セクション間18px
                      
                      // 食事名＋数量ステッパー
                      _buildMealHeader(),
                      
                      const SizedBox(height: UIConstants.spacingSection), // 【Home準拠】セクション間18px
                      
                      // 大きなCalories表示カード
                      _buildCaloriesCard(),
                      
                      const SizedBox(height: UIConstants.spacingCard), // 【Home準拠】カード間14px
                      
                      // Protein / Carbs / Fats の横並び
                      _buildMacroCards(),
                      
                      const SizedBox(height: UIConstants.spacingSection), // 【Home準拠】セクション間18px
                      
                      // Ingredientsリスト
                      _buildIngredientsSection(),
                      
                      const SizedBox(height: 100), // ボタン分の余白
                    ],
                  ),
                ),
              ),
              
              // 下部の固定ボタン
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  /// ドラッグハンドル
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 上部の料理画像
  Widget _buildFoodImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18), // 【Home準拠】角丸18px
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18), // 【Home準拠】角丸18px
        child: Stack(
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 60,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 上部ナビゲーションバー
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TappableIcon(
                      icon: Icons.arrow_back,
                      color: Colors.white,
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const Text(
                      '栄養',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        TappableIcon(
                          icon: Icons.share,
                          color: Colors.white,
                          onTap: () {},
                        ),
                        TappableIcon(
                          icon: Icons.more_vert,
                          color: Colors.white,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 食事名＋数量ステッパー
  Widget _buildMealHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左：ブックマークアイコン＋タイムスタンプ＋食事名
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_border,
                    size: 16,
                    color: UIConstants.colorCaption, // 【Home準拠】caption色
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: UIConstants.colorCaption, // 【Home準拠】caption色
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingText), // 【Home準拠】数値周りの呼吸（8px → 10px）
              Text(
                mealName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 右：数量ステッパー
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: UIConstants.colorBorder, // 【Home準拠】border色
              width: 1,
            ),
            borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
          ),
          child: Row(
            children: [
              // -ボタン
              Tappable(
                onTap: () {},
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(UIConstants.radiusInner),
                ),
                minSize: 0, // paddingでタップ領域確保
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              
              // 数値
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              
              // +ボタン
              Tappable(
                onTap: () {},
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(UIConstants.radiusInner),
                ),
                minSize: 0, // paddingでタップ領域確保
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 大きなCalories表示カード
  Widget _buildCaloriesCard() {
    return _StyledCard(
      useSubtleBorder: true, // 【Home準拠】より薄いborder（opacity 0.6）
      child: Row(
        children: [
          // 左：フレームアイコン
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 32,
              color: Color(0xFFFF9500),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // 右：Caloriesテキスト＋数値
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'カロリー',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: UIConstants.colorDescription, // 【Home準拠】description色
                  ),
                ),
                const SizedBox(height: UIConstants.spacingText), // 【Home準拠】数値周りの呼吸（4px → 10px）
                Text(
                  '$calories',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Protein / Carbs / Fats の横並び
  Widget _buildMacroCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            label: 'たんぱく質',
            value: '$protein',
            unit: 'g',
            color: const Color(0xFFE53935),
            icon: Icons.restaurant,
          ),
        ),
        const SizedBox(width: 12), // 【Home準拠】カード間12px
        Expanded(
          child: _buildMacroCard(
            label: '炭水化物',
            value: '$carbs',
            unit: 'g',
            color: const Color(0xFFFF9500),
            icon: Icons.grain,
          ),
        ),
        const SizedBox(width: 12), // 【Home準拠】カード間12px
        Expanded(
          child: _buildMacroCard(
            label: '脂質',
            value: '$fats',
            unit: 'g',
            color: const Color(0xFF007AFF),
            icon: Icons.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return _StyledCard(
      padding: const EdgeInsets.all(16), // 【Home準拠】マクロカードと同じpadding
      useSubtleBorder: true, // 【Home準拠】より薄いborder
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: UIConstants.spacingLabel),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9AA5), // 【Home準拠】caption色
            ),
          ),
          const SizedBox(height: UIConstants.spacingLabel), // 【Home準拠】数値周りの呼吸（4px → 8px）
          Text(
            '$value$unit',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Ingredientsリスト
  Widget _buildIngredientsSection() {
    // ダミーIngredientsデータ
    final ingredients = [
      {'name': 'レタス', 'calories': 20, 'amount': '1.5カップ'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '材料',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                '+ 追加',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 10), // 【Home準拠】見出し下10px
        
        // Ingredientsリスト
        ...ingredients.map((ingredient) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12), // 【Home準拠】カード間12px
            child: _StyledCard(
              padding: const EdgeInsets.all(16),
              useSubtleBorder: false, // 【Home準拠】標準border（食事カードと同様）
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左：名前＋カロリー
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: UIConstants.colorBackground,
                            borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
                          ),
                          child: const Icon(
                            Icons.circle,
                            size: 24,
                            color: UIConstants.colorCaption, // 【Home準拠】caption色
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ingredient['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                              '• ${ingredient['calories']} kcal',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: UIConstants.colorCaption, // 【Home準拠】caption色
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 右：数量
                  Text(
                    ingredient['amount'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 下部の固定ボタン
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // 【Home準拠】左右16px
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE9E9EF), // 【Home準拠】border色
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 左：Fix Resultsボタン（Outlined）
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  '結果を修正',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(
                    color: Color(0xFFE9E9EF), // 【Home準拠】border色
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12), // 【Home準拠】カード間12px
            
            // 右：Doneボタン（黒Filled）
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
                  ),
                ),
                child: const Text(
                  '完了',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

/// 共通スタイルカード（Home準拠）
class _StyledCard extends StatelessWidget {
  const _StyledCard({
    required this.child,
    this.padding,
    this.useSubtleBorder = false, // 【Home準拠】subtle borderオプション
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool useSubtleBorder;

  @override
  Widget build(BuildContext context) {
    // 【Home準拠】浮き感の最適化：useSubtleBorder=trueの場合はより薄いborder
    final borderColor = useSubtleBorder
        ? UIConstants.colorBorder.withValues(alpha: 0.6) // より薄く（60%）
        : UIConstants.colorBorder.withValues(alpha: 0.8); // 標準（80%）
    
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusCard), // 【Home準拠】カード角丸22px
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
