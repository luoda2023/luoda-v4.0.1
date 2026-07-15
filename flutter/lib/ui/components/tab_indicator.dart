// flutter/lib/ui/components/tab_indicator.dart
// 微信风格 Tab 指示器

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 微信风格底部下划线 Tab 指示器
class WeChatTabIndicator extends StatelessWidget {
  final String label;
  final bool active;
  final int? badge;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const WeChatTabIndicator({
    super.key,
    required this.label,
    this.active = false,
    this.badge,
    this.onTap,
    this.width = 80,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.primaryGreen : AppColors.textSecondary,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                right: 12,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.unreadBadge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    badge! > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (active)
              Positioned(
                bottom: 0,
                left: width / 2 - 12,
                right: width / 2 - 12,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 微信顶部 Tab 栏（用于子页面切换）
class WeChatTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<int>? badges;
  final double height;

  const WeChatTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.badges,
    this.height = 44,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          return Expanded(
            child: WeChatTabIndicator(
              label: tabs[i],
              active: i == currentIndex,
              badge: badges != null && badges!.length > i ? badges![i] : null,
              onTap: () => onTap?.call(i),
              width: double.infinity,
              height: height,
            ),
          );
        }),
      ),
    );
  }
}
