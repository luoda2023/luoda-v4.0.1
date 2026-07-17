// 针对 LUODA(微信壳层)核心逻辑的单元测试。
// 设计说明：本环境无显示、后端 Rust 原生库未编译，故只测"纯 Dart 逻辑层"
// （会话状态 / 聊天 store / 绑定合并等价路径）。FFI 调用(bind.*)在 store 内
// 已被 try/catch 兜住，缺失原生库时仅静默失败，不影响内存态逻辑验证。
//
// 运行： flutter test test/luoda_logic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:luoda_flutter/ui/states/app_state.dart';
import 'package:luoda_flutter/ui/states/chat_message_state.dart';
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
      // 取消置顶
      c.pin('b');
      expect(c.conversations.firstWhere((e) => e.id == 'b').pinned, isFalse);
      // 取消后按时间倒序
      expect(c.filtered().map((e) => e.id).toList(), ['c', 'b', 'a']);
    });

    test('applyOnlineStates 刷新占位文字，但绝不覆盖真实聊天预览', () {
      final c = ConversationState();
      Get.put(c);
      c.conversations.value = [
        // 真实聊天预览：必须被保留
        Conversation(id: 'p1', name: 'P1', peerId: 'p1',
            lastMessage: '昨天我们聊过方案', lastTime: DateTime(2023)),
        // 占位文字：应被更新为 在线/离线
        Conversation(id: 'p2', name: 'P2', peerId: 'p2', lastMessage: '未知'),
        // 系统/mock 行（peerId 空）：永不参与在线查询，文字不动
        Conversation(id: 'dev_001', name: '办公电脑', lastMessage: '在线'),
      ];
      c.applyOnlineStates({'p1', 'p2'}); // p1、p2 在线
      final p1 = c.conversations.firstWhere((e) => e.id == 'p1');
      final p2 = c.conversations.firstWhere((e) => e.id == 'p2');
      final dev = c.conversations.firstWhere((e) => e.id == 'dev_001');
      expect(p1.lastMessage, '昨天我们聊过方案'); // 关键：真实预览保留
      expect(p1.isOnline, isTrue);
      expect(p2.lastMessage, '在线'); // 占位被刷新
      expect(p2.isOnline, isTrue);
      expect(dev.lastMessage, '在线'); // 系统行不动
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
      c.applyOnlineStates({}); // 都不在线
      expect(c.conversations.firstWhere((e) => e.id == 'p1').lastMessage,
          '文件已收到');
      expect(c.conversations.firstWhere((e) => e.id == 'p2').lastMessage,
          '离线');
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
        Conversation(id: 'sys', name: '系统', lastMessage: '在线'), // peerId 空
      ];
      final map = c.contactsByPlatform();
      expect(map.containsKey('windows'), isTrue);
      expect(map.containsKey('macos'), isTrue);
      expect(map.containsKey('linux'), isTrue);
      expect(map.containsKey(''), isFalse); // 系统项不进通讯录
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

      app.activeConversation = 'x'; // 打开会话
      c.recordIncoming('x', 'again'); // 活跃中，不累加未读
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
        Conversation(id: 'b1', name: 'PC1', peerId: 'b1',
            lastMessage: '已绑定设备')
      ];
      c.ensureBoundDevices([
        (id: 'b1', name: 'PC1'),
        (id: 'b2', name: 'PC2'),
      ]);
      expect(c.conversations.where((e) => e.peerId == 'b1' || e.peerId == 'b2').length, 2);
      // 再次合并不应重复
      c.ensureBoundDevices([
        (id: 'b1', name: 'PC1'),
        (id: 'b2', name: 'PC2'),
      ]);
      expect(c.conversations.where((e) => e.peerId == 'b1' || e.peerId == 'b2').length, 2);
    });
  });

  group('ChatMessageState — 收发/持久化联动/跨设备合并', () {
    test('send 落一条我方消息、触发 onMessage(mine=true) 并尝试真实 transport', () {
      final chat = ChatMessageState();
      Get.put(chat);
      var onMsgCalls = 0;
      String? transportedConv;
      String? transportedText;
      chat.setOnMessage((id, text, mine) {
        onMsgCalls++;
        expect(mine, isTrue);
      });
      chat.setTransport((conv, text) async {
        transportedConv = conv;
        transportedText = text;
      });
      chat.send('c1', 'hello');
      expect(chat.messagesOf('c1').length, 1);
      expect(chat.messagesOf('c1').first.sender, 'me');
      expect(chat.messagesOf('c1').first.text, 'hello');
      expect(chat.messagesOf('c1').first.isMine, isTrue);
      expect(onMsgCalls, 1);
      expect(transportedConv, 'c1');
      expect(transportedText, 'hello');
    });

    test('receive 落对端消息并触发 onMessage(mine=false)', () {
      final chat = ChatMessageState();
      Get.put(chat);
      var mineFlag = true;
      chat.setOnMessage((id, text, mine) => mineFlag = mine);
      chat.receive('c2', 'peerA', 'hi there');
      expect(chat.messagesOf('c2').length, 1);
      expect(chat.messagesOf('c2').first.sender, 'peerA');
      expect(chat.messagesOf('c2').first.isMine, isFalse);
      expect(mineFlag, isFalse);
    });

    test('send 忽略空白；无原生库时也不因持久化崩溃', () {
      final chat = ChatMessageState();
      Get.put(chat);
      chat.send('c', '   ');
      expect(chat.messagesOf('c').length, 0);
      chat.send('c', 'real');
      expect(chat.messagesOf('c').length, 1); // 内存态正常，尽管持久化被 try/catch 兜住
    });

    test('exportHistory / importHistory 按时间去重合并', () {
      final a = ChatMessageState();
      Get.put(a);
      a.send('c', 'one');
      final snap = a.exportHistory();
      expect(snap.containsKey('c'), isTrue);

      final b = ChatMessageState();
      Get.put(b);
      b.importHistory(snap);
      expect(b.messagesOf('c').length, 1);

      b.receive('c', 'peer', 'two');
      expect(b.messagesOf('c').length, 2);

      b.importHistory(snap); // 重新导入不应产生重复 'one'
      expect(b.messagesOf('c').where((m) => m.text == 'one').length, 1);
      expect(b.messagesOf('c').length, 2);
    });

    test('system() 追加系统居中消息', () {
      final chat = ChatMessageState();
      Get.put(chat);
      chat.system('c', '已建立远程连接');
      final m = chat.messagesOf('c').first;
      expect(m.isSystem, isTrue);
      expect(m.sender, 'system');
    });
  });
}
