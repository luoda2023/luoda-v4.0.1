flutter\AppBar(
  title: Text('远程桌面控制'),
  backgroundColor: AppColors.remoteToolbarBg,
  actions: [
    IconButton(
      icon: Icon(Icons.switch_embed),
      onPressed: () {
        // 切换显示模式（全屏/窗口模式）
        final state = ApplState();
        state.toggleFullscreen();
      },
    ),
    IconButton(
      icon: Icon(Icons.brightness_6),
      onPressed: () {
        // 主题切换
        // final state = AppState();
        // state.toggleTheme();
      },
    ),
    IconButton(
      icon: Icon(Icons.navigate_next, color: AppColors.textTertiary),
      onPressed: () {
        // 进入聊天
        Get.to(ChatPage(deviceId: widget.deviceId));
      },
    ),
  ],
  surface: false,
);

/// 构建主内容区
Widget _buildMainContent(String deviceId) {
  // 使用 GestureDetector 捕获手势
  return Expanded(
    child: GestureDetector(
      onTap: () {
        // 处理全局点击，可能需要更新状态
        // Example: toggle mute/unmute
      },
      child: Container(
        color: AppColors.background,
        child: _RemoteDesktopView(deviceId: deviceId),
      ),
    ),
  );
}