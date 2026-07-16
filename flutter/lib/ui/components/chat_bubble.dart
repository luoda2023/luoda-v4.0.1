// flutter/lib/ui/components/chat_bubble.dart
// 微信风格聊天气泡

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 聊天气泡类型
enum ChatBubbleType {
  /// 自己发出的消息（绿色气泡，靠右）
  mine,

  /// 对方发来的消息（白色气泡，靠左）
  other,

  /// 系统消息（灰色居中）
  system,

  /// 文件消息
  file,

  /// 图片消息
  image,
}

/// 微信风格聊天气泡
///
/// - 我的消息: 背景绿色 (#95EC69)，圆角右下小，右对齐
/// - 对方消息: 背景白色，圆角左下小，左对齐
/// - 系统消息: 居中文字，浅灰背景
class ChatBubble extends StatelessWidget {
  final String? text;
  final ChatBubbleType type;
  final String? timestamp;
  final Widget? customContent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? avatar;
  final String? senderName;

  /// 可选自定义文字样式。移动端传入手机标准字号，桌面端留空沿用默认 PC 样式。
  final TextStyle? textStyle;

  const ChatBubble({
    super.key,
    this.text,
    required this.type,
    this.timestamp,
    this.customContent,
    this.onTap,
    this.onLongPress,
    this.avatar,
    this.senderName,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (type == ChatBubbleType.system) {
      return _buildSystemBubble();
    }
    return _buildUserBubble();
  }

  Widget _buildSystemBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bubbleSystem,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text ?? '',
        style: AppTextStyles.chatSystemMessage,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUserBubble() {
    final isMine = type == ChatBubbleType.mine;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine && avatar != null) ...[
            avatar!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (senderName != null && !isMine) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      senderName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppColors.bubbleMine
                          : AppColors.bubbleOther,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(8),
                        topRight: const Radius.circular(8),
                        bottomLeft: Radius.circular(isMine ? 8 : 2),
                        bottomRight: Radius.circular(isMine ? 2 : 8),
                      ),
                      boxShadow: [
                        if (!isMine)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                      ],
                    ),
                    child: customContent ??
                        Text(
                          text ?? '',
                          style: textStyle ??
                              (isMine
                                  ? AppTextStyles.chatMessageMine
                                  : AppTextStyles.chatMessageOther),
                        ),
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      timestamp!,
                      style: AppTextStyles.chatTimestamp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMine && avatar != null) ...[
            const SizedBox(width: 8),
            avatar!,
          ],
        ],
      ),
    );
  }
}

/// 文件消息气泡
class FileBubble extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final bool isMine;
  final String? timestamp;
  final VoidCallback? onDownload;
  final VoidCallback? onTap;

  const FileBubble({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.isMine,
    this.timestamp,
    this.onDownload,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      type: isMine ? ChatBubbleType.mine : ChatBubbleType.other,
      timestamp: timestamp,
      onTap: onTap,
      customContent: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: AppColors.primaryGreen,
            size: 36,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  fileName,
                  style: AppTextStyles.bodyText1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                fileSize,
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (onDownload != null && !isMine) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: onDownload,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
