// flutter/lib/ui/components/avatar.dart
// 微信风格圆形头像组件（含在线状态点）

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 微信风格头像
///
/// 圆形头像 + 右下角在线状态点
/// - 在线: 绿色圆点
/// - 离线: 灰色圆点（或不显示）
/// - 通知: 红色角标
class Avatar extends StatelessWidget {
  /// 头像图片URL（网络或资源）
  final String? imageUrl;

  /// 头像文字（当无图片时显示首字）
  final String? text;

  /// 头像尺寸
  final double size;

  /// 在线状态：true=在线, false=离线, null=不显示状态点
  final bool? online;

  /// 未读消息数（>0显示红色角标）
  final int unreadCount;

  /// 头像圆角（默认圆形）
  final double radius;

  /// 背景色（当无图片时）
  final Color? backgroundColor;

  /// 文字颜色
  final Color? textColor;

  /// 边框
  final Border? border;

  /// 点击回调
  final VoidCallback? onTap;

  const Avatar({
    super.key,
    this.imageUrl,
    this.text,
    this.size = 40,
    this.online,
    this.unreadCount = 0,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildAvatar();

    if (online != null || unreadCount > 0) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (online == true)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          if (unreadCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.unreadBadge,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _buildAvatar() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildTextAvatar(),
        ),
      );
    }
    if (text != null && text!.isNotEmpty) {
      return _buildTextAvatar();
    }
    // 默认占位图标
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryGreenLight,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildTextAvatar() {
    final displayText = (text ?? '?').characters.first.toUpperCase();
    // 哈希生成颜色
    final colors = [
      AppColors.primaryGreen,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
    ];
    final hash = (text ?? '').hashCode;
    final color = colors[hash % colors.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withOpacity(0.85),
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 设备类头像（使用设备图标）
class DeviceAvatar extends StatelessWidget {
  final IconData? icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool? online;
  final int unreadCount;
  final VoidCallback? onTap;

  const DeviceAvatar({
    super.key,
    this.icon,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    this.online,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Avatar(
      text: null,
      size: size,
      online: online,
      unreadCount: unreadCount,
      onTap: onTap,
      backgroundColor: backgroundColor,
    );
  }
}
