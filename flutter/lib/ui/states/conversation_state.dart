// flutter/lib/ui/states/conversation_state.dart
// 会话状态管理：会话列表/未读数/最后消息

import 'package:get/get.dart';
import 'package:luoda_flutter/models/platform_model.dart';
import 'app_state.dart';
import 'package:luoda_flutter/ui/states/chat_message_state.dart';

/// LUODA: 消息权限状态（微信壳层「常连接」三色指示）。
/// - always   🟢 常连接：已建立后台常连接，可随时收发消息
/// - canSend  🔵 可发消息：对方在线但未建立常连接，需先建立连接/会话才能收发
/// - rejected 🔴 已拒接：对方关闭了「允许随时接收消息」或本端已拉黑
enum MessagePermission {
  always,
  canSend,
  rejected,
}

extension MessagePermissionX on MessagePermission {
  String get label {
    switch (this) {
      case MessagePermission.always:
        return '常连接';
      case MessagePermission.canSend:
        return '可发消息';
      case MessagePermission.rejected:
        return '已拒接';
    }
  }

  /// UI 显示颜色（与微信三色一致：绿/蓝/红）
  int get colorValue {
    switch (this) {
      case MessagePermission.always:
        return 0xFF07C160; // 绿
      case MessagePermission.canSend:
        return 0xFF10AEFF; // 蓝
      case MessagePermission.rejected:
        return 0xFFFA5151; // 红
    }
  }
}

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

 /// LUODA: 是否置顶（会话列表优先显示）。
 final bool pinned;

 /// LUODA: 设备平台（windows/macos/linux/android/ios/server/unknown），
 /// 用于在设备列表显示对应图标（与 PC 端 DeviceCard 一致）。
 final String platform;

 /// LUODA: 真实的 LUODA peer ID（用于调 bind.queryOnlines 查在线状态）。
 /// 空字符串表示这条会话不是真实设备（例如 mock 项、文件传输助手等），
 /// 不参与在线状态查询，绿点永远不亮。
 final String peerId;

 /// LUODA: 是否在线。由 `applyOnlineStates` 周期更新。
 /// 只在 `peerId` 非空时才有意义。
 final bool isOnline;

 /// LUODA: 消息权限状态（🟢常连接 / 🔵可发 / 🔴拒接）。
 final MessagePermission permission;

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
    this.pinned = false,
    this.platform = '',
    this.peerId = '',
    this.isOnline = false,
    this.permission = MessagePermission.canSend,
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
   bool? pinned,
   String? platform,
   String? peerId,
   bool? isOnline,
   MessagePermission? permission,
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
   pinned: pinned ?? this.pinned,
   platform: platform ?? this.platform,
   peerId: peerId ?? this.peerId,
   isOnline: isOnline ?? this.isOnline,
   permission: permission ?? this.permission,
 );
 }
}

/// 会话状态管理
class ConversationState extends GetxController {
 /// 所有会话列表
 final RxList<Conversation> conversations = <Conversation>[].obs;

 /// 当前选中的会话ID
 String get activeId => appState.activeConversation;

 /// LUODA: 「允许随时接收消息」主开关（常连接总开关）。
 final RxBool allowAlwaysReceive = false.obs;

 /// LUODA: 常连接白名单（已授权随时收发消息的 peerId 集合）。
 final RxSet<String> whitelist = <String>{}.obs;

 ConversationState() {
 _loadSettings();
 // 加载示例数据（无真实 peer 时兜底显示，方便首次安装看到 UI）
 _loadMockData();
 // LUODA: 若已持久化白名单/总开关，进入常连接同步（ChatMessageState 未就绪时自动跳过）。
 syncChatConnections();
 }

  /// LUODA: 从本地持久化加载主开关与白名单。
  /// 注意：key 必须与 Rust 侧 `is_chat_always_enabled()` / `is_in_chat_whitelist()`
  /// 读取的 `allow_always_receive_msg` / `chat_whitelist` 完全一致，否则两端设置不同步。
  void _loadSettings() {
    try {
      allowAlwaysReceive.value =
          bind.mainGetLocalOption(key: 'allow_always_receive_msg') == 'Y';
      final raw = bind.mainGetLocalOption(key: 'chat_whitelist');
      if (raw.isNotEmpty) {
        whitelist.value = raw
            .split(RegExp(r'[,;\s]+'))
            .where((e) => e.isNotEmpty)
            .toSet();
      }
    } catch (_) {}
  }

