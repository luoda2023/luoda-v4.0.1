// flutter/lib/ui/components/sidebar_item.dart
// 微信风格左侧导航栏项目

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 侧栏导航项类型
enum SidebarItemType {
  /// 会话/聊天
  chat,

  /// 通讯录/设备列表
  contacts,

  /// 文件传输
  files,

  /// 设置
  settings,

  /// 自定义
  custom,
}

/// 微信风格左侧深色导航栏项目
///
/// - 默认显示一个图标
/// - 选中时图标变绿
/// - 顶部为主功能（聊天、通讯录、设置）
/// - 底部为辅助功能（头像、菜单）
class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final bool selected;
  final bool enabled;
  final int badge; // 未读数（>0显示红色角标）
  final VoidCallback? onTap;
  final double size;
  final Color? selectedColor;
  final Color? unselectedColor;

  const SidebarItem({
    super.key,
    required this.icon,
    this.tooltip,
    this.selected = false,
    this.enabled = true,
    this.badge = 0,
    this.onTap,
    this.size = 24,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? (selectedColor ?? AppColors.primaryGreen)
        : (unselectedColor ?? AppColors.textTertiary);

    return Tooltip(
      message: tooltip ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            children: [
              Center(
                child: Icon(icon, size: size, color: color),
              ),
              if (badge > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.unreadBadge,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 侧栏分隔符
class SidebarDivider extends StatelessWidget {
  const SidebarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AppColors.textTertiary.withOpacity(0.3),
    );
  }
}

/// 侧栏头部项 (用于扩展功能)
class SidebarHeaderItem extends SidebarItem {
  const SidebarHeaderItem({
    super.key,
    required super.icon,
    super.tooltip,
    super.selected = false,
    super.onTap,
    super.size,
    super.selectedColor,
    super.unselectedColor,
    super.badge = 0,
  });
}

/// 底部头像导航项
class SidebarAvatarItem extends StatelessWidget {
  final String? imageUrl;
  final String? text;
  final bool online;
  final int unreadCount;
  final VoidCallback? onTap;

  const SidebarAvatarItem({
    super.key,
    this.imageUrl,
    this.text,
    this.online = false,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Center(
                      child: Text(
                        (text ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                decoration: BoxDecoration(
                  color: AppColors.unreadBadge,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.navigationBarBg, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 侧栏底部菜单项（汉堡菜单）
class SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SidebarItem(
      icon: icon,
      onTap: onTap,
      tooltip: tooltip,
      unselectedColor: AppColors.textTertiary,
    );
  }
}

/// 菜单项文字（用于侧栏底部展开菜单）
class SidebarItemLabel extends StatelessWidget {
  final String label;
  final bool selected;

  const SidebarItemLabel({
    super.key,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: selected
            ? AppTextStyles.caption.copyWith(color: AppColors.primaryGreen)
            : AppTextStyles.caption,
      ),
    );
  }
}
