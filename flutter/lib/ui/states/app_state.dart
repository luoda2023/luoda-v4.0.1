// flutter/lib/ui/states/app_state.dart
// 应用全局状态：当前导航/会话/窗口

import 'package:get/get.dart';

/// 主导航区域
enum NavSection {
 /// 会话（最近设备+聊天）
 chat,
 /// 通讯录（设备列表）
 contacts,
 /// 文件传输
 files,
 /// 设置
 settings,
}

/// 与 LUODA rendezvous 服务器(rev.dicad.cn) 的连接状态。
/// home_page 右下角"正在连接 / 已连接 rev.dicad.cn / 无法连接"由它驱动。
enum ServerConnectionStatus {
 /// 还没触发过 queryOnlines,首屏默认状态
 connecting,
 /// bind.queryOnlines 调用无抛异常 -> 视为服务器可达
 connected,
 /// bind.queryOnlines 抛异常 -> 服务器不可达
 disconnected,
}

/// 会话过滤
enum ConversationFilter {
  /// 全部
  all,
  /// 在线
  online,
  /// 收藏
  starred,
  /// 群组
  group,
}

/// 应用全局UI状态
class AppState extends GetxController {
  /// 当前导航
  final Rx<NavSection> _nav = NavSection.chat.obs;
  NavSection get nav => _nav.value;
  set nav(NavSection v) => _nav.value = v;

  /// 当前会话过滤
  final Rx<ConversationFilter> _filter = ConversationFilter.all.obs;
  ConversationFilter get filter => _filter.value;
  set filter(ConversationFilter v) => _filter.value = v;

  /// 当前选中的会话 ID（peerId 或会话键）
  final RxString _activeConversation = ''.obs;
  String get activeConversation => _activeConversation.value;
  set activeConversation(String v) => _activeConversation.value = v;

  /// 搜索关键词
  final RxString _searchKeyword = ''.obs;
  String get searchKeyword => _searchKeyword.value;
  set searchKeyword(String v) => _searchKeyword.value = v;

  /// 是否显示侧栏（移动端可隐藏）
  final RxBool _showSidebar = true.obs;
  bool get showSidebar => _showSidebar.value;
  set showSidebar(bool v) => _showSidebar.value = v;

  /// 是否显示会话列表（小屏可隐藏）
  final RxBool _showConversationList = true.obs;
  bool get showConversationList => _showConversationList.value;
  set showConversationList(bool v) => _showConversationList.value = v;

 /// 全屏模式（远程桌面全屏）
 final RxBool _fullscreen = false.obs;
 bool get fullscreen => _fullscreen.value;
 set fullscreen(bool v) => _fullscreen.value = v;

 /// 与 LUODA 服务器(rev.dicad.cn)的连接状态。home_page 右下角状态文字条由此驱动。
 /// 由 home_page 周期 queryOnlines 结果更新。
 final Rx<ServerConnectionStatus> _serverStatus =
 ServerConnectionStatus.connecting.obs;
 ServerConnectionStatus get serverStatus => _serverStatus.value;
 set serverStatus(ServerConnectionStatus v) => _serverStatus.value = v;

 /// 暗色模式开关（驱动 GetMaterialApp 的 themeMode，设置页可切换）
 final RxBool isDarkMode = false.obs;
 void toggleDarkMode() => isDarkMode.value = !isDarkMode.value;
 void setDarkMode(bool v) => isDarkMode.value = v;

 /// 全部会话未读数合计（侧栏会话图标角标用）
 final RxInt totalUnread = 0.obs;

  void selectNav(NavSection section) {
    nav = section;
    if (section == NavSection.chat) {
      filter = ConversationFilter.all;
    }
  }

  void selectConversation(String id) {
    activeConversation = id;
  }

  void toggleSidebar() => _showSidebar.value = !_showSidebar.value;
  void toggleConversationList() =>
      _showConversationList.value = !_showConversationList.value;
  void toggleFullscreen() => _fullscreen.value = !_fullscreen.value;
}

/// 全局AppState实例
AppState get appState => Get.find<AppState>();
