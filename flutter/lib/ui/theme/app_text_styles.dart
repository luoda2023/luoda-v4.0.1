// flutter/lib/ui/theme/app_text_styles.dart
// 微信风格文本样式

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// LUODA v2.2.1 微信风格文本样式
///
/// 字号系统参考微信PC端：
/// - 显示标题: 24
/// - 一级标题: 18
/// - 二级标题: 16
/// - 正文: 14
/// - 辅助文字: 12
/// - 微小文字: 10
class AppTextStyles {
  AppTextStyles._();

  // ========== 显示与标题 ==========
  static const TextStyle display = TextStyle(
 fontSize: 24,
 fontWeight: FontWeight.w600,
 color: AppColors.textPrimary,
 height: 1.4,
  );

  static const TextStyle headline1 = TextStyle(
 fontSize: 18,
 fontWeight: FontWeight.w600,
 color: AppColors.textPrimary,
 height: 1.4,
  );

  static const TextStyle headline2 = TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.w600,
 color: AppColors.textPrimary,
 height: 1.4,
  );

  static const TextStyle headline3 = TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w500,
 color: AppColors.textPrimary,
 height: 1.4,
  );

  // ========== 正文 ==========
  static const TextStyle bodyText1 = TextStyle(
 fontSize: 14,
 color: AppColors.textPrimary,
 height: 1.5,
  );

  static const TextStyle bodyText2 = TextStyle(
 fontSize: 13,
 color: AppColors.textSecondary,
 height: 1.5,
  );

  static const TextStyle caption = TextStyle(
 fontSize: 12,
 color: AppColors.textTertiary,
 height: 1.4,
  );

  static const TextStyle overline = TextStyle(
 fontSize: 10,
 color: AppColors.textTertiary,
 height: 1.4,
  );

  // ========== 特殊样式 ==========
  static const TextStyle appBarTitle = TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.w600,
 color: AppColors.textPrimary,
  );

  static const TextStyle conversationNameActive = TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: AppColors.textPrimary,
  );

  static const TextStyle conversationName = TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w500,
 color: AppColors.textPrimary,
  );

  static const TextStyle conversationLastMessage = TextStyle(
 fontSize: 12,
 color: AppColors.textSecondary,
 overflow: TextOverflow.ellipsis,
  );

  static const TextStyle conversationTime = TextStyle(
 fontSize: 11,
 color: AppColors.textTertiary,
  );

  static const TextStyle unreadBadge = TextStyle(
 fontSize: 10,
 fontWeight: FontWeight.w600,
 color: AppColors.textOnDark,
  );

  static const TextStyle chatMessageMine = TextStyle(
 fontSize: 14,
 color: AppColors.textPrimary,
 height: 1.5,
  );

  static const TextStyle chatMessageOther = TextStyle(
 fontSize: 14,
 color: AppColors.textPrimary,
 height: 1.5,
  );

  static const TextStyle chatTimestamp = TextStyle(
 fontSize: 10,
 color: AppColors.textTertiary,
  );

  static const TextStyle chatSystemMessage = TextStyle(
 fontSize: 12,
 color: AppColors.textTertiary,
  );

  // ========== 按钮 ==========
  static const TextStyle buttonPrimary = TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: AppColors.textOnDark,
  );

  static const TextStyle buttonSecondary = TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: AppColors.primaryGreen,
  );

  static const TextStyle buttonText = TextStyle(
 fontSize: 14,
 color: AppColors.link,
  );

  // ========== 远程桌面相关 ==========
  static const TextStyle remoteToolbarHint = TextStyle(
 fontSize: 12,
 color: AppColors.textOnDark,
  );

  static const TextStyle remoteResolution = TextStyle(
 fontSize: 12,
 color: AppColors.textSecondary,
 fontFeatures: [FontFeature.tabularFigures()],
  );

  // ========== 输入框 ==========
  static const TextStyle input = TextStyle(
 fontSize: 14,
 color: AppColors.textPrimary,
  );

  static const TextStyle inputHint = TextStyle(
 fontSize: 14,
 color: AppColors.textTertiary,
  );

  // ========== TextTheme 静态属性（app_theme.dart 需要）==========
  static TextTheme get lightTextTheme => TextTheme(
 displayLarge: display,
 displayMedium: headline1,
 displaySmall: headline2,
 headlineLarge: headline1,
 headlineMedium: headline2,
 headlineSmall: headline3,
 titleLarge: headline2,
 titleMedium: headline3,
 titleSmall: bodyText1,
 bodyLarge: bodyText1,
 bodyMedium: bodyText2,
 bodySmall: caption,
 labelLarge: buttonPrimary,
 labelMedium: buttonSecondary,
 labelSmall: buttonText,
  );

  static TextTheme get darkTextTheme => TextTheme(
 displayLarge: display.copyWith(color: AppColors.textPrimaryDark),
 displayMedium: headline1.copyWith(color: AppColors.textPrimaryDark),
 displaySmall: headline2.copyWith(color: AppColors.textPrimaryDark),
 headlineLarge: headline1.copyWith(color: AppColors.textPrimaryDark),
 headlineMedium: headline2.copyWith(color: AppColors.textPrimaryDark),
 headlineSmall: headline3.copyWith(color: AppColors.textPrimaryDark),
 titleLarge: headline2.copyWith(color: AppColors.textPrimaryDark),
 titleMedium: headline3.copyWith(color: AppColors.textPrimaryDark),
 titleSmall: bodyText1.copyWith(color: AppColors.textPrimaryDark),
 bodyLarge: bodyText1.copyWith(color: AppColors.textPrimaryDark),
 bodyMedium: bodyText2.copyWith(color: AppColors.textSecondaryDark),
 bodySmall: caption.copyWith(color: AppColors.textTertiaryDark),
 labelLarge: buttonPrimary.copyWith(color: AppColors.textOnDark),
 labelMedium: buttonSecondary,
 labelSmall: buttonText,
  );
}
