import 'package:flutter/material.dart';

/// 語意化色彩 token。
///
/// 規則：feature 層**禁止**出現任何 `Color(0xFF...)` 字面值，
/// 一律透過 `Theme.of(context).extension<AppColors>()!` 取用。
/// 這條規則由 custom_lint 強制（見 tool/harness.sh 的 layering 檢查）。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAccent,
    required this.accentPrimary,
    required this.accentPressed,
    required this.accentSubtle,
    required this.success,
    required this.warning,
    required this.danger,
    required this.sportRun,
    required this.sportRide,
    required this.sportHyrox,
    required this.sportOther,
    required this.borderSubtle,
    required this.borderStrong,
    required this.scrim,
  });

  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnAccent;

  final Color accentPrimary;
  final Color accentPressed;
  final Color accentSubtle;

  final Color success;
  final Color warning;
  final Color danger;

  final Color sportRun;
  final Color sportRide;
  final Color sportHyrox;
  final Color sportOther;

  final Color borderSubtle;
  final Color borderStrong;
  final Color scrim;

  static const light = AppColors(
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF6F7F9),
    textPrimary: Color(0xFF0F1115),
    textSecondary: Color(0xFF5B616E),
    textTertiary: Color(0xFF9AA0AC),
    textOnAccent: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFFFF5A1F),
    accentPressed: Color(0xFFE04A12),
    accentSubtle: Color(0xFFFFF0EA),
    success: Color(0xFF12805C),
    warning: Color(0xFFB45309),
    danger: Color(0xFFC0362C),
    sportRun: Color(0xFFFF5A1F),
    sportRide: Color(0xFF0EA5E9),
    sportHyrox: Color(0xFF7C3AED),
    sportOther: Color(0xFF64748B),
    borderSubtle: Color(0xFFE8EAED),
    borderStrong: Color(0xFFCBD0D8),
    scrim: Color(0x66000000),
  );

  /// 深色模式不是把亮色反轉，而是重新定義語意：
  /// elevation 用「提高亮度」表達，而非加陰影。
  static const dark = AppColors(
    surface: Color(0xFF0F1115),
    surfaceElevated: Color(0xFF181B21),
    surfaceSunken: Color(0xFF0A0C0F),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA0A7B4),
    textTertiary: Color(0xFF6B7280),
    textOnAccent: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFFFF6B33),
    accentPressed: Color(0xFFFF8455),
    accentSubtle: Color(0xFF2A1810),
    success: Color(0xFF2DD4A0),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    sportRun: Color(0xFFFF6B33),
    sportRide: Color(0xFF38BDF8),
    sportHyrox: Color(0xFFA78BFA),
    sportOther: Color(0xFF94A3B8),
    borderSubtle: Color(0xFF23272F),
    borderStrong: Color(0xFF343A45),
    scrim: Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAccent,
    Color? accentPrimary,
    Color? accentPressed,
    Color? accentSubtle,
    Color? success,
    Color? warning,
    Color? danger,
    Color? sportRun,
    Color? sportRide,
    Color? sportHyrox,
    Color? sportOther,
    Color? borderSubtle,
    Color? borderStrong,
    Color? scrim,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      sportRun: sportRun ?? this.sportRun,
      sportRide: sportRide ?? this.sportRide,
      sportHyrox: sportHyrox ?? this.sportHyrox,
      sportOther: sportOther ?? this.sportOther,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textOnAccent: c(textOnAccent, other.textOnAccent),
      accentPrimary: c(accentPrimary, other.accentPrimary),
      accentPressed: c(accentPressed, other.accentPressed),
      accentSubtle: c(accentSubtle, other.accentSubtle),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      sportRun: c(sportRun, other.sportRun),
      sportRide: c(sportRide, other.sportRide),
      sportHyrox: c(sportHyrox, other.sportHyrox),
      sportOther: c(sportOther, other.sportOther),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
