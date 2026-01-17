import 'package:flutter/material.dart';

/// Cal AI風Groups UI（コミュニティフィード型）
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
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
      userName: 'Cole Belvins',
      timestamp: 'Today at 3:49pm',
      mealName: 'Grilled Chicken with Avocado, Garlic Spinach, and Toast',
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
      userName: 'Devin Carroll',
      timestamp: 'Today at 3:26pm',
      mealName: 'Caesar Salad with Grilled Salmon',
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
      userName: 'Sarah Johnson',
      timestamp: 'Today at 2:15pm',
      mealName: 'Quinoa Bowl with Vegetables',
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
    const backgroundColor = Color(0xFFF6F6F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),

            // メインコンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // グループメンバー（ストーリー風）
                    _buildMembersSection(),

                    const SizedBox(height: 24),

                    // 投稿フィード
                    ...posts.map((post) => _buildPostCard(post)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左：グループ選択ピル
          GestureDetector(
            onTap: () {
              // ダミー処理
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 20,
                    color: Color(0xFF34C759),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Shred Squad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          // 右：フィルター/ソートボタン
          IconButton(
            icon: const Icon(Icons.tune, size: 24),
            onPressed: () {
              // ダミー処理
            },
          ),
        ],
      ),
    );
  }

  /// グループメンバーセクション（ストーリー風）
  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
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
                            color: Colors.black.withOpacity(0.05),
                            border: Border.all(
                              color: member.isCrown
                                  ? const Color(0xFFFFD700)
                                  : Colors.black.withOpacity(0.1),
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
                    const SizedBox(height: 8),
                    // ストリーク数
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Color(0xFFFF9500),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${member.streak}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 投稿カード
  Widget _buildPostCard(MealPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー情報ヘッダー
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // アバター
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Text(
                      post.userName[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // メニューボタン
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // 食事名
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.mealName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 料理画像
          Container(
            width: double.infinity,
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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

          const SizedBox(height: 16),

          // 栄養情報
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildNutrientInfo(
                    icon: Icons.local_fire_department,
                    value: '${post.calories}',
                    color: const Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientInfo(
                    icon: Icons.restaurant,
                    value: '${post.protein}g',
                    color: const Color(0xFFE53935),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientInfo(
                    icon: Icons.grain,
                    value: '${post.carbs}g',
                    color: const Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientInfo(
                    icon: Icons.circle,
                    value: '${post.fats}g',
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // リアクションとコメント
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // リアクション数
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: Color(0xFFFF9500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.reactions}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // スター数
                if (post.stars > 0) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.stars}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
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
                    label: 'React',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                // Comment ボタン
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),

          // コメント数
          if (post.comments > 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  'View ${post.comments} comment${post.comments > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 栄養情報アイテム
  Widget _buildNutrientInfo({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
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

