// flutter/lib/ui/theme/app_theme.dart
// LUODA v4.0.1 微信PC风格主题，适配 Flutter 3.22+

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// 主题工厂类（纯静态，不可实例化）
class AppTheme {
  const AppTheme._();

  /// 浅色主题
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      cardTheme: _cardTheme,
      dialogTheme: _dialogTheme,
      tabBarTheme: _tabBarTheme,
      inputDecorationTheme: _inputDecorationTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      appBarTheme: _appBarTheme,
      textTheme: AppTextStyles.lightTextTheme,
      primaryTextTheme: AppTextStyles.lightTextTheme,
      scaffoldBackgroundColor: AppColors.surface,
      dividerColor: AppColors.divider,
      applyElevationOverlayColor: false,
    );
  }

  /// 深色主题
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      cardTheme: _cardThemeDark,
      dialogTheme: _dialogThemeDark,
      tabBarTheme: _tabBarThemeDark,
      inputDecorationTheme: _inputDecorationThemeDark,
      elevatedButtonTheme: _elevatedButtonTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      appBarTheme: _appBarThemeDark,
      textTheme: AppTextStyles.darkTextTheme,
      primaryTextTheme: AppTextStyles.darkTextTheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: AppColors.dividerDark,
      applyElevationOverlayColor: false,
    );
  }

  /// 浅色配色方案
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.primaryGreen,
    surface: AppColors.surface,
  );

  /// 深色配色方案
  static final ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primaryGreen,
    secondary: AppColors.primaryGreen,
    surface: AppColors.surfaceDark,
  );

  /// Card 主题（浅色）
  static final CardTheme _cardTheme = CardTheme(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Card 主题（深色）
  static final CardTheme _cardThemeDark = CardTheme(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.cardBgDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Dialog 主题（浅色）
  static final DialogTheme _dialogTheme = DialogTheme(
    backgroundColor: AppColors.cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  );

  /// Dialog 主题（深色）
  static final DialogTheme _dialogThemeDark = DialogTheme(
    backgroundColor: AppColors.cardBgDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  );

  /// TabBar 主题（浅色）
  static final TabBarTheme _tabBarTheme = TabBarTheme(
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(width: 2, color: AppColors.primaryGreen),
    ),
    labelColor: AppColors.primaryGreen,
    unselectedLabelColor: AppColors.textTertiary,
  );

  /// TabBar 主题（深色）
  static final TabBarTheme _tabBarThemeDark = TabBarTheme(
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(width: 2, color: AppColors.primaryGreen),
    ),
    labelColor: AppColors.primaryGreen,
    unselectedLabelColor: AppColors.textTertiaryDark,
  );

  /// 输入框主题（浅色）
  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: AppColors.cardBg.withOpacity(0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  /// 输入框主题（深色）
  static final InputDecorationTheme _inputDecorationThemeDark =
      InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: AppColors.cardBgDark.withOpacity(0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  /// 按钮主题
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  /// 浮动按钮主题
  static const FloatingActionButtonThemeData _floatingActionButtonTheme =
      FloatingActionButtonThemeData(shape: CircleBorder());

  /// AppBar 主题 → 浅色
  static const AppBarTheme _appBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
  );

  /// AppBar 主题 → 深色
  static const AppBarTheme _appBarThemeDark = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: AppColors.navigationBarBgDark,
    scrolledUnderElevation: 0,
  );
}
