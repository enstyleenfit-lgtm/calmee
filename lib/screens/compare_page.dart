import 'package:flutter/material.dart';

/// Cal AI風Compare UI（Before/After比較）
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
  final beforeDate = 'Sep 20, 2023';
  final afterWeight = 182.0; // lbs
  final afterDate = 'Jul 7, 2025';

  // サムネイル一覧（ダミー）
  final List<ThumbnailItem> thumbnails = List.generate(
    6,
    (index) => ThumbnailItem(
      isAfter: index == 5, // 最後がAfter
    ),
  );

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
                    // Before / After 比較カード
                    _buildComparisonCards(),

                    const SizedBox(height: 20),

                    // Hide weight トグル
                    _buildHideWeightToggle(),

                    const SizedBox(height: 24),

                    // サムネイル一覧
                    _buildThumbnailsList(),

                    const SizedBox(height: 24),

                    // Shareボタン
                    _buildShareButton(),

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

  /// ヘッダー
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
        children: [
          // 戻るボタン
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Compare',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Before / After 比較カード
  Widget _buildComparisonCards() {
    return Row(
      children: [
        // Beforeカード（左）
        Expanded(
          child: _buildPhotoCard(
            weight: beforeWeight,
            date: beforeDate,
            isAfter: false,
            isSelected: false,
          ),
        ),
        const SizedBox(width: 12),
        // Afterカード（右）
        Expanded(
          child: _buildPhotoCard(
            weight: afterWeight,
            date: afterDate,
            isAfter: true,
            isSelected: true,
          ),
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
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: isSelected
            ? Border.all(
                color: Colors.black,
                width: 2,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
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
                          : Colors.black.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAfter ? 'After' : 'Before',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.6),
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
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
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    if (!hideWeight) const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
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

  /// Hide weight トグル
  Widget _buildHideWeightToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Text(
            'Hide weight',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Switch(
            value: hideWeight,
            onChanged: (value) {
              setState(() {
                hideWeight = value;
              });
            },
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }

  /// サムネイル一覧
  Widget _buildThumbnailsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: thumbnails.length,
            itemBuilder: (context, index) {
              final thumbnail = thumbnails[index];
              final isSelected = selectedThumbnailIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedThumbnailIndex = index;
                  });
                },
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(
                    right: index < thumbnails.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: Colors.black,
                            width: 2,
                          )
                        : Border.all(
                            color: Colors.black.withOpacity(0.2),
                            width: 1,
                          ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                              : Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Shareボタン
  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          // ダミー処理
        },
        icon: const Icon(Icons.share, size: 24),
        label: const Text(
          'Share',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
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