  /// LUODA: 切换主开关并持久化，然后同步后台常连接。
  void setAllowAlwaysReceive(bool v) {
    allowAlwaysReceive.value = v;
    try {
      bind.mainSetLocalOption(
          key: 'allow_always_receive_msg', value: v ? 'Y' : 'N');
    } catch (_) {}
    refreshPermissions();
    syncChatConnections();
  }

  /// LUODA: 把 peerId 加入/移出常连接白名单并持久化，然后同步后台常连接。
  void toggleWhitelist(String peerId) {
    final next = Set<String>.from(whitelist);
    if (next.contains(peerId)) {
      next.remove(peerId);
    } else {
      next.add(peerId);
    }
    whitelist.value = next;
    try {
      bind.mainSetLocalOption(key: 'chat_whitelist', value: next.join(','));
    } catch (_) {}
    refreshPermissions();
    syncChatConnections();
  }

  /// LUODA: 依据主开关/白名单/在线态，把需要常连接的联系人同步到 Rust 后台连接管理器。
  /// - 在线 + 已授权(白名单) + 总开关开 → startChatConnection 获取后台 connId，
  ///   交给 ChatMessageState 用于 cmSendChat 路由（无需活跃远程会话即可收发）。
  /// - 否则（关闭/未授权/离线）→ 停止并清理该联系人的常连接。
  Future<void> syncChatConnections() async {
    if (!Get.isRegistered<ChatMessageState>()) return;
    final chat = Get.find<ChatMessageState>();
    final enabled = allowAlwaysReceive.value;
    final wl = whitelist.toSet();
    for (final peerId in wl) {
      if (peerId.isEmpty) continue;
      if (!enabled) {
        try {
          await bind.stopChatConnection(peerId: peerId);
        } catch (_) {}
        chat.clearAlwaysConnection(peerId);
        continue;
      }
      final isOnline =
          conversations.any((c) => c.peerId == peerId && c.isOnline);
      if (!isOnline) {
        try {
          await bind.stopChatConnection(peerId: peerId);
        } catch (_) {}
        chat.clearAlwaysConnection(peerId);
        continue;
      }
      try {
        final connId = await bind.startChatConnection(peerId: peerId);
        if (connId > 0) {
          chat.setAlwaysConnection(peerId, connId);
        }
      } catch (_) {}
    }
  }

  /// LUODA: 根据主开关/白名单/在线态计算消息权限三色状态。
  MessagePermission _calcPermission(Conversation c, bool online) {
    if (c.peerId.isEmpty) return c.permission; // 系统/mock 项保持
    if (!allowAlwaysReceive.value) return MessagePermission.canSend;
    if (!whitelist.contains(c.peerId)) return MessagePermission.canSend;
    if (!online) return MessagePermission.canSend;
    return MessagePermission.always;
  }

