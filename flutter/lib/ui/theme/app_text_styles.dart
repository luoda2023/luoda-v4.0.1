// flutter/lib/ui/theme/app_text_styles.dart
// 微信风格文本样式

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// LUODA v4.0.1 微信风格文本样式
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

/// 手机端（微信手机版标准）文字样式。
///
/// 与上文 PC 端字号体系区分，专供移动端窄屏使用，符合移动端人机规范：
/// 标题 17 / 正文 16 / 次要 13 / 时间 12，触摸友好、不宜过大或过小。
/// 桌面端仍使用 [AppTextStyles]，不受影响。
class MobileTextStyles {
  MobileTextStyles._();

  /// 顶部导航标题（消息 / 聊天 / 设备页）：17，中等字重。
  static const TextStyle navTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 会话列表 - 名称：16，中等字重。
  static const TextStyle conversationName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 会话列表 - 最后消息预览：13，次要色。
  static const TextStyle conversationPreview = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  /// 会话列表 / 聊天 - 时间：12，三级色。
  static const TextStyle conversationTime = TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
    height: 1.3,
  );

  /// 聊天页标题：17。
  static const TextStyle chatTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 聊天气泡正文：16（微信手机正文标准，非 PC 的 14）。
  static const TextStyle chatMessage = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 系统消息：12。
  static const TextStyle chatSystem = TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
  );

  /// 消息时间戳：11。
  static const TextStyle chatTimestamp = TextStyle(
    fontSize: 11,
    color: AppColors.textTertiary,
  );

  /// 设备列表 - 名称：15。
  static const TextStyle deviceName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 设备列表 - 副标题：12。
  static const TextStyle deviceSub = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  /// 功能 / 设置列表项主文字：16。
  static const TextStyle listItem = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 列表项次要文字：13。
  static const TextStyle listItemSub = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  /// 底部 Tab 文字：11。
  static const TextStyle tabLabel = TextStyle(
    fontSize: 11,
    height: 1.2,
  );

  /// 输入框文字：16。
  static const TextStyle input = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// 输入框提示文字：16。
  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  /// 分组标题 / 空状态提示：13。
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}
