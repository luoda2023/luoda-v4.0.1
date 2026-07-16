// flutter/lib/ui/mobile/mobile_main_layout.dart
// LUODA 手机端微信风格主壳。
//
// 复用桌面端已写好的微信组件（ConversationState / ChatPage / ConversationItem /
// WeChatSearchBar / ServerConnectionBar / AppColors），在窄屏上用「底部 Tab
// （消息 / 设备 / 服务 / 我）+ 会话列表 → 聊天详情」组织，并完整保留移动端
// 原有功能：远程连接(ConnectionPage)、被控(ServerPage)、设置(SettingsPage)。
//
// 与桌面 MainLayout 共享同一套 ConversationState，因此手机端也能看到真实
// peer 列表、在线绿点、未读角标，并复用 ChatMessageState 收发消息。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';
import '../../mobile/pages/connection_page.dart';
import '../../mobile/pages/server_page.dart';
import '../../mobile/pages/settings_page.dart';
import '../components/conversation_item.dart';
import '../components/search_bar.dart';
import '../components/server_connection_bar.dart';
import '../pages/chat_page.dart';
import '../states/app_state.dart';
import '../states/chat_message_state.dart';
import '../states/conversation_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MobileMainLayout extends StatefulWidget {
  const MobileMainLayout({Key? key}) : super(key: key);

  @override
  State<MobileMainLayout> createState() => _MobileMainLayoutState();
}

class _MobileMainLayoutState extends State<MobileMainLayout> {
  int _tabIndex = 0;
  final TextEditingController _connectController = TextEditingController();
  Timer? _onlineQueryTimer;
  Timer? _reloadPeersTimer;
  final String _onlineEventName = 'callback_query_onlines';
  final String _onlineHandlerKey = 'mobile_main_layout_online';

