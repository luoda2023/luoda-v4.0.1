// flutter/lib/ui/components/device_card.dart
// 微信风格设备卡片

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'avatar.dart';

/// 设备状态
enum DeviceStatus {
  /// 在线，可连接
  online,

  /// 离线
  offline,

  /// 连接中
  connecting,

  /// 已连接 (活动中)
  connected,

  /// 错误
  error,

  /// 未知
  unknown,
}

/// 设备类型（决定图标）
enum DeviceKind {
  /// Windows
  windows,

  /// macOS
  macos,

  /// Linux
  linux,

  /// Android
  android,

  /// iOS
  ios,

  /// 服务器
  server,

  /// 未知
  unknown,
}

extension DeviceKindEx on DeviceKind {
  IconData get icon {
    switch (this) {
      case DeviceKind.windows:
        return Icons.desktop_windows;
      case DeviceKind.macos:
        return Icons.laptop_mac;
      case DeviceKind.linux:
        return Icons.computer;
      case DeviceKind.android:
        return Icons.android;
      case DeviceKind.ios:
        return Icons.phone_iphone;
      case DeviceKind.server:
        return Icons.dns_outlined;
      case DeviceKind.unknown:
        return Icons.devices;
    }
  }

  Color get color {
    switch (this) {
      case DeviceKind.windows:
        return const Color(0xFF0078D4); // Windows blue
      case DeviceKind.macos:
        return const Color(0xFF555555);
      case DeviceKind.linux:
        return const Color(0xFFFCC624); // Linux yellow
      case DeviceKind.android:
        return const Color(0xFF3DDC84); // Android green
      case DeviceKind.ios:
        return const Color(0xFF007AFF);
      case DeviceKind.server:
        return AppColors.primaryGreen;
      case DeviceKind.unknown:
        return AppColors.textSecondary;
    }
  }
}

extension DeviceStatusEx on DeviceStatus {
  String get label {
    switch (this) {
      case DeviceStatus.online:
        return '在线';
      case DeviceStatus.offline:
        return '离线';
      case DeviceStatus.connecting:
        return '连接中';
      case DeviceStatus.connected:
        return '已连接';
      case DeviceStatus.error:
        return '错误';
      case DeviceStatus.unknown:
        return '未知';
    }
  }

  Color get color {
    switch (this) {
      case DeviceStatus.online:
      case DeviceStatus.connected:
        return AppColors.online;
      case DeviceStatus.offline:
        return AppColors.offline;
      case DeviceStatus.connecting:
        return AppColors.warning;
      case DeviceStatus.error:
        return AppColors.error;
      case DeviceStatus.unknown:
        return AppColors.textTertiary;
    }
  }
}

/// 微信风格设备卡片
///
/// 用于设备列表中显示单个远程设备
class DeviceCard extends StatelessWidget {
  /// 设备ID（远端peer id）
  final String id;

  /// 设备别名
  final String alias;

  /// 主机名
  final String? hostname;

  /// 平台
  final DeviceKind kind;

  /// 状态
  final DeviceStatus status;

  /// 最后上线时间
  final String? lastSeen;

  /// 是否选中
  final bool selected;

  /// 单击回调
  final VoidCallback? onTap;

  /// 双击回调（直接连接）
  final VoidCallback? onDoubleTap;

  /// 长按回调（弹出菜单）
  final VoidCallback? onLongPress;

  /// 右侧附加内容（如未读数）
  final Widget? trailing;

  /// 副信息文字（替代默认的 hostname + lastSeen）
  final String? subtitle;

  const DeviceCard({
    super.key,
    required this.id,
    required this.alias,
    this.hostname,
    this.kind = DeviceKind.unknown,
    this.status = DeviceStatus.unknown,
    this.lastSeen,
    this.selected = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreenLight : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.primaryGreen : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alias,
                            style: AppTextStyles.headline3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitle(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kind.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(kind.icon, color: kind.color, size: 22),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    final parts = <String>[];
    if (subtitle != null) {
      parts.add(subtitle!);
    } else {
      if (hostname != null) parts.add(hostname!);
      if (lastSeen != null) parts.add(lastSeen!);
    }
    parts.add(status.label);

    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join(' · '),
            style: AppTextStyles.bodyText2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 简化的设备列表项（用于紧凑列表）
class CompactDeviceCard extends StatelessWidget {
  final String alias;
  final DeviceKind kind;
  final DeviceStatus status;
  final String? lastMessage;
  final String? time;
  final int unreadCount;
  final bool selected;
  final VoidCallback? onTap;

  const CompactDeviceCard({
    super.key,
    required this.alias,
    this.kind = DeviceKind.unknown,
    this.status = DeviceStatus.unknown,
    this.lastMessage,
    this.time,
    this.unreadCount = 0,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: selected ? AppColors.selected : Colors.transparent,
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kind.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(kind.icon, color: kind.color, size: 20),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alias,
                            style: AppTextStyles.conversationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 8),
                          Text(time!, style: AppTextStyles.conversationTime),
                        ],
                      ],
                    ),
                    if (lastMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        lastMessage!,
                        style: AppTextStyles.conversationLastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.unreadBadge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: AppTextStyles.unreadBadge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
