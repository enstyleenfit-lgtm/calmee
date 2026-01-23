import 'package:flutter/material.dart';
import '../widgets/centered_content.dart';
import '../theme/ui_constants.dart';
import '../widgets/tappable.dart';

/// Cal AI風Compare UI（ビフォー/アフター比較）
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  bool hideWeight = false;
  int selectedThumbnailIndex = 5; // 最後のサムネイルが選択状態

  // ダミーデータ
  final beforeWeight = 355.0; // lbs
  final beforeDate = '2023/9/20';
  final afterWeight = 182.0; // lbs
  final afterDate = '2025/7/7';

  // サムネイル一覧（ダミー）
  final List<ThumbnailItem> thumbnails = List.generate(
    6,
    (index) => ThumbnailItem(
      isAfter: index == 5, // 最後がAfter
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.colorBackground, // 【Home準拠】背景色
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),

            // メインコンテンツ（PC幅でもスマホ幅で中央表示）
            Expanded(
              child: CenteredContent(
                padding: const EdgeInsets.only(top: 18, bottom: 16, left: 16, right: 16), // 【最終調整】ヘッダー下18px
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Before / After 比較カード
                    _buildComparisonCards(),

                    const SizedBox(height: UIConstants.spacingSection), // 【最終調整】セクション間18px

                    // Hide weight トグル
                    _buildHideWeightToggle(),

                    const SizedBox(height: 18), // 【Home準拠】セクション間18px

                    // サムネイル一覧
                    _buildThumbnailsList(),

                    const SizedBox(height: 18), // 【Home準拠】セクション間18px

                    // Shareボタン
                    _buildShareButton(),

                    const SizedBox(height: UIConstants.spacingCard), // 【最終調整】カード下部余白14px
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ヘッダー（タイトル＋Shareボタン）
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
        children: [
          // 戻るボタン
          TappableIcon(
            icon: Icons.arrow_back,
            size: 24,
            color: Colors.black.withValues(alpha: 0.5), // 【視線誘導】戻るボタンを弱め
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          const Text(
            '比較',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700, // 【Home準拠】太め
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // Shareボタン（ピル型）
          // 【タップ感統一】弱めるけど押せる感は維持（背景opacity戻す＋枠線追加）
          TappablePill(
            onTap: () {
              // ダミー処理
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7), // 【タップ感統一】背景を少し戻す（0.5 → 0.7）
                borderRadius: BorderRadius.circular(UIConstants.radiusPill),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3), // 【タップ感統一】枠線追加でボタンらしさ維持
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.7), // 【タップ感統一】アイコンを少し戻す（0.5 → 0.7）
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '共有',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // 【視線誘導】共有ボタンを弱め（w700 → w500）
                      color: Colors.white.withValues(alpha: 0.7), // 【タップ感統一】テキストを少し戻す（0.5 → 0.7）
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

  /// Before / After 比較カード（430px内では縦積み）
  Widget _buildComparisonCards() {
    // PC幅でも430px内に収まるよう縦積みに変更
    return Column(
      children: [
        // Beforeカード
        _buildPhotoCard(
          weight: beforeWeight,
          date: beforeDate,
          isAfter: false,
          isSelected: false,
        ),
        const SizedBox(height: UIConstants.spacingCard), // 【Home準拠】カード間14px
        // Afterカード
        _buildPhotoCard(
          weight: afterWeight,
          date: afterDate,
          isAfter: true,
          isSelected: true,
        ),
      ],
    );
  }

  /// 写真カード
  Widget _buildPhotoCard({
    required double weight,
    required String date,
    required bool isAfter,
    required bool isSelected,
  }) {
    return _StyledCard(
      padding: EdgeInsets.zero,
      useSubtleBorder: false, // 【Home準拠】主要カードは0.8（標準border）
      child: Container(
        height: 500,
        decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UIConstants.radiusInner), // 【Home準拠】内側要素18px（写真角丸）
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ダミー背景画像
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isAfter
                        ? [
                            const Color(0xFFE8F5E9),
                            const Color(0xFFC8E6C9),
                          ]
                        : [
                            const Color(0xFFF5F5F5),
                            const Color(0xFFE0E0E0),
                          ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAfter ? Icons.check_circle : Icons.circle,
                        size: 80,
                        color: isAfter
                            ? const Color(0xFF34C759)
                            : Colors.black.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        // 表示文字列（i18n未導入のため直書き）
                        isAfter ? '後' : '前',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600, // 【視線誘導】ラベルを弱め（w700 → w600）
                          color: Colors.black.withValues(alpha: 0.55), // 【視線誘導】ラベルを弱め（opacity 0.55）
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 体重＋日付のオーバーレイ（下部）
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // 【Home準拠】薄背景＋白文字（控えめなグラデーション）
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5), // 【Home準拠】薄めの背景
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hideWeight)
                        Text(
                          '${weight.toStringAsFixed(0)} lbs',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700, // 【Home準拠】太字
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      if (!hideWeight) const SizedBox(height: UIConstants.spacingText), // 【最終調整】テキスト行間：10px
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.58), // 【視線誘導】日付を弱め（opacity 0.58）
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hide weight トグル
  Widget _buildHideWeightToggle() {
    return _StyledCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      useSubtleBorder: true, // 【最終調整】補助要素は0.6（控えめ）
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '体重非表示',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500, // 【視線誘導】トグルを弱め（w600 → w500）
              color: Colors.black.withValues(alpha: 0.5), // 【視線誘導】トグルを最弱（opacity 0.5）
            ),
          ),
          Switch(
            value: hideWeight,
            onChanged: (value) {
              setState(() {
                hideWeight = value;
              });
            },
            activeThumbColor: Colors.black.withValues(alpha: 0.5), // 【視線誘導】スイッチを弱め（opacity 0.5）
          ),
        ],
      ),
    );
  }

  /// サムネイル一覧
  Widget _buildThumbnailsList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14), // 【最終調整】サムネ列の上下余白14px
      child: SizedBox(
        height: 80,
        child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: thumbnails.length,
        itemBuilder: (context, index) {
          final thumbnail = thumbnails[index];
          final isSelected = selectedThumbnailIndex == index;

          return Tappable(
            onTap: () {
              setState(() {
                selectedThumbnailIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(UIConstants.radiusInner),
            child: Container(
              width: 80,
              margin: EdgeInsets.only(
                right: index < thumbnails.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
                border: Border.all(
                  color: isSelected
                      ? Colors.black
                      : UIConstants.colorBorder.withValues(alpha: 0.8), // 【Home準拠】border色
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18), // 【Home準拠】内側要素18px
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: thumbnail.isAfter
                          ? [
                              const Color(0xFFE8F5E9),
                              const Color(0xFFC8E6C9),
                            ]
                          : [
                              const Color(0xFFF5F5F5),
                              const Color(0xFFE0E0E0),
                            ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      thumbnail.isAfter ? Icons.check_circle : Icons.circle,
                      size: 32,
                      color: thumbnail.isAfter
                          ? const Color(0xFF34C759)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  /// Shareボタン（下部）
  Widget _buildShareButton() {
    // 【タップ感統一】弱めるけど押せる感は維持（背景opacity戻す＋枠線追加）
    return SizedBox(
      width: double.infinity,
      child: Tappable(
        onTap: () {
          // ダミー処理
        },
        borderRadius: BorderRadius.circular(UIConstants.radiusInner),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7), // 【タップ感統一】背景を少し戻す（0.5 → 0.7）
            borderRadius: BorderRadius.circular(UIConstants.radiusInner),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.3), // 【タップ感統一】枠線追加でボタンらしさ維持
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share, size: 20, color: Colors.white.withValues(alpha: 0.7)), // 【タップ感統一】アイコンを少し戻す（0.5 → 0.7）
              const SizedBox(width: 6),
              Text(
                '共有',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500, // 【視線誘導】共有ボタンを弱め（w700 → w500）
                  color: Colors.white.withValues(alpha: 0.7), // 【タップ感統一】テキストを少し戻す（0.5 → 0.7）
                ),
              ),
            ],
          ),
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

/// サムネイルアイテムのデータモデル
class ThumbnailItem {
  final bool isAfter;

  ThumbnailItem({
    required this.isAfter,
  });
}
