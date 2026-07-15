// flutter/lib/ui/states/app_state.dart
// 应用全局状态：当前导航/会话/窗口

import 'package:flutter/material.dart';
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
