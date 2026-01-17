import 'package:flutter/material.dart';

/// Cal AI風食事詳細ボトムシート
class MealDetailSheet extends StatelessWidget {
  const MealDetailSheet({super.key});

  // ダミーデータ
  static const mealName = 'Caesar Salad with Cherry Tomatoes';
  static const timestamp = '6:21 PM';
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
            color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 上部の料理画像
                      _buildFoodImage(),
                      
                      const SizedBox(height: 24),
                      
                      // 食事名＋数量ステッパー
                      _buildMealHeader(),
                      
                      const SizedBox(height: 24),
                      
                      // 大きなCalories表示カード
                      _buildCaloriesCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Protein / Carbs / Fats の横並び
                      _buildMacroCards(),
                      
                      const SizedBox(height: 24),
                      
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
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 上部の料理画像
  Widget _buildFoodImage() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Text(
                      'Nutrition',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {},
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
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              color: Colors.black.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // -ボタン
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 大きなCalories表示カード
  Widget _buildCaloriesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左：フレームアイコン
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
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
                  'Calories',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
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
            label: 'Protein',
            value: '$protein',
            unit: 'g',
            color: const Color(0xFFE53935),
            icon: Icons.restaurant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroCard(
            label: 'Carbs',
            value: '$carbs',
            unit: 'g',
            color: const Color(0xFFFF9500),
            icon: Icons.grain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroCard(
            label: 'Fats',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
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
      {'name': 'Lettuce', 'calories': 20, 'amount': '1.5 cups'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                '+ Add more',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Ingredientsリスト
        ...ingredients.map((ingredient) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
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
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 24,
                          color: Colors.black38,
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
                            const SizedBox(height: 2),
                            Text(
                              '• ${ingredient['calories']} cal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black.withOpacity(0.5),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 下部の固定ボタン
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 左：Fix Resultsボタン（白背景）
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  'Fix Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Colors.black.withOpacity(0.2),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 右：Doneボタン（黒背景）
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
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

