import 'package:flutter/material.dart';
import '../widgets/centered_content.dart';
import '../theme/ui_constants.dart';
import '../widgets/tappable.dart';

/// Cal AI風Groups UI（コミュニティフィード型）
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  // 表示文字列（i18n未導入のため直書き）
  String selectedGroup = '全て'; // 全て / 友達 / チーム

  // ダミーデータ
  final List<GroupMember> members = [
    GroupMember(name: 'Alex', streak: 31, avatar: '👑', isCrown: true),
    GroupMember(name: 'Mike', streak: 24, avatar: '💪'),
    GroupMember(name: 'Tom', streak: 12, avatar: '🔥'),
    GroupMember(name: 'V', streak: 11, avatar: 'V'),
    GroupMember(name: 'Sam', streak: 2, avatar: '😊'),
  ];

  final List<MealPost> posts = [
    MealPost(
      userName: 'コール',
      timestamp: '今日 15:49',
      mealName: '鶏肉とアボカド',
      imagePlaceholder: true,
      calories: 480,
      protein: 38,
      carbs: 23,
      fats: 24,
      reactions: 4,
      stars: 1,
      comments: 2,
    ),
    MealPost(
      userName: 'デビン',
      timestamp: '今日 15:26',
      mealName: 'サーモンのシーザーサラダ',
      imagePlaceholder: true,
      calories: 520,
      protein: 42,
      carbs: 28,
      fats: 26,
      reactions: 6,
      stars: 2,
      comments: 3,
    ),
    MealPost(
      userName: 'サラ',
      timestamp: '今日 14:15',
      mealName: '野菜のキヌアボウル',
      imagePlaceholder: true,
      calories: 380,
      protein: 15,
      carbs: 55,
      fats: 12,
      reactions: 3,
      stars: 0,
      comments: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.colorBackground, // 【Home準拠】背景色
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（グループ選択ピル）
            _buildHeader(),

            // メインコンテンツ（PC幅でもスマホ幅で中央表示）
            Expanded(
              child: CenteredContent(
                padding: const EdgeInsets.only(top: 18, bottom: 16, left: 16, right: 16), // 【最終調整】ヘッダー下18px
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // グループメンバー（ストーリー風）
                    _buildMembersSection(),

                    const SizedBox(height: UIConstants.spacingSection), // 【最終調整】セクション間18px

                    // 投稿フィード
                    ...posts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final post = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < posts.length - 1 ? 14 : 0, // 【Home準拠】カード間14px
                        ),
                        child: _buildPostCard(post),
                      );
                    }),
                    
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

  /// ヘッダー（グループ選択ピル）
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 【Home準拠】左右16px
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: UIConstants.colorBorder, // 【Home準拠】border色
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左：グループ選択ピル
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                      _buildGroupPill('全て', '全て'),
                  const SizedBox(width: 8),
                      _buildGroupPill('友達', '友達'),
                  const SizedBox(width: 8),
                      _buildGroupPill('チーム', 'チーム'),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 右：フィルター/ソートボタン
          IconButton(
            icon: const Icon(Icons.tune, size: 24),
            color: Colors.black,
            onPressed: () {
              // ダミー処理
            },
          ),
        ],
      ),
    );
  }

  /// グループ選択ピル
  Widget _buildGroupPill(String label, String value) {
    final isSelected = selectedGroup == value;
    return TappablePill(
      onTap: () {
        setState(() {
          selectedGroup = value;
        });
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          // 【最終調整】選択中：白背景＋線薄め、非選択：透明＋線薄め
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(UIConstants.radiusPill), // 【Home準拠】ピル999
          border: Border.all(
            color: UIConstants.colorBorder.withValues(alpha: 0.6), // 【最終調整】線を薄め
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700, // 【Home準拠】太め
            color: isSelected ? Colors.black : Colors.black,
          ),
        ),
      ),
    );
  }

  /// グループメンバーセクション（ストーリー風）
  Widget _buildMembersSection() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Container(
            width: 80,
            margin: EdgeInsets.only(
              right: index < members.length - 1 ? 12 : 0, // 最後の要素以外にmargin
            ),
            child: Column(
              children: [
                // アバター
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: UIConstants.colorBackground, // 【Home準拠】背景色
                        border: Border.all(
                          color: member.isCrown
                              ? const Color(0xFFFFD700)
                              : UIConstants.colorBorder, // 【Home準拠】border色（薄線）
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          member.avatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    if (member.isCrown)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: UIConstants.spacingText), // 【最終調整】アバター下のバッジとの距離10px
                // ストリーク数（ピル型バッジ）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // 【最終調整】主張しすぎ防止：背景/線を薄く
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(UIConstants.radiusPill), // 【Home準拠】ピル999
                    border: Border.all(
                      color: UIConstants.colorBorder.withValues(alpha: 0.6), // 【最終調整】線を薄く
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Color(0xFFFF9500),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${member.streak}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 投稿カード
  Widget _buildPostCard(MealPost post) {
    // 【タップ感統一】投稿カード全体をTappableで統一
    return Tappable(
      onTap: () {
        // ダミー処理
      },
      borderRadius: BorderRadius.circular(UIConstants.radiusCard),
      child: _StyledCard(
        padding: EdgeInsets.zero,
        useSubtleBorder: false, // 【Home準拠】主要カードは0.8（標準border）
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報ヘッダー
          Padding(
            padding: const EdgeInsets.all(16), // 【Home準拠】内側余白
            child: Row(
              children: [
                // アバター
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: UIConstants.colorBackground, // 【Home準拠】背景色
                  ),
                  child: Center(
                    child: Text(
                      post.userName[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700, // 【Home準拠】太め
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 名前＋タイムスタンプ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500, // 【視線誘導】ユーザー名を弱め（w700 → w500）
                          color: Colors.black.withValues(alpha: 0.5), // 【視線誘導】補足情報を最弱（opacity 0.5）
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.5), // 【視線誘導】時間を最弱（opacity 0.5）
                        ),
                      ),
                    ],
                  ),
                ),
                // メニューボタン
                TappableIcon(
                  icon: Icons.more_vert,
                  size: 20,
                  color: Colors.black.withValues(alpha: 0.5), // 【視線誘導】メニューボタンを弱め
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 10), // 【最終調整】ヘッダー ↔ 食事名：10px

          // 食事名
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.mealName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.6), // 【視線誘導】食事名を弱め（写真を主役に）
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 10), // 【最終調整】余白リズム：10px

          // 料理画像
          Container(
            width: double.infinity,
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
              child: Container(
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
                      const SizedBox(height: 16),
                      Text(
                        post.mealName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w600, // 【Home準拠】太め
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: UIConstants.spacingCard), // 【最終調整】余白リズム：14px

          // 栄養情報（Calories強調）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calories強調
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 20,
                      color: const Color(0xFFFF9500).withValues(alpha: 0.7), // 【視線誘導】Caloriesアイコンを弱め（主張しすぎない）
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.calories}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700, // 【Home準拠】太字
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'カロリー',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.63), // 【視線誘導】単位を弱め（opacity 0.63）
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: UIConstants.spacingText), // 【最終調整】Calories ↔ P/C/F：10px

                // P/C/F 行（Homeマクロと同じ規格、折り返しOK）
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMacroPill(
                      icon: Icons.restaurant,
                      value: '${post.protein}g',
                      color: const Color(0xFFE53935),
                    ),
                    _buildMacroPill(
                      icon: Icons.grain,
                      value: '${post.carbs}g',
                      color: const Color(0xFFFF9500),
                    ),
                    _buildMacroPill(
                      icon: Icons.circle,
                      value: '${post.fats}g',
                      color: const Color(0xFF007AFF),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: UIConstants.spacingCard), // 【最終調整】余白リズム：14px

          // リアクションとコメント
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // リアクション数
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: const Color(0xFFFF9500).withValues(alpha: 0.6), // 【視線誘導】アイコンを弱め
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.reactions}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500, // 【視線誘導】アクションを弱め（w700 → w500）
                        color: Colors.black.withValues(alpha: 0.58), // 【視線誘導】色を弱め（opacity 0.58）
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // スター数
                if (post.stars > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 18,
                        color: const Color(0xFFFFD700).withValues(alpha: 0.6), // 【視線誘導】アイコンを弱め
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.stars}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // 【視線誘導】アクションを弱め（w700 → w500）
                          color: Colors.black.withValues(alpha: 0.58), // 【視線誘導】色を弱め（opacity 0.58）
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                // React ボタン
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.emoji_emotions_outlined,
                    label: '反応',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                // Comment ボタン
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'コメント',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),

          // コメント数
          if (post.comments > 0) ...[
            const SizedBox(height: 10), // 【最終調整】余白リズム：10px
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Tappable(
                onTap: () {},
                minSize: 0, // テキストなのでタップ領域は自動
                child: Text(
                  'コメントを${post.comments}件見る',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500, // 【視線誘導】補足情報を弱め（w600 → w500）
                    color: Colors.black.withValues(alpha: 0.5), // 【視線誘導】補足情報を最弱（opacity 0.5）
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: UIConstants.spacingCard), // 【最終調整】カード下部余白：14px（カード間14pxに統一）
        ],
      ),
      ),
    );
  }

  /// マクロピル（Homeマクロカードと同じ規格）
  Widget _buildMacroPill({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // 【最終調整】P/C/Fは補助的に：背景/線を薄く（主従関係を明確に）
        color: color.withValues(alpha: 0.08), // 背景をより薄く
        borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
        border: Border.all(
          color: color.withValues(alpha: 0.15), // 【最終調整】borderをsubtle寄り（0.6相当）
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.7)), // 【視線誘導】アイコンを弱め（主張しすぎない）
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600, // 【視線誘導】P/C/F数値を弱め（w700 → w600）
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // 【タップ感統一】Tappableで統一
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.radiusInner),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent, // 背景を透明に
          border: Border.all(
            color: UIConstants.colorBorder.withValues(alpha: 0.6), // 【最終調整】borderを控えめに
            width: 1,
          ),
          borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black.withValues(alpha: 0.58)), // 【視線誘導】アイコンを弱め（opacity 0.58）
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500, // 【視線誘導】アクションを弱め（w700 → w500）
                color: Colors.black.withValues(alpha: 0.58), // 【視線誘導】色を弱め（opacity 0.58）
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
    this.useSubtleBorder = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool useSubtleBorder;

  @override
  Widget build(BuildContext context) {
    // 【Home準拠】浮き感の最適化
    final borderColor = useSubtleBorder
        ? UIConstants.colorBorder.withValues(alpha: 0.6) // より薄く（60%）
        : UIConstants.colorBorder.withValues(alpha: 0.8); // 標準（80%）
    
    return Container(
      padding: padding,
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

/// グループメンバーのデータモデル
class GroupMember {
  final String name;
  final int streak;
  final String avatar;
  final bool isCrown;

  GroupMember({
    required this.name,
    required this.streak,
    required this.avatar,
    this.isCrown = false,
  });
}

/// 食事投稿のデータモデル
class MealPost {
  final String userName;
  final String timestamp;
  final String mealName;
  final bool imagePlaceholder;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int reactions;
  final int stars;
  final int comments;

  MealPost({
    required this.userName,
    required this.timestamp,
    required this.mealName,
    required this.imagePlaceholder,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.reactions,
    required this.stars,
    required this.comments,
  });
}
