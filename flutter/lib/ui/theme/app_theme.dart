// flutter/lib/ui/theme/app_theme.dart
// LUODA v2.2.1 微信PC风格主题，适配 Flutter 3.22+

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// 主题工厂类（无deprecated成员使用）
class AppTheme {
 const AppTheme._();

 /// 浅色主题
 static ThemeData light() {
 return ThemeData.light().copyWith(
 useMaterial3: true,
 colorScheme: _lightColorScheme,

 // 主题构建新版本参数
 cardTheme: _cardTheme,
 dialogTheme: _dialogTheme,
 tabBarTheme: _tabBarTheme,
 inputDecorationTheme: _inputDecorationTheme,
 elevatedButtonTheme: _elevatedButtonTheme,
 floatingActionButtonTheme: _floatingActionButtonTheme,
 appBarTheme: _appBarTheme,
 textTheme: AppTextStyles.lightTextTheme,
 primaryTextTheme: AppTextStyles.lightTextTheme,

 indicatorColor: AppColors.primaryGreen,
 scaffoldBackgroundColor: AppColors.surface,
 cardColor: AppColors.cardBg,
 dividerColor: AppColors.divider,
 dialogBackgroundColor: AppColors.cardBg,

 applyElevationOverlayColor: false,
 );
 }

 /// 深色主题
 static ThemeData dark() {
 return ThemeData.dark().copyWith(
 useMaterial3: true,
 colorScheme: _darkColorScheme,

 cardTheme: _cardThemeDark,
 dialogTheme: _dialogThemeDark,
 tabBarTheme: _tabBarTheme,
 inputDecorationTheme: _inputDecorationTheme,
 elevatedButtonTheme: _elevatedButtonTheme,
 floatingActionButtonTheme: _floatingActionButtonTheme,
 appBarTheme: _appBarThemeDark,
 textTheme: AppTextStyles.darkTextTheme,
 primaryTextTheme: AppTextStyles.darkTextTheme,

 indicatorColor: AppColors.primaryGreen,
 scaffoldBackgroundColor: AppColors.background,
 cardColor: AppColors.cardBgDark,
 dividerColor: AppColors.dividerDark,
 dialogBackgroundColor: AppColors.cardBgDark,

 applyElevationOverlayColor: false,
 );
 }

 /// 浅色配色方案
 static const ColorScheme _lightColorScheme = ColorScheme.light(
 primary: AppColors.primaryGreen,
 secondary: AppColors.primaryGreen,
 surface: AppColors.surface,
 background: AppColors.background,
 );

 /// 深色配色方案
 static final ColorScheme _darkColorScheme = ColorScheme.dark(
 primary: AppColors.primaryGreen,
 secondary: AppColors.primaryGreen,
 surface: AppColors.surface,
 background: AppColors.background,
 );

 /// Card主题
 static final CardTheme _cardTheme = CardTheme(
 margin: EdgeInsets.zero,
 elevation: 0,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
 );

 /// Dialog主题
 static final DialogTheme _dialogTheme = DialogTheme(
 backgroundColor: AppColors.cardBg,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 elevation: 4,
 insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
 );

 /// 深色Dialog主题
 static final DialogTheme _dialogThemeDark = DialogTheme(
 backgroundColor: AppColors.cardBgDark,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 elevation: 4,
 insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
 );

 /// TabBar主题
 static final TabBarTheme _tabBarTheme = TabBarTheme(
 indicator: const UnderlineTabIndicator(
 borderSide: BorderSide(width: 2, color: AppColors.primaryGreen),
 ),
 labelColor: AppColors.primaryGreen,
 unselectedLabelColor: AppColors.textTertiary,
 );

 /// 输入框主题
 static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
 filled: true,
 fillColor: AppColors.cardBg.withValues(alpha: 128),
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 );

 /// 按钮主题
 static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
 style: ElevatedButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical: 12),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
 ),
 );

 /// 浮动按钮主题
 static const FloatingActionButtonThemeData _floatingActionButtonTheme =
 FloatingActionButtonThemeData(shape: CircleBorder());

 /// AppBar主题 → 浅色
 static final AppBarTheme _appBarTheme = AppBarTheme(
 centerTitle: true,
 elevation: 0,
 scrolledUnderElevation: 0,
 );

 /// AppBar主题 → 深色
 static final AppBarTheme _appBarThemeDark = const AppBarTheme(
 centerTitle: true,
 elevation: 0,
 backgroundColor: AppColors.navigationBarBg,
 scrolledUnderElevation: 0,
 );

 static final CardTheme _cardThemeDark = _cardTheme.copyWith(
 color: AppColors.cardBgDark,
 );
}

// 兼容扩展：如AppColors缺少Dark项，补充
class AppColorsCompatible {
 static Color get backgroundDark => const Color(0xFF2E2E2E);
 static Color get cardBgDark => const Color(0xFF1E1E1E);
 static Color get dividerDark => const Color(0xFF444444);
 static Color get surfaceDark => const Color(0xFF333333);
}
