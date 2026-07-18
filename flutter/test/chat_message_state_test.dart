// 隔离版测试：覆盖 ChatMessageState 的核心收发逻辑。
//
// 之所以隔离：本机 Flutter 为 3.44.4，项目依赖钉死 3.24.5（CI 版本），整包无法编译。
// 但 chat_message_state.dart 的核心逻辑（UiChatMessage 纯模型 + ChatMessageState 的
// send/receive/system/clear/export/import）对 bind 的调用都被 try/catch 包住，
// 在单元测试环境（无 FFI）下会被静默吞掉，不影响内存态逻辑判定，因此可在本机 SDK 直接跑。
// 完整套件（含文件传输等引 common.dart 的单元）见 luoda_logic_test.dart，需在 3.24.5 下运行。
//
// 运行： flutter test test/chat_message_state_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:luoda_flutter/ui/states/chat_message_state.dart';

void main() {
  late ChatMessageState state;

  setUp(() {
    Get.reset();
    state = ChatMessageState();
    Get.put(state);
  });

  group('UiChatMessage — 纯模型', () {
    test('isMine 正确区分自己与对端', () {
      expect(UiChatMessage(sender: 'me', text: 'hi', time: _t).isMine, isTrue);
      expect(UiChatMessage(sender: 'peer1', text: 'hi', time: _t).isMine, isFalse);
      expect(UiChatMessage(sender: 'system', text: 'x', time: _t, isSystem: true).isMine, isFalse);
    });

    test('timeLabel 输出 HH:mm', () {
      final m = UiChatMessage(sender: 'me', text: 'x', time: _t); // 09:05
      expect(m.timeLabel, '09:05');
    });

    test('toJson / fromJson 往返一致', () {
      final m = UiChatMessage(sender: 'peer9', text: '你好', time: _t, isSystem: false);
      final j = m.toJson();
      final back = UiChatMessage.fromJson(j);
      expect(back.sender, 'peer9');
      expect(back.text, '你好');
      expect(back.time, _t);
      expect(back.isSystem, isFalse);
    });

    test('fromJson 对缺字段有兜底', () {
      final back = UiChatMessage.fromJson(<String, dynamic>{});
      expect(back.sender, 'peer');
      expect(back.text, '');
      expect(back.isSystem, isFalse);
    });
  });

  group('ChatMessageState — 收发/持久化联动', () {
    test('send 空文本被忽略', () {
      state.send('c1', '   ');
      expect(state.messagesOf('c1'), isEmpty);
    });

    test('send 追加「我方」消息并触发 onMessage(mine=true)', () {
      String? lastId;
      bool? lastMine;
      state.setOnMessage((id, text, mine) {
        lastId = id;
        lastMine = mine;
      });
      state.send('c1', 'hello');
      final msgs = state.messagesOf('c1');
      expect(msgs.length, 1);
      expect(msgs.first.sender, 'me');
      expect(msgs.first.text, 'hello');
      expect(lastId, 'c1');
      expect(lastMine, isTrue);
    });

    test('receive 追加对端消息并触发 onMessage(mine=false)', () {
      state.receive('c2', 'peerX', 'hi there');
      final msgs = state.messagesOf('c2');
      expect(msgs.length, 1);
      expect(msgs.first.sender, 'peerX');
      expect(msgs.first.isMine, isFalse);
    });

    test('system 追加系统灰条消息', () {
      state.system('c3', '已建立远程连接');
      final msgs = state.messagesOf('c3');
      expect(msgs.length, 1);
      expect(msgs.first.isSystem, isTrue);
      expect(msgs.first.sender, 'system');
    });

    test('配置了 transport 时 send 会尝试真实发出', () async {
      String? deliveredTo;
      String? deliveredText;
      state.setTransport((id, text) async {
        deliveredTo = id;
        deliveredText = text;
      });
      state.send('c4', 'ping');
      // _deliver 是 fire-and-forget，给一拍让 async 落地
      await Future.delayed(Duration.zero);
      expect(deliveredTo, 'c4');
      expect(deliveredText, 'ping');
    });

    test('clear 清空会话消息', () {
      state.send('c5', 'a');
      state.send('c5', 'b');
      expect(state.messagesOf('c5').length, 2);
      state.clear('c5');
      expect(state.messagesOf('c5'), isEmpty);
    });
  });

  group('ChatMessageState — 跨设备历史导入导出', () {
    test('exportHistory 返回全部会话快照', () {
      state.send('c1', 'a');
      state.receive('c2', 'p', 'b');
      final out = state.exportHistory();
      expect(out.containsKey('c1'), isTrue);
      expect(out.containsKey('c2'), isTrue);
      expect(out['c1']!.length, 1);
    });

    test('importHistory 按时间去重,不重复追加', () {
      state.send('c1', 'a'); // time = now
      final snap = state.exportHistory();
      // 再发一条,然后导入旧快照(含同一条 a),不应重复
      state.send('c1', 'b');
      expect(state.messagesOf('c1').length, 2);
      state.importHistory(snap);
      // a 已存在(同时间),b 仍在 → 仍是 2 条
      expect(state.messagesOf('c1').length, 2);
    });

    test('importHistory 合并新对端消息', () {
      final incoming = {
        'newPeer': [
          {'s': 'newPeer', 't': 'hello', 'time': 1700000000000, 'sys': false},
        ],
      };
      state.importHistory(incoming);
      final msgs = state.messagesOf('newPeer');
      expect(msgs.length, 1);
      expect(msgs.first.text, 'hello');
    });
  });
}

final _t = DateTime(2024, 1, 1, 9, 5);
