// 隔离版测试：只覆盖 ConversationState 的核心逻辑。
// 之所以隔离：本机 Flutter 为 3.44.4，而项目依赖被钉在 3.24.5（CI 版本）。
// 3.44.4 下 extended_text/google_fonts/DialogTheme 等 API 已破坏，整包无法编译；
// 但 conversation_state.dart 仅依赖 app_state.dart(flutter/material + get)，
// 不引入 common.dart 等被破坏的依赖，因此这套用例可在本机 SDK 直接跑通，
// 作为「在线态刷新绝不覆盖真实聊天预览」等关键逻辑的可运行证据。
// 完整套件（含 ChatMessageState）见 luoda_logic_test.dart，需在 3.24.5 下运行。
//
// 运行： flutter test test/conversation_state_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:luoda_flutter/ui/states/app_state.dart';
import 'package:luoda_flutter/ui/states/conversation_state.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put(AppState());
  });

  group('ConversationState — 置顶/排序/在线态/通讯录/未读', () {
    test('pin() 切换置顶；filtered() 置顶项始终最前', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [
        Conversation(id: 'a', name: 'A', lastTime: DateTime(2020)),
        Conversation(id: 'b', name: 'B', lastTime: DateTime(2021)),
        Conversation(id: 'c', name: 'C', lastTime: DateTime(2022)),
      ];
      c.pin('b');
      final list = c.filtered();
      expect(list.first.id, 'b');
      expect(list.first.pinned, isTrue);
      c.pin('b');
      expect(c.conversations.firstWhere((e) => e.id == 'b').pinned, isFalse);
      expect(c.filtered().map((e) => e.id).toList(), ['c', 'b', 'a']);
    });

    test('applyOnlineStates 刷新占位文字，但绝不覆盖真实聊天预览', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [
        Conversation(id: 'p1', name: 'P1', peerId: 'p1',
            lastMessage: '昨天我们聊过方案', lastTime: DateTime(2023)),
        Conversation(id: 'p2', name: 'P2', peerId: 'p2', lastMessage: '未知'),
        Conversation(id: 'dev_001', name: '办公电脑', lastMessage: '在线'),
      ];
      c.applyOnlineStates({'p1', 'p2'});
      final p1 = c.conversations.firstWhere((e) => e.id == 'p1');
      final p2 = c.conversations.firstWhere((e) => e.id == 'p2');
      final dev = c.conversations.firstWhere((e) => e.id == 'dev_001');
      expect(p1.lastMessage, '昨天我们聊过方案');
      expect(p1.isOnline, isTrue);
      expect(p2.lastMessage, '在线');
      expect(p2.isOnline, isTrue);
      expect(dev.lastMessage, '在线');
      expect(dev.isOnline, isFalse);
    });

    test('applyOnlineStates 离线时也只刷新占位行', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [
        Conversation(id: 'p1', name: 'P1', peerId: 'p1',
            lastMessage: '文件已收到', lastTime: DateTime(2023)),
        Conversation(id: 'p2', name: 'P2', peerId: 'p2', lastMessage: '未知'),
      ];
      c.applyOnlineStates({});
      expect(c.conversations.firstWhere((e) => e.id == 'p1').lastMessage, '文件已收到');
      expect(c.conversations.firstWhere((e) => e.id == 'p2').lastMessage, '离线');
    });

    test('isStatusPlaceholder 正确识别占位/真实文案', () {
      expect(ConversationState.isStatusPlaceholder('在线'), isTrue);
      expect(ConversationState.isStatusPlaceholder('离线'), isTrue);
      expect(ConversationState.isStatusPlaceholder('未知'), isTrue);
      expect(ConversationState.isStatusPlaceholder('已绑定设备'), isTrue);
      expect(ConversationState.isStatusPlaceholder('已断开'), isTrue);
      expect(ConversationState.isStatusPlaceholder('连接中...'), isTrue);
      expect(ConversationState.isStatusPlaceholder(null), isTrue);
      expect(ConversationState.isStatusPlaceholder(''), isTrue);
      expect(ConversationState.isStatusPlaceholder('我们周末见'), isFalse);
    });

    test('contactsByPlatform 按平台分组并排除系统会话', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [
        Conversation(id: '1', name: 'Win1', peerId: '1', platform: 'windows'),
        Conversation(id: '2', name: 'Mac1', peerId: '2', platform: 'macos'),
        Conversation(id: '3', name: 'Lin1', peerId: '3', platform: 'linux'),
        Conversation(id: 'sys', name: '系统', lastMessage: '在线'),
      ];
      final map = c.contactsByPlatform();
      expect(map.containsKey('windows'), isTrue);
      expect(map.containsKey('macos'), isTrue);
      expect(map.containsKey('linux'), isTrue);
      expect(map.containsKey(''), isFalse);
      expect(map['windows']!.length, 1);
    });

    test('recordIncoming 未打开会话时未读+1；打开后不再+1；markRead 归零并联动 totalUnread', () {
      final c = ConversationState();
      Get.put(c);
      final app = Get.find<AppState>();
      c.conversations.value = [Conversation(id: 'x', name: 'X', peerId: 'x')];
      c.recordIncoming('x', 'hi');
      expect(c.conversations.firstWhere((e) => e.id == 'x').unreadCount, 1);
      expect(app.totalUnread.value, 1);
      app.activeConversation = 'x';
      c.recordIncoming('x', 'again');
      expect(c.conversations.firstWhere((e) => e.id == 'x').unreadCount, 1);
      c.markRead('x');
      expect(c.conversations.firstWhere((e) => e.id == 'x').unreadCount, 0);
      expect(app.totalUnread.value, 0);
    });

    test('recordOutgoing 更新最后一条但不增加未读', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [Conversation(id: 'x', name: 'X', peerId: 'x')];
      c.recordOutgoing('x', '我发的');
      final conv = c.conversations.firstWhere((e) => e.id == 'x');
      expect(conv.lastMessage, '我发的');
      expect(conv.unreadCount, 0);
    });

    test('ensureBoundDevices 合并为私有联系人且不重复', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [
        Conversation(id: 'b1', name: 'PC1', peerId: 'b1', lastMessage: '已绑定设备')
      ];
      c.ensureBoundDevices([(id: 'b1', name: 'PC1'), (id: 'b2', name: 'PC2')]);
      expect(c.conversations.where((e) => e.peerId == 'b1' || e.peerId == 'b2').length, 2);
      c.ensureBoundDevices([(id: 'b1', name: 'PC1'), (id: 'b2', name: 'PC2')]);
      expect(c.conversations.where((e) => e.peerId == 'b1' || e.peerId == 'b2').length, 2);
    });
  });
}
