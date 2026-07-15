// flutter/lib/ui/helpers/navigation_helper.dart
// 微信风格页面导航辅助

import 'package:flutter/material.dart';

/// 微信风格导航辅助类
///
/// 提供页面切换/弹窗等导航相关工具方法
class NavigationHelper {
  NavigationHelper._();

  /// 切换左侧导航栏主项
  static void switchSidebarItem(BuildContext context, int index) {
    // TODO: 实现导航切换
    debugPrint('switchSidebarItem: $index');
  }

  /// 打开会话（点击会话列表项）
  static void openConversation(BuildContext context, String conversationId) {
    // TODO: 实现打开会话
    debugPrint('openConversation: $conversationId');
  }

  /// 打开设备远程控制
  static void openRemoteDesktop(BuildContext context, String peerId) {
    // TODO: 实现打开远程桌面
    debugPrint('openRemoteDesktop: $peerId');
  }

  /// 打开文件传输
  static void openFileTransfer(BuildContext context, String peerId) {
    debugPrint('openFileTransfer: $peerId');
  }

  /// 打开终端
  static void openTerminal(BuildContext context, String peerId) {
    debugPrint('openTerminal: $peerId');
  }

  /// 打开摄像头视图
  static void openCamera(BuildContext context, String peerId) {
    debugPrint('openCamera: $peerId');
  }

  /// 打开端口转发
  static void openPortForward(BuildContext context, String peerId) {
    debugPrint('openPortForward: $peerId');
  }

  /// 显示设置页
  static void openSettings(BuildContext context) {
    debugPrint('openSettings');
  }
}
