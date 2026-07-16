// flutter/lib/ui/pages/home_page.dart
// 微信风格设备列表页（首页）

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/conversation_item.dart';
import '../components/search_bar.dart';
import '../components/server_connection_bar.dart';
import '../states/app_state.dart';
import '../states/conversation_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
// LUODA: 拉真实 peer 列表 + 调 hbbs 在线状态查询
// `gFFI` 全局定义在 common.dart; `bind` / `platformFFI` 全局定义在
// models/platform_model.dart
import '../../common.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';

class HomePage extends StatefulWidget {
 const HomePage({Key? key}) : super(key: key);

 @override
 State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 Timer? _onlineQueryTimer;
 Timer? _reloadPeersTimer;
 static const String _onlineEventName = 'callback_query_onlines';
 static const String _onlineHandlerKey = 'home_page_online';

 @override
 void initState() {
 super.initState();
 // 1. 注册 hbbs 在线状态回调: Rust 端把结果通过 platformFFI 事件推回来
 platformFFI.registerEventHandler(
 _onlineEventName,
 _onlineHandlerKey,
 (Map<String, dynamic> evt) async {
 final onlineStr = evt['onlines'] as String? ?? '';
 final offlineStr = evt['offlines'] as String? ?? '';
 final onlineSet = <String>{};
 if (onlineStr.isNotEmpty) {
 onlineSet.addAll(onlineStr.split(',').where((s) => s.isNotEmpty));
 }
 // offlines 字符串目前不显示,但保持订阅以便日后扩展
 // ignore: unused_local_variable
 final offlineList = offlineStr.split(',').where((s) => s.isNotEmpty).toList();
 final convState = Get.find<ConversationState>();
 convState.applyOnlineStates(onlineSet);
 },
 );

 // 2. 启动周期查询: 每 6 秒调一次 bind.queryOnlines,只对带 peerId 的会话
 _onlineQueryTimer = Timer.periodic(const Duration(seconds: 6), (_) {
 _triggerQueryOnlines();
 });
 // 立即跑一次,避免首屏等 6 秒
 Timer.run(_triggerQueryOnlines);

 // 3. 启动周期从真实 PeerStore 拉设备列表同步进 ConversationState
 Timer.run(_reloadPeersFromStore);
 _reloadPeersTimer = Timer.periodic(const Duration(seconds: 30), (_) {
 _reloadPeersFromStore();
 });
 }

 @override
 void dispose() {
 _onlineQueryTimer?.cancel();
 _onlineQueryTimer = null;
 _reloadPeersTimer?.cancel();
 _reloadPeersTimer = null;
 platformFFI.unregisterEventHandler(_onlineEventName, _onlineHandlerKey);
 super.dispose();
 }

 /// 收集所有带 peerId 的 conversation,调 Rust 端去查 hbbs 在线状态。
 /// 没有任何真实 peer 时跳过,避免压服务器。
 void _triggerQueryOnlines() {
 final convState = Get.find<ConversationState>();
 final appState = Get.find<AppState>();
 final ids = convState.conversations
 .where((c) => c.peerId.isNotEmpty)
 .map((c) => c.peerId)
 .toSet()
 .toList();
 if (ids.isEmpty) {
 // 没有真实 peer 不能证明服务器是否可达;保留上一状态,不主动改写
 return;
 }
 try {
 bind.queryOnlines(ids: ids);
 // queryOnlines 是异步 FFI 调用,只要不抛异常说明 FFI 通道、hbbs 都可达
 appState.serverStatus = ServerConnectionStatus.connected;
 } catch (e) {
 // queryOnlines 失败不应该让 UI 崩,后台日志即可
 // 同时给用户右下角文字提示:服务器暂不可达
 appState.serverStatus = ServerConnectionStatus.disconnected;
 debugPrint('queryOnlines failed: $e');
 }
 }

 /// 从 PeerStore 拉真实 peer 列表,塞进 ConversationState。
 /// 优先从 recentPeersModel 拉取;若为空,fallback 到 abModel 的当前地址簿。
 void _reloadPeersFromStore() {
 try {
 final convState = Get.find<ConversationState>();
 final peers = <Peer>[];
 // 优先用最近连接过的 peer
 if (gFFI.recentPeersModel.peers.isNotEmpty) {
 peers.addAll(gFFI.recentPeersModel.peers);
 }
 // 地址簿补充(去重)
 for (final p in gFFI.abModel.currentAbPeers.toList()) {
 if (peers.every((e) => e.id != p.id)) {
 peers.add(p);
 }
 }
 if (peers.isEmpty) {
 // 无真实设备 -> 保留 mock 兜底
 return;
 }
 convState.reloadFromPeers(peers
 .map((p) => (
 id: p.id,
 alias: p.alias,
 hostname: p.hostname,
 platform: p.platform,
 ))
 .toList());
 } catch (e) {
 debugPrint('_reloadPeersFromStore failed: $e');
 }
 }

 @override
 Widget build(BuildContext context) {
 final appState = Get.find<AppState>();
 final convState = Get.find<ConversationState>();

 return Scaffold(
 backgroundColor: AppColors.background,
 appBar: AppBar(
 backgroundColor: AppColors.primaryGreen,
 title: const Text('设备列表', style: AppTextStyles.headline2),
 actions: [
 IconButton(
 icon: const Icon(Icons.search, color: AppColors.textOnDark),
 onPressed: () => appState.searchKeyword = '',
 ),
 IconButton(
 icon: const Icon(Icons.settings, color: AppColors.textOnDark),
 onPressed: () => Get.toNamed('/settings'),
 ),
 ],
 ),
 body: NestedScrollView(
 headerSliverBuilder: (ctx, sb) => [_buildSliverHeader(ctx)],
 body: Column(
 children: [
 StreamBuilder<List<Conversation>>(
 stream: convState.listenConversations(),
 builder: (context, snap) {
 final list = convState.filteredConvs(keyword: appState.searchKeyword);
 return Expanded(
 child: list.isEmpty
 ? const Center(child: Text("暂无设备"))
 : ListView.builder(
 padding: const EdgeInsets.symmetric(vertical: 8),
 itemCount: list.length,
 itemBuilder: (c, i) => ConversationItem(
 name: list[i].name,
 lastMessage: list[i].lastMessage,
 unreadCount: list[i].unreadCount,
 avatarText: list[i].avatarText ?? 'D',
 isOnline: list[i].isOnline,
 showOnlineDot: true,
 onTap: () => appState.selectConversation(list[i].id),
 ),
 ),
 );
 },
 ),
 Align(
 alignment: Alignment.bottomRight,
 child: const ServerConnectionBar(),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildSliverHeader(BuildContext c) {
 return SliverToBoxAdapter(
 child: WeChatSearchBar(
 hintText: '搜索设备或联系人',
 onChanged: (v) => Get.find<AppState>().searchKeyword = v,
 ),
 );
 }
}

// === mock helpers ===
extension ConversationStateX on ConversationState {
 Stream<List<Conversation>> listenConversations() async* {
 // periodically refresh
 while (true) {
 yield conversations.toList();
 await Future.delayed(const Duration(seconds: 3));
 }
 }

 List<Conversation> filteredConvs({String? keyword}) {
 final q = keyword?.toLowerCase() ?? '';
 return conversations.where((c) {
 return q.isEmpty || c.name.toLowerCase().contains(q);
 }).toList();
 }
}
