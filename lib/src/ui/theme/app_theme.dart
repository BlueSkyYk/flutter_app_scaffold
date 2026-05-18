import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light({
    AppColors colors = AppColors.light,
    AppTextStyles text = AppTextStyles.defaults,
  }) {
    return _build(brightness: Brightness.light, colors: colors, text: text);
  }

  static ThemeData dark({
    AppColors colors = AppColors.dark,
    AppTextStyles text = AppTextStyles.defaults,
  }) {
    return _build(brightness: Brightness.dark, colors: colors, text: text);
  }

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required AppTextStyles text,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
    ).copyWith(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.onSurface,
      error: colors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.divider,
      textTheme: TextTheme(
        titleLarge: text.title.copyWith(color: colors.textPrimary),
        titleMedium: text.subtitle.copyWith(color: colors.textPrimary),
        bodyMedium: text.body.copyWith(color: colors.textPrimary),
        bodySmall: text.caption.copyWith(color: colors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
