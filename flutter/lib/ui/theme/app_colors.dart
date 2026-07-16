// flutter/lib/ui/theme/app_colors.dart
// LUODA v4.0.1 微信风格色板

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 主色（微信绿）
  static const Color primaryGreen = Color(0xFF07C160);
  static const Color primaryGreenDark = Color(0xFF06AD56);
  static const Color primaryGreenLight = Color(0xFFE8F8EE);
  static const Color primaryGreenHover = Color(0x1A07C160);

  // 背景 - 浅色
  static const Color background = Color(0xFFEDEDED);
  static const Color conversationListBg = Color(0xFFFFFFFF);
  static const Color contentAreaBg = Color(0xFFF5F5F5);
  static const Color navigationBarBg = Color(0xFF2E2E2E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE6E6E6);

  // 文字 - 浅色
  static const Color textPrimary = Color(0xFF191919);
  static const Color textSecondary = Color(0xFF5B5B5B);
  static const Color textTertiary = Color(0xFFB2B2B2);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color link = Color(0xFF576B95);

  // 状态
  static const Color online = Color(0xFF07C160);
  static const Color offline = Color(0xFFB2B2B2);
  static const Color unreadBadge = Color(0xFFFA5151);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFA5151);
  static const Color success = Color(0xFF07C160);

  // 分割线 / 边框
  static const Color border = Color(0xFFDADADA);
  static const Color hover = Color(0xFFE8E8E8);
  static const Color selected = Color(0xFFD6D6D6);
  static const Color pressed = Color(0xFFC9C9C9);

  // 导航项选中态背景（微信左侧导航被点亮时的浅色底）
  static const Color activeItemBackground = Color(0xFFDCEFE3);

  // 聊天气泡
  static const Color bubbleMine = Color(0xFF95EC69);
  static const Color bubbleOther = Color(0xFFFFFFFF);
  static const Color bubbleSystem = Color(0xFFE0E0E0);

  // 远程桌面
  static const Color remoteToolbarBg = Color(0xCC2E2E2E);
  static const Color remoteNoConnection = Color(0xFF333333);
  static const Color displaySelectedBorder = Color(0xFF07C160);

  // ============ Dark Mode Colors ============
  static const Color backgroundDark = Color(0xFF2E2E2E);
  static const Color cardBgDark = Color(0xFF1E1E1E);
  static const Color dividerDark = Color(0xFF444444);
  static const Color surfaceDark = Color(0xFF333333);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB2B2B2);
  static const Color textTertiaryDark = Color(0xFF888888);
  static const Color navigationBarBgDark = Color(0xFF1A1A1A);
  static const Color contentAreaBgDark = Color(0xFF1E1E1E);
  static const Color conversationListBgDark = Color(0xFF2D2D2D);
  static const Color hoverDark = Color(0xFF3A3A3A);
 static const Color selectedDark = Color(0xFF404040);
 static const Color pressedDark = Color(0xFF4A4A4A);
 static const Color borderDark = Color(0xFF444444);
}
