import 'package:flutter/material.dart';

/// 默认色板。业务可继承或直接修改后传给 AppTheme。
class AppColors {
  const AppColors({
    this.primary = const Color(0xFF1677FF),
    this.onPrimary = Colors.white,
    this.background = const Color(0xFFF5F6F8),
    this.surface = Colors.white,
    this.onSurface = const Color(0xFF1F1F1F),
    this.textPrimary = const Color(0xFF1F1F1F),
    this.textSecondary = const Color(0xFF6B7280),
    this.divider = const Color(0xFFE5E7EB),
    this.success = const Color(0xFF10B981),
    this.warning = const Color(0xFFF59E0B),
    this.error = const Color(0xFFEF4444),
  });

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;

  static const AppColors light = AppColors();

  static const AppColors dark = AppColors(
    primary: Color(0xFF4096FF),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE5E7EB),
    textPrimary: Color(0xFFE5E7EB),
    textSecondary: Color(0xFF9CA3AF),
    divider: Color(0xFF2D2D2D),
  );
}
