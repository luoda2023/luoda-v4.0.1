// flutter/lib/ui/states/chat_message_state.dart
// 微信风格聊天消息存储（UI 层唯一消息源），并接上真实收发链路。
//
// 架构（与「联系人同步」同源，去中间服务器）：
//  - 发送：先本地落一条「我方」消息（UI 即时可见），再尝试经当前活跃 P2P 会话
//    (gFFI.sessionId) 调用 sessionSendChat 真正发给对端；消息不经任何服务器。
//  - 接收：models/model.dart 的 chat_client_mode / chat_server_mode 事件回推对端消息，
//    由该处调用本 store 的 receive() 写入对应会话（对端 peerId 即会话 id）。
//  - 持久化：每条会话消息用 mainGetLocalOption / mainSetLocalOption 存本地
//    （key = ldesk_chat_<conversationId>），重启不丢。
//  - PC↔手机：绑定设备互为私有联系人（见 binding_model.dart），与本机其他联系人
//    走同一条 P2P 聊天链路，记录各自本地持久化 —— 即「和联系人同步一样」。

import 'dart:convert';

import 'package:get/get.dart';
import 'package:luoda_flutter/common.dart';
import 'package:luoda_flutter/models/platform_model.dart';

/// 单条聊天消息（UI 层模型）
class UiChatMessage {
  /// 发送方标识：'me' 表示自己，其余为对端
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

  Map<String, dynamic> toJson() => {
        's': sender,
        't': text,
        'time': time.millisecondsSinceEpoch,
        'sys': isSystem,
      };

  factory UiChatMessage.fromJson(Map<String, dynamic> j) => UiChatMessage(
        sender: j['s'] as String? ?? 'peer',
        text: j['t'] as String? ?? '',
        time: DateTime.fromMillisecondsSinceEpoch(j['time'] as int? ?? 0),
        isSystem: j['sys'] as bool? ?? false,
      );
}

/// 聊天消息 store：按会话分桶管理消息列表
class ChatMessageState extends GetxController {
  /// conversationId -> 消息列表（时间升序）
  final RxMap<String, RxList<UiChatMessage>> _buckets =
      <String, RxList<UiChatMessage>>{}.obs;

  /// 已惰性加载过的会话（避免重复读本地）
  final Set<String> _loaded = {};

  /// 真实发送通道：由会话层（models/model.dart）注入，经活跃 P2P 会话发出。
  /// 为 null 时只本地留存（例如尚未与该对端建立连接）。
  Future<void> Function(String conversationId, String text)? _transport;

  /// 消息落库后的联动回调（会话列表最后一条/未读数），由壳层注册。
  void Function(String id, String text, bool mine)? _onMessage;

  void setTransport(Future<void> Function(String, String)? fn) => _transport = fn;

  void setOnMessage(void Function(String id, String text, bool mine)? fn) =>
      _onMessage = fn;

  /// LUODA: 常连接映射 peerId -> 后台常驻连接的 connId。
  /// 非空时该联系人的聊天走 cmSendChat（无需活跃远程会话）。
  final Map<String, int> _alwaysConnIds = {};

  /// LUODA: 注册某联系人的常连接 connId（后台保活成功后调用）。
  void setAlwaysConnection(String peerId, int connId) {
    _alwaysConnIds[peerId] = connId;
  }

  /// LUODA: 清除某联系人的常连接（断开/取消授权时调用）。
  void clearAlwaysConnection(String peerId) {
    _alwaysConnIds.remove(peerId);
  }

  @override
  void onInit() {
    super.onInit();
    _initTransport();
  }

  /// LUODA: 初始化真实发送通道（Gap A 修复：从一开始即就绪，不再等收到消息）。
  /// 路由优先级：常连接 connId > 活跃会话 sessionSendChat。
  void _initTransport() {
    setTransport((conversationId, text) async {
      // 1. 常连接优先：若该联系人有后台常驻连接，直接经 cmSendChat 发。
      final connId = _alwaysConnIds[conversationId];
      if (connId != null) {
        try {
          await gFFI.cmSendChat(connId: connId, msg: text);
          return;
        } catch (_) {
          // 常连接异常则降级到会话/本地
        }
      }
      // 2. 活跃远程会话兜底：仅当当前会话对端正是该联系人时经 sessionSendChat 发。
      final sid = gFFI.sessionId;
      if (sid != null && gFFI.id == conversationId) {
        try {
          await gFFI.sessionSendChat(sessionId: sid, text: text);
        } catch (_) {}
      }
      // 否则仅本地留存（send() 已落库）
    });
  }

