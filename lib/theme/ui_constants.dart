import 'package:flutter/material.dart';

/// Cal AI UIデザイン定数
/// 今後の調整はこのファイルのみで完結
class UIConstants {
  UIConstants._(); // インスタンス化防止

  // ========== Spacing ==========
  /// セクション間の余白（最大）
  static const double spacingSection = 18.0;

  /// カード間の余白（中）
  static const double spacingCard = 14.0;

  /// テキスト行間・見出し下（小）
  static const double spacingText = 10.0;

  /// ラベル↔値の間（最小）
  static const double spacingLabel = 8.0;

  // ========== Border Radius ==========
  /// カードの角丸
  static const double radiusCard = 22.0;

  /// 内側要素（画像・ボタンなど）の角丸
  static const double radiusInner = 18.0;

  /// ピル型要素の角丸
  static const double radiusPill = 999.0;

  // ========== Max Width ==========
  /// PC幅でもスマホ幅で中央表示する最大幅
  static const double maxWidth = 430.0;

  // ========== Colors ==========
  /// 背景色
  static const Color colorBackground = Color(0xFFF6F6F8);

  /// ボーダー色
  static const Color colorBorder = Color(0xFFE9E9EF);

  /// 説明テキスト色（description）
  static const Color colorDescription = Color(0xFF7A7A86);

  /// キャプション色（caption）
  static const Color colorCaption = Color(0xFF9A9AA5);
}