  AppState get _appState => Get.find<AppState>();
  ConversationState get _convState => Get.find<ConversationState>();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ChatMessageState>()) {
      Get.put(ChatMessageState());
    }
    _setupPeerPolling();
  }

  @override
  void dispose() {
    _onlineQueryTimer?.cancel();
    _reloadPeersTimer?.cancel();
    _connectController.dispose();
    platformFFI.unregisterEventHandler(_onlineEventName, _onlineHandlerKey);
    super.dispose();
  }

  // ============ 真实数据管道（与桌面 MainLayout 同源）============

  void _setupPeerPolling() {
    platformFFI.registerEventHandler(
      _onlineEventName,
      _onlineHandlerKey,
      (Map<String, dynamic> evt) async {
        final onlineStr = evt['onlines'] as String? ?? '';
        final onlineSet = <String>{};
        if (onlineStr.isNotEmpty) {
          onlineSet.addAll(onlineStr.split(',').where((s) => s.isNotEmpty));
        }
        _convState.applyOnlineStates(onlineSet);
      },
    );
    _onlineQueryTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _queryOnlines());
    Timer.run(_queryOnlines);
    Timer.run(_reloadPeers);
    _reloadPeersTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _reloadPeers());
  }

  void _queryOnlines() {
    final ids = _convState.conversations
        .where((c) => c.peerId.isNotEmpty)
        .map((c) => c.peerId)
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    try {
      bind.queryOnlines(ids: ids);
      _appState.serverStatus = ServerConnectionStatus.connected;
    } catch (e) {
      _appState.serverStatus = ServerConnectionStatus.disconnected;
      debugPrint('queryOnlines failed: $e');
    }
  }

  void _reloadPeers() {
    try {
      final peers = <Peer>[];
      if (gFFI.recentPeersModel.peers.isNotEmpty) {
        peers.addAll(gFFI.recentPeersModel.peers);
      }
      for (final p in gFFI.abModel.currentAbPeers.toList()) {
        if (peers.every((e) => e.id != p.id)) peers.add(p);
      }
      if (peers.isEmpty) return;
      _convState.reloadFromPeers(peers
          .map((p) => (
                id: p.id,
                alias: p.alias,
                hostname: p.hostname,
                platform: p.platform,
              ))
          .toList());
    } catch (e) {
      debugPrint('_reloadPeers failed: $e');
    }
  }

  void _onConnect() {
    final id = _connectController.text.trim();
    if (id.isEmpty) {
      Get.snackbar('提示', '请输入对方 ID 或 IP:端口',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    // 真实发起远程连接（common.dart 全局函数）
    connect(context, id);
  }

  // ============ 布局 ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final tabs = <Widget>[
      _buildMessageTab(),
      ConnectionPage(appBarActions: const []),
      if (isAndroid) ServerPage(),
      SettingsPage(),
    ];
    return tabs[_tabIndex.clamp(0, tabs.length - 1)];
  }

  /// 消息 Tab：未选会话时显示会话列表，选中后显示聊天详情（全屏）。
  Widget _buildMessageTab() {
    return Obx(() {
      if (_appState.activeConversation.isEmpty) {
        return _buildConversationListPage();
      }
      return _buildChatDetail(_appState.activeConversation);
    });
  }

  Widget _buildChatDetail(String conversationId) {
    return Column(
      children: [
        _buildChatDetailHeader(conversationId),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(child: ChatPage(conversationId: conversationId)),
      ],
    );
  }

  Widget _buildChatDetailHeader(String conversationId) {
    final convs = _convState.conversations;
    final idx = convs.indexWhere((c) => c.id == conversationId);
    final title = idx >= 0 ? convs[idx].name : conversationId;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.contentAreaBg,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryGreen),
            onPressed: () => _appState.selectConversation(''),
          ),
          Expanded(
            child: Text(title,
                style: AppTextStyles.headline2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            tooltip: '发起远程协助',
            icon: const Icon(Icons.cast_connected,
                color: AppColors.primaryGreen),
            onPressed: () => connect(context, conversationId),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationListPage() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildConnectEntry(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildConversationList()),
            const Align(
              alignment: Alignment.centerLeft,
              child: ServerConnectionBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.navigationBarBg,
      child: Row(
        children: [
          const Text('LUODA',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Obx(() => IconButton(
                icon: Icon(
                  _appState.isDarkMode.value
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: _appState.toggleDarkMode,
              )),
        ],
      ),
    );
  }

  Widget _buildConnectEntry() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _connectController,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _onConnect(),
              decoration: InputDecoration(
                hintText: '输入对方 ID 或 IP:端口号',
                isDense: true,
                filled: true,
                fillColor: AppColors.contentAreaBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _onConnect,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.login, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return Obx(() {
      final keyword = _appState.searchKeyword;
      final list = _convState.filtered(keyword: keyword);
      if (list.isEmpty) {
        return const Center(
          child: Text('暂无设备',
              style: TextStyle(color: AppColors.textTertiary)),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final c = list[i];
          return ConversationItem(
            name: c.name,
            lastMessage: c.lastMessage,
            unreadCount: c.unreadCount,
            avatarText: c.avatarText ?? 'D',
            isOnline: c.isOnline,
            showOnlineDot: true,
            selected: false,
            onTap: () {
              _appState.selectConversation(c.id);
              _convState.markRead(c.id);
            },
          );
        },
      );
    });
  }

  Widget _buildBottomNav() {
    return Obx(() {
      final unread =
          _convState.conversations.fold<int>(0, (s, c) => s + c.unreadCount);
      final items = <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: unread > 0
              ? Badge.count(
                  count: unread, child: const Icon(Icons.chat_bubble))
              : const Icon(Icons.chat_bubble),
          label: '消息',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.connected_tv),
          label: '设备',
        ),
      ];
      if (isAndroid) {
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.mobile_screen_share),
          label: '服务',
        ));
      }
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: '我',
      ));
      return BottomNavigationBar(
        currentIndex: _tabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textTertiary,
        onTap: (i) => setState(() => _tabIndex = i),
        items: items,
      );
    });
  }
}
