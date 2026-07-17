// flutter/lib/models/binding_model.dart
// 手机 <-> PC 直连绑定与自动同步（去中间/中继服务器）。
//
// 设计（与用户需求一致）：
//   1. PC 端展示二维码（ldesk://bind?id=<PC的ID>&name=<名称>），手机扫码即绑定。
//   2. 绑定后，只要 PC 在运行，手机端每 30 分钟自动刷新该 PC 的状态——
//      走局域网发现（mainDiscover + mainGetLanPeers），不经过任何中继服务器。
//   3. 绑定关系持久化在本机（mainGetLocalOption / mainSetLocalOption），
//      首次扫码后永不重复要求，可随时在「设备」页解绑。
//
// 该 State 在 main.dart 的 _registerUiControllers 中注册，桌面/移动端通用。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../common.dart';
import '../ui/states/conversation_state.dart';
import 'platform_model.dart';

/// 一个被绑定的 PC。
class BoundPc {
  final String id;
  String name;
  String lanIp; // 局域网直连地址（发现到时填入）
  int lastSync; // 最近一次同步的 epoch 毫秒
  bool online; // 当前是否通过局域网发现到

  BoundPc({
    required this.id,
    required this.name,
    this.lanIp = '',
    this.lastSync = 0,
    this.online = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lanIp': lanIp,
        'lastSync': lastSync,
        'online': online,
      };

  factory BoundPc.fromJson(Map<String, dynamic> m) => BoundPc(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        lanIp: m['lanIp'] ?? '',
        lastSync: m['lastSync'] is int ? m['lastSync'] : 0,
        online: m['online'] == true,
      );
}

/// 绑定状态管理（GetX）。
class BindingState extends GetxController {
  /// 已绑定的 PC 列表。
  final RxList<BoundPc> bindings = <BoundPc>[].obs;

  Timer? _timer;

  static const String _kOptionKey = 'ldesk_bindings';

  @override
  void onInit() {
    super.onInit();
    load();
    startAutoSync();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// 从本机持久化读取绑定关系。
  Future<void> load() async {
    try {
      final raw = bind.mainGetLocalOption(key: _kOptionKey);
      if (raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        bindings.value = list
            .whereType<Map<String, dynamic>>()
            .map((e) => BoundPc.fromJson(e))
            .where((b) => b.id.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('BindingState.load failed: $e');
    }
  }

  /// 持久化绑定关系到本机。
  Future<void> save() async {
    try {
      final json =
          jsonEncode(bindings.map((b) => b.toJson()).toList());
      await bind.mainSetLocalOption(key: _kOptionKey, value: json);
    } catch (e) {
      debugPrint('BindingState.save failed: $e');
    }
  }

  /// 添加（或更新）一个绑定。已存在则直接触发一次同步。
  void addBinding(String id, String name) {
    if (id.isEmpty) return;
    final idx = bindings.indexWhere((b) => b.id == id);
    if (idx >= 0) {
      // 已绑定：更新名称（如有）并立即同步一次。
      final updated = bindings[idx]
        ..name = (name.isNotEmpty ? name : bindings[idx].name);
      bindings[idx] = updated;
      save();
      syncNow();
      return;
    }
    bindings.add(BoundPc(id: id, name: name.isNotEmpty ? name : id));
    save();
    syncNow();
  }

  /// 解绑。
  void removeBinding(String id) {
    bindings.removeWhere((b) => b.id == id);
    save();
    _removeFromConversations(id);
  }

  /// 启动自动同步：立即同步一次，之后每 30 分钟一次。
  void startAutoSync() {
    if (isWeb) return; // 浏览器无局域网能力，跳过周期性发现（移动/桌面端照常）
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => syncNow());
    syncNow();
  }

  /// 立即同步一次：走局域网发现（不经过中继服务器）。
  Future<void> syncNow() async {
    if (bindings.isEmpty) return;
    try {
      // 局域网广播发现，命中同一 WiFi/网段内运行的 PC。
      bind.mainDiscover();
      // 直接读取局域网发现的 PC 列表（返回 JSON 字符串）。
      final raw = await bind.mainGetLanPeers();
      final lanList = (jsonDecode(raw) as List?) ?? [];
      final lanMap = <String, Map<String, dynamic>>{};
      for (final e in lanList) {
        if (e is Map<String, dynamic> && (e['id'] ?? '').isNotEmpty) {
          lanMap[e['id'] as String] = e;
        }
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final next = <BoundPc>[];
      for (final b in bindings) {
        final lan = lanMap[b.id];
        b.online = lan != null;
        b.lanIp = (lan?['ip'] as String?) ?? '';
        b.lastSync = now;
        next.add(b);
      }
      bindings.value = next;
      _mergeIntoConversations();
    } catch (e) {
      debugPrint('BindingState.syncNow failed: $e');
    }
  }

  /// 把绑定 PC 合并进会话列表，使其在「消息 / 设备」中可见并显示在线状态。
  /// 仅当该行 lastMessage 仍是「在线状态占位文字」时才刷新文字，
  /// 避免每 30 分钟同步把用户与该设备的真实聊天预览覆盖成「在线/离线」。
  void _mergeIntoConversations() {
    if (!Get.isRegistered<ConversationState>()) return;
    final conv = Get.find<ConversationState>();
    for (final b in bindings) {
      final idx = conv.conversations.indexWhere((c) => c.id == b.id);
      if (idx >= 0) {
        final existing = conv.conversations[idx];
        final newMsg = ConversationState.isStatusPlaceholder(existing.lastMessage)
            ? (b.online ? '在线' : '离线')
            : existing.lastMessage;
        conv.conversations[idx] = existing.copyWith(
          isOnline: b.online,
          lastMessage: newMsg,
        );
      } else {
        conv.conversations.add(Conversation(
          id: b.id,
          name: b.name,
          peerId: b.id, // 真实 peer，参与在线查询
          isOnline: b.online,
          lastMessage: b.online ? '在线' : '离线',
          avatarText: b.name.isNotEmpty ? b.name[0] : 'D',
          platform: '',
        ));
      }
    }
  }

  void _removeFromConversations(String id) {
    if (!Get.isRegistered<ConversationState>()) return;
    final conv = Get.find<ConversationState>();
    conv.conversations.removeWhere((c) => c.id == id && c.peerId == id);
  }

  /// 判断某会话/设备是否是绑定的 PC。
  bool isBound(String id) => bindings.any((b) => b.id == id);

  /// 取绑定 PC 的局域网直连地址（用于优先直连）。
  String lanIpOf(String id) {
    final b = bindings.firstWhereOrNull((e) => e.id == id);
    return b?.lanIp ?? '';
  }
}
