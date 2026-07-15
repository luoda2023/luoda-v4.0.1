// flutter/lib/ui/states/conversation_state.dart
// 会话状态管理：会话列表/未读数/最后消息

import 'package:get/get.dart';
import 'app_state.dart';

/// 会话数据模型
class Conversation {
  final String id;
  final String name;
  final String? lastMessage;
  final DateTime? lastTime;
  final int unreadCount;
  final bool muted;
  final bool isGroup;
  final String? avatarText;
  final String? avatarUrl;

  const Conversation({
    required this.id,
    required this.name,
    this.lastMessage,
    this.lastTime,
    this.unreadCount = 0,
    this.muted = false,
    this.isGroup = false,
    this.avatarText,
    this.avatarUrl,
  });

  Conversation copyWith({
    String? name,
    String? lastMessage,
    DateTime? lastTime,
    int? unreadCount,
    bool? muted,
    bool? isGroup,
    String? avatarText,
    String? avatarUrl,
  }) {
    return Conversation(
      id: id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      muted: muted ?? this.muted,
      isGroup: isGroup ?? this.isGroup,
      avatarText: avatarText ?? this.avatarText,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// 会话状态管理
class ConversationState extends GetxController {
  /// 所有会话列表
  final RxList<Conversation> conversations = <Conversation>[].obs;

  /// 当前选中的会话ID
  String get activeId => appState.activeConversation;

  ConversationState() {
    // 加载示例数据
    _loadMockData();
  }

  void _loadMockData() {
    conversations.value = [
      const Conversation(
        id: 'dev_001',
        name: '我的办公电脑',
        lastMessage: '在线',
        unreadCount: 0,
        isGroup: false,
        avatarText: '办',
      ),
      const Conversation(
        id: 'dev_002',
        name: '家庭服务器',
        lastMessage: '已断开',
        unreadCount: 2,
        isGroup: false,
        avatarText: '家',
      ),
      const Conversation(
        id: 'dev_003',
        name: '会议室工作站',
        lastMessage: '连接中...',
        unreadCount: 0,
        isGroup: false,
        avatarText: '会',
      ),
    ];
  }

  /// 根据当前导航和过滤返回会话列表
  List<Conversation> filtered({String? keyword}) {
    var list = conversations.toList();
    if (keyword != null && keyword.isNotEmpty) {
      list = list
          .where((c) => c.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    return list;
  }

  /// 标记会话已读
  void markRead(String id) {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx >= 0 && conversations[idx].unreadCount > 0) {
      conversations[idx] = conversations[idx].copyWith(unreadCount: 0);
    }
  }

  /// 删除会话
  void remove(String id) {
    conversations.removeWhere((c) => c.id == id);
  }

  /// 置顶会话（暂未实现）
  void pin(String id) {
    // TODO: 置顶逻辑
  }
}
