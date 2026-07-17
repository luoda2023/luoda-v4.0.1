// flutter/lib/ui/components/conversation_item.dart
// 微信风格会话列表项

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'avatar.dart';

/// 会话类型
enum ConversationType {
  /// 单设备会话（远程控制）
  device,

  /// 群聊/多观察者
  group,

  /// 文件传输助手
  fileTransfer,

  /// 系统通知
  system,

  /// 联系人
  contact,
}

/// 微信风格会话列表项
///
/// 布局: [头像] [名称+时间]\n[最后消息+未读数]
/// - hover: 浅灰背景
/// - 选中: 中灰背景
class ConversationItem extends StatelessWidget {
  /// 显示名称
  final String name;

  /// 最后一条消息
  final String? lastMessage;

  /// 时间
  final String? time;

  /// 是否在线
  final bool? isOnline;

  /// 未读消息数
  final int unreadCount;

  /// 是否禁止打扰
  final bool muted;

  /// 是否选中
  final bool selected;

  /// 头像URL或文字
  final String? avatarUrl;
  final String? avatarText;

  /// 会话类型
  final ConversationType type;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调（用于弹出菜单）
  final VoidCallback? onLongPress;

  /// 头像尺寸，默认44
  final double avatarSize;

  /// 是否显示在线状态点
  final bool showOnlineDot;

  /// 是否置顶（显示图钉标记）
  final bool pinned;

  /// 是否有未决操作（红点提示）
  final bool hasPendingAction;

  const ConversationItem({
    super.key,
    required this.name,
    this.lastMessage,
    this.time,
    this.isOnline,
    this.unreadCount = 0,
    this.muted = false,
    this.selected = false,
    this.avatarUrl,
    this.avatarText,
    this.type = ConversationType.device,
    this.onTap,
    this.onLongPress,
    this.avatarSize = 44,
    this.showOnlineDot = true,
    this.pinned = false,
    this.hasPendingAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHover = false;
    Color bg = Colors.transparent;
    if (selected) {
      bg = AppColors.selected;
    } else if (isHover) {
      bg = AppColors.hover;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行: 名称 + 时间
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (type == ConversationType.group) ...[
                          const Icon(
                            Icons.group,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            name,
                            style: selected
                                ? AppTextStyles.conversationNameActive
                                : AppTextStyles.conversationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            time!,
                            style: AppTextStyles.conversationTime,
                          ),
                        ],
                        if (pinned) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.push_pin,
                              size: 13, color: AppColors.textTertiary),
                        ],
                      ],
                    ),
                    if (lastMessage != null) ...[
                      const SizedBox(height: 4),
                      // 第二行: 最后消息 + 未读数
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage!,
                              style: AppTextStyles.conversationLastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0 && !muted) ...[
                            const SizedBox(width: 8),
                            _buildUnreadBadge(),
                          ] else if (muted && unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildMutedDot(),
                          ] else if (hasPendingAction) ...[
                            const SizedBox(width: 8),
                            _buildPendingDot(),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    IconData? typeIcon;
    switch (type) {
      case ConversationType.fileTransfer:
        typeIcon = Icons.folder_outlined;
        break;
      case ConversationType.system:
        typeIcon = Icons.notifications_outlined;
        break;
      case ConversationType.contact:
        typeIcon = Icons.person_outlined;
        break;
      default:
        typeIcon = null;
    }

    if (typeIcon != null) {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: AppColors.primaryGreenLight,
          shape: BoxShape.circle,
        ),
        child: Icon(typeIcon, color: AppColors.primaryGreen, size: avatarSize * 0.5),
      );
    }

    return Avatar(
      imageUrl: avatarUrl,
      text: avatarText ?? name,
      size: avatarSize,
      online: showOnlineDot ? isOnline : null,
      unreadCount: 0, // 不在头像上显示
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.unreadBadge,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: AppTextStyles.unreadBadge,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMutedDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.unreadBadge,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPendingDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.unreadBadge,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 空会话占位
class EmptyConversationItem extends StatelessWidget {
  final String? message;

  const EmptyConversationItem({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        message ?? '暂无会话',
        style: AppTextStyles.bodyText2,
        textAlign: TextAlign.center,
      ),
    );
  }
}