  /// LUODA: 主开关/白名单变化后，仅重算消息权限三色状态（不改变在线态/预览文字）。
  void refreshPermissions() {
    var changed = false;
    final next = <Conversation>[];
    for (final c in conversations) {
      final p = _calcPermission(c, c.isOnline);
      if (p != c.permission) {
        next.add(c.copyWith(permission: p));
        changed = true;
      } else {
        next.add(c);
      }
    }
    if (changed) conversations.value = next;
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
 platform: 'windows',
 // peerId 留空 -> 不参与在线查询
 ),
 const Conversation(
 id: 'dev_002',
 name: '家庭服务器',
 lastMessage: '已断开',
 unreadCount: 2,
 isGroup: false,
 avatarText: '家',
 platform: 'server',
 ),
 const Conversation(
 id: 'dev_003',
 name: '会议室工作站',
 lastMessage: '连接中...',
 unreadCount: 0,
 isGroup: false,
 avatarText: '会',
 platform: 'linux',
 ),
 ];
 }

 /// LUODA: 把真实 peer 列表替换/合并进会话列表。
 /// 当 [peers] 非空时,会清空 mock 项,以真实 peer 重建会话列表。
 /// 每条 peer 映射成一条 Conversation:
 /// - id = peer.id (LUODA 真实 ID)
 /// - peerId = peer.id (用于在线状态查询)
 /// - name = peer.alias || peer.hostname || peer.id
 /// - lastMessage = '在线' / '离线' / '未知' 由 applyOnlineStates 填
 /// - avatarText = name 的第一个字符
 /// LUODA: 改为「合并」而非「覆盖」——保留已有真实 peer 会话的聊天预览/未读/置顶，
 /// 以及已绑定设备、手动联系人（原每 30s 覆盖式刷新会清掉这些状态，导致未读角标与
 /// 聊天预览周期性消失）。仅当 peers 为空时才保留 mock 兜底。
 void reloadFromPeers(List<({String id, String alias, String hostname, String platform})> peers) {
 if (peers.isEmpty) {
 // 没有真实设备时,保留 mock 兜底
 return;
 }
 final Map<String, Conversation> merged = {};
 // 1. 保留所有已有「真实 peer 会话」(peerId 非空)：聊天预览/未读/置顶/绑定设备/手动联系人
 for (final c in conversations) {
 if (c.peerId.isNotEmpty) merged[c.peerId] = c;
 }
 // 2. 合并本轮 hbbs peers：仅更新名称/平台，不覆盖预览/未读/置顶
 for (final p in peers) {
 final name = (p.alias.isNotEmpty ? p.alias : (p.hostname.isNotEmpty ? p.hostname : p.id));
 final avatarText = name.isEmpty ? 'D' : name.substring(0, 1);
 final existing = merged[p.id];
 if (existing != null) {
 merged[p.id] = existing.copyWith(
 name: name,
 avatarText: avatarText,
 platform: p.platform.isNotEmpty ? p.platform : existing.platform,
 );
 } else {
 merged[p.id] = Conversation(
 id: p.id,
 name: name,
 peerId: p.id,
 isOnline: false,
 lastMessage: '未知',
 avatarText: avatarText,
 platform: p.platform,
 );
 }
 }
 conversations.value = merged.values.toList();
 }

  /// LUODA: 根据 hbbs 返回的在线 ID 列表,更新 conversations 的 isOnline 字段。
  /// 仅当某行 lastMessage 还是「在线状态占位文字」时才刷新该文字；
  /// 若用户已与该设备产生真实聊天,会保留真实聊天预览,不被 '在线'/'离线' 覆盖。
  /// 不会触发不存在 peer 的会话(避免误改文件传输助手等系统会话)。
  void applyOnlineStates(Set<String> onlineIds) {
    var changed = false;
    final next = <Conversation>[];
    for (final c in conversations) {
      if (c.peerId.isEmpty) {
        // 系统会话/mock 项不动
        next.add(c);
        continue;
      }
      final online = onlineIds.contains(c.peerId);
      // 状态未变、预览未变、权限也未变：保持原样，避免无谓重建
      if (online == c.isOnline &&
          !isStatusPlaceholder(c.lastMessage) &&
          _calcPermission(c, online) == c.permission) {
        next.add(c);
        continue;
      }
      // 状态变化，或仍为状态占位文字 -> 更新在线态；仅占位时刷新文字
      final newMsg = isStatusPlaceholder(c.lastMessage)
          ? (online ? '在线' : '离线')
          : c.lastMessage;
      final same = online == c.isOnline && newMsg == c.lastMessage;
      final permission = _calcPermission(c, online);
      next.add(c.copyWith(
          isOnline: online, lastMessage: newMsg, permission: permission));
      if (!same || permission != c.permission) changed = true;
    }
    if (changed) {
      conversations.value = next;
    }
    // LUODA: 在线态变化后重新同步常连接（覆盖断线重连场景）。
    syncChatConnections();
  }

 /// 根据当前导航和过滤返回会话列表
 /// LUODA: 置顶会话始终排在前面（保持各自时间序）。
 List<Conversation> filtered({String? keyword}) {
   var list = conversations.toList();
   if (keyword != null && keyword.isNotEmpty) {
     list = list
         .where((c) => c.name.toLowerCase().contains(keyword.toLowerCase()))
         .toList();
   }
   list.sort((a, b) {
     if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
     // 同置顶态下按最后消息时间倒序（无时间者排后）
     final ta = a.lastTime?.millisecondsSinceEpoch ?? 0;
     final tb = b.lastTime?.millisecondsSinceEpoch ?? 0;
     return tb.compareTo(ta);
   });
   return list;
 }

 /// LUODA: 通讯录分组——按平台归类所有真实设备(peerId 非空)。
 /// 返回顺序：server/windows/macos/linux/android/ios/unknown。
 static const List<String> _platformOrder = [
   'server',
   'windows',
   'macos',
   'linux',
   'android',
   'ios',
   'unknown',
 ];
 Map<String, List<Conversation>> contactsByPlatform() {
   final map = <String, List<Conversation>>{};
   for (final c in conversations) {
     if (c.peerId.isEmpty) continue; // 系统/mock 项不进通讯录
     final p = c.platform.isEmpty ? 'unknown' : c.platform;
     (map[p] ??= []).add(c);
   }
   final ordered = <String, List<Conversation>>{};
   for (final p in _platformOrder) {
     if (map.containsKey(p)) {
       ordered[p] = map[p]!..sort((a, b) => a.name.compareTo(b.name));
     }
   }
   // 兜底任何未列出的平台
   for (final p in map.keys) {
     if (!ordered.containsKey(p)) {
       ordered[p] = map[p]!..sort((a, b) => a.name.compareTo(b.name));
     }
   }
   return ordered;
 }

  /// 标记会话已读
  void markRead(String id) {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx >= 0 && conversations[idx].unreadCount > 0) {
      final dec = conversations[idx].unreadCount;
      conversations[idx] = conversations[idx].copyWith(unreadCount: 0);
      _recalcUnread(-dec);
    }
  }

  /// 我方发出消息后，更新会话列表的最后一条/时间（不增加未读）
  void recordOutgoing(String id, String text) {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    conversations[idx] = conversations[idx].copyWith(
      lastMessage: text,
      lastTime: DateTime.now(),
    );
  }

  /// 收到对方消息后，更新最后一条/时间；若当前未打开该会话则未读 +1
  void recordIncoming(String id, String text) {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final c = conversations[idx];
    final isActive = appState.activeConversation == id;
    final add = isActive ? 0 : 1;
    conversations[idx] = c.copyWith(
      lastMessage: text,
      lastTime: DateTime.now(),
      unreadCount: c.unreadCount + add,
    );
    if (add > 0) _recalcUnread(add);
  }

  /// LUODA: 把已绑定的「自己其他设备」作为私有联系人加入会话列表，
  /// 使其与普通联系人走同一条 P2P 聊天链路（即「和联系人同步一样」）。
  /// 已存在的（按 peerId）不会重复添加。
  void ensureBoundDevices(List<({String id, String name})> devices) {
    if (devices.isEmpty) return;
    var changed = false;
    final next = conversations.toList();
    for (final d in devices) {
      if (next.any((c) => c.peerId == d.id)) continue;
      final name = d.name.isNotEmpty ? d.name : d.id;
      next.add(Conversation(
        id: d.id,
        name: name,
        peerId: d.id,
        lastMessage: '已绑定设备',
        lastTime: DateTime.now(),
        avatarText: name.isEmpty ? 'D' : name.substring(0, 1),
        platform: 'server',
      ));
      changed = true;
    }
    if (changed) conversations.value = next;
  }

  /// 删除会话
  void remove(String id) {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final dec = conversations[idx].unreadCount;
      conversations.removeAt(idx);
      if (dec > 0) _recalcUnread(-dec);
    }
  }

  /// 置顶/取消置顶会话（切换 pinned 状态，置顶项在列表中优先显示）
  void pin(String id) {
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      conversations[idx] = conversations[idx].copyWith(pinned: !conversations[idx].pinned);
    }
  }

  /// LUODA: 判断一条 lastMessage 是否只是「在线状态占位文字」而非真实聊天内容。
  /// 用于在线状态刷新时只覆盖占位行，避免清掉用户与该设备的真实聊天预览。
  static const Set<String> _statusPlaceholders = {
    '在线',
    '离线',
    '未知',
    '已绑定设备',
    '已断开',
    '连接中...',
  };
  static bool isStatusPlaceholder(String? msg) {
    if (msg == null || msg.isEmpty) return true;
    return _statusPlaceholders.contains(msg);
  }

  /// 重新计算全局未读角标（避免每次遍历全部会话）
  void _recalcUnread(int delta) {
    final next = (appState.totalUnread.value + delta).clamp(0, 1 << 30);
    appState.totalUnread.value = next;
  }
}
