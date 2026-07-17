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
 // 加载示例数据（无真实 peer 时兜底显示，方便首次安装看到 UI）
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
 void reloadFromPeers(List<({String id, String alias, String hostname, String platform})> peers) {
 if (peers.isEmpty) {
 // 没有真实设备时,保留 mock 兜底
 return;
 }
 final list = peers.map((p) {
 final name = (p.alias.isNotEmpty ? p.alias : (p.hostname.isNotEmpty ? p.hostname : p.id));
 final avatarText = name.isEmpty ? 'D' : name.substring(0, 1);
 return Conversation(
 id: p.id,
 name: name,
 peerId: p.id,
 isOnline: false,
 lastMessage: '未知',
 avatarText: avatarText,
 platform: p.platform,
 );
 }).toList();
 conversations.value = list;
 }

 /// LUODA: 根据 hbbs 返回的在线 ID 列表,更新 conversations 的 isOnline 字段。
 /// 同时把 lastMessage 同步成 '在线' / '离线',方便会话列表看到状态。
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
 if (online != c.isOnline || c.lastMessage == '未知') {
 next.add(c.copyWith(
 isOnline: online,
 lastMessage: online ? '在线' : '离线',
 ));
 changed = true;
 } else {
 next.add(c);
 }
 }
 if (changed) {
 conversations.value = next;
 }
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

  /// 重新计算全局未读角标（避免每次遍历全部会话）
  void _recalcUnread(int delta) {
    final next = (appState.totalUnread.value + delta).clamp(0, 1 << 30);
    appState.totalUnread.value = next;
  }
}
