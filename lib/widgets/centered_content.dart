import 'package:flutter/material.dart';

/// PC幅でもスマホ幅で中央表示する共通Widget
/// Center + ConstrainedBox(maxWidth) + SingleChildScrollView/Padding をラップ
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = 430,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.scroll = true,
  });

  /// 子ウィジェット
  final Widget child;

  /// 最大幅（デフォルト: 430px）
  final double maxWidth;

  /// パディング（デフォルト: 左右16px、上下16px）
  final EdgeInsets padding;

  /// スクロール可能にするか（デフォルト: true）
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: scroll
            ? SingleChildScrollView(
                padding: padding,
                child: child,
              )
            : Padding(
                padding: padding,
                child: child,
              ),
      ),
    );
  }
}

