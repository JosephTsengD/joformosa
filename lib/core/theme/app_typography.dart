import 'package:flutter/material.dart';

/// CJK 排版注意事項：
/// 1. fontFamilyFallback 必填，否則各家 Android ROM 的中文字重不一致。
/// 2. 中文不加 letterSpacing（會破壞字距），只有英文全大寫標籤才加。
/// 3. 時間 / 分數用 tabularFigures，避免數字寬度跳動。
abstract final class AppText {
  static const _fallback = <String>['Noto Sans TC', 'PingFang TC', 'Microsoft JhengHei'];

  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 1.24,
    fontWeight: FontWeight.w800,
    fontFamilyFallback: _fallback,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 1.32,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: _fallback,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: _fallback,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamilyFallback: _fallback,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: _fallback,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFamilyFallback: _fallback,
  );
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w600,
    fontFamilyFallback: _fallback,
  );

  /// 英文全大寫的標籤（縣市代碼、運動類別）
  static const TextStyle label = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  /// 等寬數字：時間、積分
  static const TextStyle numeric = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
