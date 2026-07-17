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

  /// 文件传输 Tab 当前选中的目标设备 ID
  String _filePeerId = '';

  AppState get _appState => Get.find<AppState>();
  ConversationState get _convState => Get.find<ConversationState>();

  @override
  void initState() {
    super.initState();
    // 消息 store 惰性注册
    if (!Get.isRegistered<ChatMessageState>()) {
      Get.put(ChatMessageState());
    }
    // 聊天消息联动会话列表（最后一条/未读）
    chatMessages.setOnMessage((id, text, mine) {
      final conv = Get.find<ConversationState>();
      if (mine) {
        conv.recordOutgoing(id, text);
      } else {
        conv.recordIncoming(id, text);
      }
    });
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
        return _buildFilesMiddle();
      }
      if (nav == NavSection.contacts) {
        return _buildContactsMiddle();
      }
      return _buildChatMiddle();
    });
  }

  /// 会话 Tab 中栏：发起连接入口 + 搜索 + 会话列表
  Widget _buildChatMiddle() {
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
            pinned: c.pinned,
            selected: c.id == activeId,
            onTap: () {
              _appState.selectConversation(c.id);
              _convState.markRead(c.id);
              if (_appState.nav != NavSection.chat) {
                _appState.selectNav(NavSection.chat);
              }
            },
            onLongPress: () => _showConversationMenu(c),
          );
        },
      );
    });
  }

  // —— 右侧主区：设置 / 聊天 / 文件传输 / 欢迎 ——
  Widget _buildMainArea() {
    return Obx(() {
      if (_appState.nav == NavSection.settings) {
        return const SettingsPage();
      }
      if (_appState.nav == NavSection.files) {
        return _buildFilesMain();
      }
      final activeId = _appState.activeConversation;
      if (activeId.isEmpty) {
        return _buildWelcome();
      }
      return ChatPage(key: ValueKey(activeId), conversationId: activeId);
    });
  }

  // ============ 通讯录视图 ============

  Widget _buildContactsMiddle() {
    return Container(
      width: _middleWidth,
      color: AppColors.conversationListBg,
      child: Column(
        children: [
          Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text('通讯录',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return Obx(() {
      final groups = _convState.contactsByPlatform();
      if (groups.isEmpty) {
        return const Center(
          child: Text('暂无联系人', style: TextStyle(color: AppColors.textTertiary)),
        );
      }
      final entries = <Widget>[];
      groups.forEach((platform, list) {
        entries.add(_buildPlatformHeader(platform, list.length));
        for (final c in list) {
          entries.add(_buildContactTile(c));
        }
      });
      return ListView(children: entries);
    });
  }

  Widget _buildPlatformHeader(String platform, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      color: AppColors.conversationListBg,
      child: Text(
        '${_platformLabel(platform)}  ($count)',
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildContactTile(Conversation c) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryGreenLight,
          shape: BoxShape.circle,
        ),
        child: Icon(_platformIcon(c.platform),
            color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(c.name,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: c.isOnline ? AppColors.online : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          Text(c.isOnline ? '在线' : '离线',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
      onTap: () {
        _appState.selectConversation(c.id);
        _convState.markRead(c.id);
        _appState.selectNav(NavSection.chat);
      },
    );
  }

  // ============ 文件传输视图 ============

  Widget _buildFilesMiddle() {
    return Container(
      width: _middleWidth,
      color: AppColors.conversationListBg,
      child: Column(
        children: [
          Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text('文件传输',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _buildFileTargetList()),
        ],
      ),
    );
  }

  Widget _buildFileTargetList() {
    return Obx(() {
      final list = _convState.conversations
          .where((c) => c.peerId.isNotEmpty)
          .toList()
        ..sort((a, b) {
          if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
          return a.name.compareTo(b.name);
        });
      if (list.isEmpty) {
        return const Center(
          child: Text('暂无可用设备', style: TextStyle(color: AppColors.textTertiary)),
        );
      }
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final c = list[i];
          final selected = _filePeerId == c.id;
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(_platformIcon(c.platform),
                  color: AppColors.primaryGreen, size: 20),
            ),
            title: Text(c.name,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            subtitle: Text(c.isOnline ? '在线' : '离线',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            trailing: c.isOnline
                ? const Icon(Icons.file_upload, color: AppColors.primaryGreen)
                : null,
            selected: selected,
            selectedTileColor: AppColors.selected,
            onTap: () => setState(() => _filePeerId = c.id),
          );
        },
      );
    });
  }

  Widget _buildFilesMain() {
    if (_filePeerId.isEmpty) {
      return Container(
        color: AppColors.contentAreaBg,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.folder_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text('选择左侧设备发起文件传输',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('文件经由 P2P 直连传输，不经过任何服务器',
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
          ],
        ),
      );
    }
    Conversation? c;
    try {
      c = _convState.conversations.firstWhere((e) => e.id == _filePeerId);
    } catch (_) {
      c = null;
    }
    if (c == null) {
      return Container(
        color: AppColors.contentAreaBg,
        alignment: Alignment.center,
        child: const Text('设备不可用',
            style: TextStyle(color: AppColors.textTertiary)),
      );
    }
    return Container(
      color: AppColors.contentAreaBg,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryGreenLight,
              shape: BoxShape.circle,
            ),
            child: Icon(_platformIcon(c.platform),
                color: AppColors.primaryGreen, size: 36),
          ),
          const SizedBox(height: 16),
          Text(c.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            c.isOnline ? '设备在线，可安全传输' : '设备当前离线，可能无法连接',
            style: TextStyle(
                fontSize: 13,
                color: c.isOnline
                    ? AppColors.online
                    : AppColors.textTertiary),
          ),
          const SizedBox(height: 28),
          Material(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => connect(context, c!.id, isFileTransfer: true),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.file_upload, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('发起文件传输',
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('将打开安全 P2P 传输窗口（去服务器）',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  // ============ 会话菜单（置顶）============

  void _showConversationMenu(Conversation c) {
    Get.defaultDialog(
      title: c.name,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(c.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(c.pinned ? '取消置顶' : '置顶到顶部'),
            onTap: () {
              Get.back();
              _convState.pin(c.id);
            },
          ),
        ],
      ),
    );
  }

  // ============ 平台图标/文案 ============

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.desktop_mac;
      case 'linux':
        return Icons.computer;
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'server':
        return Icons.dns;
      default:
        return Icons.device_unknown;
    }
  }

  String _platformLabel(String platform) {
    switch (platform) {
      case 'windows':
        return 'Windows';
      case 'macos':
        return 'macOS';
      case 'linux':
        return 'Linux';
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'server':
        return '服务器';
      default:
        return '其他设备';
    }
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
