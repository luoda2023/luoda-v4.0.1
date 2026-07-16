// flutter/lib/ui/layout/main_layout.dart
// 微信 PC 版风格三栏主壳：窄导航条 + 中栏(发起连接/会话列表) + 右侧聊天主区。
//
// 布局对齐 UI-REDESIGN/luoda-wechat-ui.html 视觉基准：
//   [54px 深色导航] | [300px 中栏] | [剩余宽度 聊天主区]
// 真实数据：复用 home_page 的 peer 轮询与 hbbs 在线查询，塞进 ConversationState。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/conversation_item.dart';
import '../components/search_bar.dart';
import '../components/server_connection_bar.dart';
import '../components/sidebar_item.dart';
import '../pages/chat_page.dart';
import '../pages/settings_page.dart';
import '../states/app_state.dart';
import '../states/chat_message_state.dart';
import '../states/conversation_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
// LUODA 手机绑定：PC 端展示二维码，手机扫码直连绑定
import '../../desktop/widgets/bind_phone_dialog.dart';
// LUODA 后端：connect() 发起连接、gFFI 拉 peer、bind/platformFFI FFI 通道
import '../../common.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const double _navWidth = 54;
  static const double _middleWidth = 300;
  static const String _onlineEventName = 'callback_query_onlines';
  static const String _onlineHandlerKey = 'main_layout_online';

  final TextEditingController _connectController = TextEditingController();
  Timer? _onlineQueryTimer;
  Timer? _reloadPeersTimer;

  AppState get _appState => Get.find<AppState>();
  ConversationState get _convState => Get.find<ConversationState>();

  @override
  void initState() {
    super.initState();
    // 消息 store 惰性注册
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

  // ============ 真实数据管道（复用自 home_page 逻辑）============

  void _setupPeerPolling() {
    // 1. 注册 hbbs 在线状态回调
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

    // 2. 周期查询在线状态（6s）
    _onlineQueryTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _queryOnlines());
    Timer.run(_queryOnlines);

    // 3. 周期从 PeerStore 拉真实设备（30s）
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
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNavBar(),
          _buildMiddleColumn(),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(child: _buildMainArea()),
        ],
      ),
    );
  }

  // —— 左侧窄导航条 ——
  Widget _buildNavBar() {
    return Container(
      width: _navWidth,
      color: AppColors.navigationBarBg,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // LUODA logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('L',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final nav = _appState.nav;
            return Column(
              children: [
                SidebarItem(
                  icon: Icons.chat_bubble,
                  tooltip: '会话',
                  selected: nav == NavSection.chat,
                  badge: _appState.totalUnread.value,
                  selectedColor: Colors.white,
                  unselectedColor: Colors.white54,
                  onTap: () => _appState.selectNav(NavSection.chat),
                ),
                const SizedBox(height: 12),
                SidebarItem(
                  icon: Icons.contacts,
                  tooltip: '通讯录',
                  selected: nav == NavSection.contacts,
                  selectedColor: Colors.white,
                  unselectedColor: Colors.white54,
                  onTap: () => _appState.selectNav(NavSection.contacts),
                ),
                const SizedBox(height: 12),
                SidebarItem(
                  icon: Icons.folder,
                  tooltip: '文件',
                  selected: nav == NavSection.files,
                  selectedColor: Colors.white,
                  unselectedColor: Colors.white54,
                  onTap: () => _appState.selectNav(NavSection.files),
                ),
              ],
            );
          }),
          const Spacer(),
          // 暗色模式切换
          Obx(() => SidebarItem(
                icon: _appState.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
                tooltip: '切换主题',
                selectedColor: Colors.white,
                unselectedColor: Colors.white54,
                onTap: _appState.toggleDarkMode,
              )),
          const SizedBox(height: 12),
          Obx(() => SidebarItem(
                icon: Icons.settings,
                tooltip: '设置',
                selected: _appState.nav == NavSection.settings,
                selectedColor: Colors.white,
                unselectedColor: Colors.white54,
                onTap: () => _appState.selectNav(NavSection.settings),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // —— 中栏：发起连接入口 + 会话/联系人列表 ——
  Widget _buildMiddleColumn() {
    return Obx(() {
      final nav = _appState.nav;
      if (nav == NavSection.settings) {
        return const SizedBox.shrink();
      }
      if (nav == NavSection.files) {
        return Container(
          width: _middleWidth,
          color: AppColors.conversationListBg,
          child: const Center(
            child: Text('文件传输', style: TextStyle(color: AppColors.textTertiary)),
          ),
        );
      }
      return Container(
        width: _middleWidth,
        color: AppColors.conversationListBg,
        child: Column(
          children: [
            _buildConnectEntry(),
            const Divider(height: 1, color: AppColors.divider),
            WeChatSearchBar(
              hintText: '搜索设备或联系人',
              onChanged: (v) => _appState.searchKeyword = v,
            ),
            Expanded(child: _buildConversationList()),
            const Align(
              alignment: Alignment.centerLeft,
              child: ServerConnectionBar(),
            ),
          ],
        ),
      );
    });
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
          const SizedBox(width: 8),
          // 手机绑定：展示二维码，手机扫码即直连绑定
          Material(
            color: AppColors.contentAreaBg,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => showBindPhoneDialog(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.qr_code_2,
                    color: AppColors.primaryGreen, size: 20),
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
      final activeId = _appState.activeConversation;
      if (list.isEmpty) {
        return const Center(
          child: Text('暂无设备', style: TextStyle(color: AppColors.textTertiary)),
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
            selected: c.id == activeId,
            onTap: () {
              _appState.selectConversation(c.id);
              _convState.markRead(c.id);
              if (_appState.nav != NavSection.chat) {
                _appState.selectNav(NavSection.chat);
              }
            },
          );
        },
      );
    });
  }

  // —— 右侧主区：设置 / 聊天 / 欢迎 ——
  Widget _buildMainArea() {
    return Obx(() {
      if (_appState.nav == NavSection.settings) {
        return const SettingsPage();
      }
      final activeId = _appState.activeConversation;
      if (activeId.isEmpty) {
        return _buildWelcome();
      }
      return ChatPage(key: ValueKey(activeId), conversationId: activeId);
    });
  }

  Widget _buildWelcome() {
    return Container(
      color: AppColors.contentAreaBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('选择左侧联系人开始聊天', style: AppTextStyles.bodyText1),
          const SizedBox(height: 8),
          const Text('或在上方输入对方 ID 发起远程协助',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}
