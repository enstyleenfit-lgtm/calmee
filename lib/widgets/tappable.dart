import 'package:flutter/material.dart';
import '../theme/ui_constants.dart';

/// タップ可能な要素の共通コンポーネント
/// タップ感・操作感を統一（リップル、タップ領域、角丸）
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.padding,
    this.minSize = 48.0, // 最低タップ領域48px
    this.splashColor,
    this.highlightColor,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final double minSize;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(UIConstants.radiusInner);
    final effectivePadding = padding ?? EdgeInsets.zero;

    Widget content = child;
    
    // 最低タップ領域を確保
    if (minSize > 0) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize,
          minHeight: minSize,
        ),
        child: Center(
          child: content,
        ),
      );
    }

    // paddingがある場合は適用
    if (effectivePadding != EdgeInsets.zero) {
      content = Padding(
        padding: effectivePadding,
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        splashColor: splashColor ?? Colors.black.withValues(alpha: 0.11), // 【最終調整】少し分かりやすく（0.08 → 0.11）
        highlightColor: highlightColor ?? Colors.black.withValues(alpha: 0.055), // 【最終調整】少し分かりやすく（0.04 → 0.055）
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          // 【最終調整】押下中だけほんの少し暗くなる
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withValues(alpha: 0.03); // 押下中の暗さ
          }
          return null;
        }),
        child: content,
      ),
    );
  }
}

/// ピル型のタップ可能な要素
class TappablePill extends StatelessWidget {
  const TappablePill({
    super.key,
    required this.onTap,
    required this.child,
    this.padding,
    this.minSize = 48.0,
    this.splashColor,
    this.highlightColor,
  });

  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsets? padding;
  final double minSize;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.radiusPill),
      padding: padding,
      minSize: minSize,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// アイコンボタン用のタップ可能な要素
class TappableIcon extends StatelessWidget {
  const TappableIcon({
    super.key,
    required this.onTap,
    required this.icon,
    this.size = 24.0,
    this.color,
    this.minSize = 48.0,
    this.child,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final double size;
  final Color? color;
  final double minSize;
  final Widget? child; // カスタムchild（camera_page用）

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIConstants.radiusInner),
      minSize: minSize,
      child: child ?? Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}

