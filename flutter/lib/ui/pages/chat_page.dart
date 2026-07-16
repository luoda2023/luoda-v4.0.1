// flutter/lib/ui/pages/chat_page.dart
// 微信风格聊天主区（整屏三栏中的右侧主角）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luoda_flutter/common.dart';
import '../components/avatar.dart';
import '../components/chat_bubble.dart';
import '../states/chat_message_state.dart';
import '../states/conversation_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 聊天页：展示某个会话的消息流 + 底部输入区。
/// 数据来自 [ChatMessageState]，与 conversation_state.dart 同层，
/// 不耦合遗留的浮窗 ChatModel。
class ChatPage extends StatefulWidget {
  /// 会话 ID（对应 ConversationState 里的会话；也用作消息分桶 key）
  final String conversationId;

  const ChatPage({Key? key, required this.conversationId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatMessageState get _store => Get.find<ChatMessageState>();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _store.send(widget.conversationId, text);
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// 会话标题：优先取 ConversationState 里的名称
  String get _title {
    final convs = Get.find<ConversationState>().conversations;
    final idx = convs.indexWhere((c) => c.id == widget.conversationId);
    if (idx >= 0) return convs[idx].name;
    return widget.conversationId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(child: _buildMessageList()),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.contentAreaBg,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _title,
              style: AppTextStyles.headline2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: '发起远程协助',
            icon: const Icon(Icons.cast_connected,
                color: AppColors.primaryGreen),
            onPressed: () {
              final convs = Get.find<ConversationState>().conversations;
              final idx = convs.indexWhere((c) => c.id == widget.conversationId);
              final peerId = idx >= 0 ? (convs[idx].peerId) : widget.conversationId;
              if (peerId.isEmpty) {
                Get.snackbar('远程协助', '该会话暂不支持远程连接',
                    snackPosition: SnackPosition.BOTTOM);
                return;
              }
              // 建立到对端的 P2P 会话；聊天将沿同一条直连收发，不经服务器
              connect(context, peerId);
              Get.snackbar('远程协助', '正在向 $_title 发起远程连接…',
                  snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: AppColors.contentAreaBg,
      child: Obx(() {
        final messages = _store.messagesOf(widget.conversationId);
        if (messages.isEmpty) {
          return const Center(
            child: Text('还没有消息，打个招呼吧',
                style: TextStyle(color: AppColors.textTertiary)),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final m = messages[index];
            if (m.isSystem) {
              return ChatBubble(
                type: ChatBubbleType.system,
                text: m.text,
              );
            }
            return ChatBubble(
              type: m.isMine ? ChatBubbleType.mine : ChatBubbleType.other,
              text: m.text,
              timestamp: m.timeLabel,
              avatar: m.isMine
                  ? null
                  : Avatar(text: _title, size: 36),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.contentAreaBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: '输入消息…',
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textOnDark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                child: const Text('发送'),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '常连接：无需远程会话，消息也会实时送达',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