  /// 取某会话的消息列表（不存在则创建空桶，并惰性从本地加载）
  RxList<UiChatMessage> messagesOf(String conversationId) {
    _ensureLoaded(conversationId);
    return _buckets.putIfAbsent(
      conversationId,
      () => <UiChatMessage>[].obs,
    );
  }

  void _ensureLoaded(String id) {
    if (_loaded.contains(id)) return;
    _loaded.add(id);
    try {
      final raw = bind.mainGetLocalOption(key: 'ldesk_chat_$id');
      if (raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        final msgs = list
            .map((e) => UiChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        if (msgs.isNotEmpty) {
          _buckets[id] = msgs.obs;
        }
      }
    } catch (_) {
      // 本地读失败不影响内存态
    }
  }

  void _persist(String id) {
    try {
      final list = messagesOf(id).map((m) => m.toJson()).toList();
      bind.mainSetLocalOption(
          key: 'ldesk_chat_$id', value: jsonEncode(list));
    } catch (_) {
      // 持久化失败不阻塞聊天
    }
  }

  /// 发送一条「我方」文本消息：本地即时可见 + 持久化 + 联动 + 真实发出
  void send(String conversationId, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    messagesOf(conversationId).add(UiChatMessage(
      sender: 'me',
      text: t,
      time: DateTime.now(),
    ));
    _persist(conversationId);
    _onMessage?.call(conversationId, t, true);
    _deliver(conversationId, t);
  }

  /// 收到对方消息（供后端「常连接」通道 / 入站事件回推调用）
  void receive(String conversationId, String sender, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    messagesOf(conversationId).add(UiChatMessage(
      sender: sender,
      text: t,
      time: DateTime.now(),
    ));
    _persist(conversationId);
    _onMessage?.call(conversationId, t, false);
  }

  /// 追加系统消息（如「已建立远程连接」）
  void system(String conversationId, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    messagesOf(conversationId).add(UiChatMessage(
      sender: 'system',
      text: t,
      time: DateTime.now(),
      isSystem: true,
    ));
    _persist(conversationId);
  }

  /// 清空某会话消息
  void clear(String conversationId) {
    messagesOf(conversationId).clear();
    _persist(conversationId);
  }

  /// 真实发送：仅当当前活跃 P2P 会话的对端正是该会话对象时才经 sessionSendChat 发出。
  void _deliver(String conversationId, String text) {
    final fn = _transport;
    if (fn == null) return;
    fn(conversationId, text).catchError((e) {
      // 发送失败（如对端已断开）仅本地留存，不抛异常
    });
  }

  /// 跨设备同步导出：返回全部会话的消息快照（供绑定局域网通道交换）
  Map<String, List<Map<String, dynamic>>> exportHistory() {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final entry in _buckets.entries) {
      out[entry.key] = entry.value.map((m) => m.toJson()).toList();
    }
    return out;
  }

  /// 跨设备同步导入：合并对端设备推来的消息快照（按时间去重）
  void importHistory(Map<String, List<Map<String, dynamic>>> data) {
    data.forEach((id, list) {
      final incoming = list
          .map((e) => UiChatMessage.fromJson(e))
          .toList();
      if (incoming.isEmpty) return;
      final bucket = messagesOf(id);
      final existing = bucket.map((m) => m.time.millisecondsSinceEpoch).toSet();
      for (final m in incoming) {
        if (!existing.contains(m.time.millisecondsSinceEpoch)) {
          bucket.add(m);
        }
      }
      _persist(id);
    });
  }
}

/// 全局便捷访问
ChatMessageState get chatMessages => Get.find<ChatMessageState>();
