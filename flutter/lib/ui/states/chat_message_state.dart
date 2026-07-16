// flutter/lib/ui/states/chat_message_state.dart
// UI 层轻量聊天消息存储。
//
// 说明：仓库里已有的 models/chat_model.dart 是遗留的「浮窗聊天」实现，
// 深度耦合 dash_chat_2 / 多窗口 / platform_model 全家桶，不适合新 ui/ 框架的
// 整屏聊天页直接复用。这里在 ui/states/ 层提供一个自给自足的消息 store，
// 与 conversation_state.dart 同层同风格：
//   - 按会话 ID 分桶存消息，Rx 响应式；
//   - send() 先本地落一条「我方」消息（UI 即时可见）；
//   - receive() 供后端（Rust FFI「常连接」通道）回推对方消息时调用。
// 真实的收发链路在「常连接」阶段接到后端，这里的接口保持稳定。

import 'package:get/get.dart';

/// 单条聊天消息（UI 层模型）
class UiChatMessage {
  /// 发送方标识：'me' 表示自己，其余为对端 peerId/名称
  final String sender;

  /// 文本内容
  final String text;

  /// 发送/接收时间
  final DateTime time;

  /// 是否系统消息（居中灰条，如「已建立连接」）
  final bool isSystem;

  const UiChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.isSystem = false,
  });

  bool get isMine => sender == 'me';

  /// HH:mm 形式的时间戳文本
  String get timeLabel {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// 聊天消息 store：按会话分桶管理消息列表
class ChatMessageState extends GetxController {
  /// conversationId -> 消息列表（时间升序）
  final RxMap<String, RxList<UiChatMessage>> _buckets =
      <String, RxList<UiChatMessage>>{}.obs;

  /// 取某会话的消息列表（不存在则创建空桶）
  RxList<UiChatMessage> messagesOf(String conversationId) {
    return _buckets.putIfAbsent(
      conversationId,
      () => <UiChatMessage>[].obs,
    );
  }

  /// 发送一条「我方」文本消息
  void send(String conversationId, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    messagesOf(conversationId).add(UiChatMessage(
      sender: 'me',
      text: t,
      time: DateTime.now(),
    ));
  }

  /// 收到对方消息（供后端「常连接」通道回推调用）
  void receive(String conversationId, String sender, String text) {
    messagesOf(conversationId).add(UiChatMessage(
      sender: sender,
      text: text,
      time: DateTime.now(),
    ));
  }

  /// 追加系统消息（如「已建立远程连接」）
  void system(String conversationId, String text) {
    messagesOf(conversationId).add(UiChatMessage(
      sender: 'system',
      text: text,
      time: DateTime.now(),
      isSystem: true,
    ));
  }

  /// 清空某会话消息
  void clear(String conversationId) {
    _buckets[conversationId]?.clear();
  }
}

/// 全局便捷访问
ChatMessageState get chatMessages => Get.find<ChatMessageState>();
