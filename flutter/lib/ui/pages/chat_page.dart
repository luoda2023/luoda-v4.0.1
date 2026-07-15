// flutter/lib/ui/pages/chat_page.dart
// 微信风格聊天页面（支持多端同步、语音/文件/表情）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/chat_bubble.dart';
import '../states/app_state.dart';
import '../models/conversation_model.dart';

class ChatPage extends StatefulWidget {
  final String conversationId; // 会话ID（对应ConversationModel）
  final String peerId;           // 对应设备/用户
  const ChatPage({Key? key, required this.conversationId, required this.peerId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ConversationModel _chatModel = Get.find<ConversationModel>(tag: 'chat-$conversationId');

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 监听消息变化自动滚动
    _chatModel.stream.listen((event) {
      if (event.streamName == 'newMessage') {
        final msg = event.message;
        _scrollToMessage(msg);
      }
    });
    _scrollController.addListener(_autoScroll);
  }

  void _scrollToMessage(ChatMessage msg) {
    // 滚动到最新消息
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut);
  }

  List<ChatMessage> _loadMessages() {
    return _chatModel.messages[widget.conversationId] ?? [];
  }

  // 输入框处理
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 发送到后端/模型
    _chatModel.sendMessage(widget.conversationId, text);

    // 清空输入
    _textController.clear();

    // 自动滚动到底部
    _scrollToMessage(ChatMessage(
      sender: 'me',
      text: text,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 主要是几个部分：
    // 1. 消息列表（来自 ChatModel）
    // 2. 输入框（带发送按钮）
    // 3. 表情/贴纸/文件上传按钮（略）

    return Scaffold(
      appBar: AppBar(
        title: Text('与 ${'${'label'}'), // 显示对话名称
        backgroundColor: AppColors.remoteToolbarBg,
      ),
      body: Column(
        children: [
          // 用 Obx 监听新消息变化以自动刷新
          Expanded(
            child: GetBuilder<ConversationModel>(
              builder: (_, model) {
                final messages = model.messages[widget.conversationId] ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) => ChatBubble(
                    message: messages[index],
                    isMine: messages[index].sender == 'me',
                    onTap: () {/* ... */},
                  ),
                );
              },
            ),
          ),

          // 底部输入区
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // 输入框
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: '发送消息...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
      ],
    );
  }
}