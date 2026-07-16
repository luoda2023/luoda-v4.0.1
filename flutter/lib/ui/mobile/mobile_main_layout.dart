// flutter/lib/ui/mobile/mobile_main_layout.dart
// LUODA 手机端微信风格主壳（移动端标准尺寸）。
//
// 复用桌面端已写好的微信状态层（ConversationState / ChatMessageState /
// AppState），在窄屏上用「底部 Tab（消息 / 设备 / 服务 / 我）+ 会话列表
// → 聊天详情」组织，并完整保留移动端原有功能：远程连接(ConnectionPage)、
// 被控(ServerPage)、设置(SettingsPage)。
//
// 文字尺寸严格按移动端人机规范（微信手机版标准）：
//   标题 17 / 正文 16 / 次要 13 / 时间 12，触摸目标 >= 48dp。
// 桌面端继续使用 AppTextStyles（PC 标准），互不影响。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';
import '../../mobile/pages/connection_page.dart';
import '../../mobile/pages/server_page.dart';
import '../../mobile/pages/settings_page.dart';
import '../components/avatar.dart';
import '../components/chat_bubble.dart';
import '../components/server_connection_bar.dart';
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
    connect(context, id);
  }

  // ============ 布局 ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildTabBody(),
          // 消息 tab 内：选中会话时以全屏覆盖层显示聊天详情（带返回）
          Obx(() => (_tabIndex == 0 && _appState.activeConversation.isNotEmpty)
              ? _MobileChatPage(
                  conversationId: _appState.activeConversation,
                  onBack: () => _appState.selectConversation(''),
                )
              : const SizedBox.shrink()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabBody() {
    final tabs = <Widget>[
      _buildMessageListPage(),
      ConnectionPage(appBarActions: const []),
      if (isAndroid) ServerPage(),
      SettingsPage(),
    ];
    return tabs[_tabIndex.clamp(0, tabs.length - 1)];
  }

  /// 消息 Tab 主页面：顶栏 + 连接入口 + 会话列表 + 托盘状态条。
  Widget _buildMessageListPage() {
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

  /// 顶部导航（微信手机版风格：浅灰底 + 居中深色标题 + 右侧图标）。
  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.background,
      child: Row(
        children: [
          const Text('LUODA', style: MobileTextStyles.navTitle),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search,
                size: 24, color: AppColors.textPrimary),
            onPressed: () {},
            tooltip: '搜索',
          ),
          Obx(() => IconButton(
                icon: Icon(
                  _appState.isDarkMode.value
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
                onPressed: _appState.toggleDarkMode,
                tooltip: '日间 / 夜间',
              )),
        ],
      ),
    );
  }

  /// 快速连接入口（输入对方 ID / IP:端口）。
  Widget _buildConnectEntry() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _connectController,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _onConnect(),
              style: MobileTextStyles.input,
              decoration: InputDecoration(
                hintText: '输入对方 ID 或 IP:端口号',
                hintStyle: MobileTextStyles.inputHint,
                isDense: true,
                filled: true,
                fillColor: AppColors.cardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        return Center(
          child: Text('暂无设备', style: MobileTextStyles.sectionLabel),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.divider,
          indent: 76,
        ),
        itemBuilder: (context, i) {
          final c = list[i];
          return _ConversationTile(
            conversation: c,
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
                  count: unread, child: const Icon(Icons.chat_bubble_outline))
              : const Icon(Icons.chat_bubble_outline),
          label: '消息',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.computer_outlined),
          label: '设备',
        ),
      ];
      if (isAndroid) {
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.screen_share_outlined),
          label: '服务',
        ));
      }
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: '我',
      ));
      return BottomNavigationBar(
        currentIndex: _tabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: MobileTextStyles.tabLabel,
        unselectedLabelStyle: MobileTextStyles.tabLabel,
        onTap: (i) => setState(() => _tabIndex = i),
        items: items,
      );
    });
  }
}

/// 会话列表项（微信手机版：圆角方形头像 48 + 名称 16 + 预览 13 + 时间 12 +
/// 在线绿点 / 未读红点；整行高度 64，触摸友好）。
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile(
      {required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: AppColors.conversationListBg,
        child: Row(
          children: [
            _RoundSquareAvatar(
              text: c.avatarText ?? 'D',
              online: c.isOnline,
              unread: c.unreadCount,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: MobileTextStyles.conversationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_timeLabel(c),
                          style: MobileTextStyles.conversationTime),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    c.lastMessage ?? '',
                    style: MobileTextStyles.conversationPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(Conversation c) {
    final t = c.lastTime;
    if (t == null) return '';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays == 0) {
      return '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    }
    return '${t.month}/${t.day}';
  }
}

/// 微信手机版圆角方形头像（48，圆角 6）+ 在线绿点 + 未读红点。
class _RoundSquareAvatar extends StatelessWidget {
  final String text;
  final bool online;
  final int unread;

  const _RoundSquareAvatar(
      {required this.text, this.online = false, this.unread = 0});

  static const List<Color> _palette = [
    AppColors.primaryGreen,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[text.hashCode % _palette.length];
    final initial = text.isEmpty ? '?' : text[0].toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (online)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.conversationListBg,
                  width: 2,
                ),
              ),
            ),
          ),
        if (unread > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.unreadBadge,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.conversationListBg,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 手机版聊天详情页（微信手机版尺寸：标题 17 / 气泡 16 / 输入 16）。
class _MobileChatPage extends StatefulWidget {
  final String conversationId;
  final VoidCallback onBack;

  const _MobileChatPage(
      {required this.conversationId, required this.onBack});

  @override
  State<_MobileChatPage> createState() => _MobileChatPageState();
}

class _MobileChatPageState extends State<_MobileChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatMessageState get _store => Get.find<ChatMessageState>();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _store.send(widget.conversationId, text);
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _title {
    final convs = Get.find<ConversationState>().conversations;
    final idx = convs.indexWhere((c) => c.id == widget.conversationId);
    return idx >= 0 ? convs[idx].name : widget.conversationId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildMessageList()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.contentAreaBg,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 24, color: AppColors.textPrimary),
            onPressed: widget.onBack,
            tooltip: '返回',
          ),
          Expanded(
            child: Text(
              _title,
              style: MobileTextStyles.chatTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cast_connected,
                size: 24, color: AppColors.primaryGreen),
            onPressed: () => connect(Get.context!, widget.conversationId),
            tooltip: '发起远程协助',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: AppColors.background,
      child: Obx(() {
        final messages = _store.messagesOf(widget.conversationId);
        if (messages.isEmpty) {
          return Center(
            child: Text('还没有消息，打个招呼吧',
                style: MobileTextStyles.sectionLabel),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final m = messages[index];
            if (m.isSystem) {
              return ChatBubble(
                type: ChatBubbleType.system,
                text: m.text,
                textStyle: MobileTextStyles.chatSystem,
              );
            }
            return ChatBubble(
              type: m.isMine ? ChatBubbleType.mine : ChatBubbleType.other,
              text: m.text,
              timestamp: m.timeLabel,
              textStyle: MobileTextStyles.chatMessage,
              avatar: m.isMine
                  ? null
                  : Avatar(text: _title, size: 40),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      color: AppColors.contentAreaBg,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: MobileTextStyles.input,
                decoration: InputDecoration(
                  hintText: '输入消息…',
                  hintStyle: MobileTextStyles.inputHint,
                  filled: true,
                  fillColor: AppColors.cardBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textOnDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Text('发送',
                  style: MobileTextStyles.listItem
                      .copyWith(color: AppColors.textOnDark)),
            ),
          ],
        ),
      ),
    );
  }
}
