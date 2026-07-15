// flutter/lib/ui/layout/main_layout.dart
// 微信风格三栏主布局

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../states/app_state.dart';
import '../theme/app_theme.dart';
import '../components/sidebar_item.dart';
import '../components/sidebar_item_def.dart'; // 假设我们创建了枚举

import '../models/device.dart'; // 假设设备模型已定义

class MainLayout extends StatelessWidget {
  final List<Widget> pages = [
    // 每个 tab 的页面
    const SizedBox(
      child: Center(child: Text('会话列表')),
    ),
    const SizedBox(
      child: Center(child: Text('设备列表')),
    ),
    const SizedBox(
      child: Center(child: Text('文件传输')),
    ),
    const SizedBox(
      child: Center(child: Text('设置')),
    ),
  ];

  final NavSection currentSection = AppState().nav.value;

  MainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = AdaptiveTheme.of(context).maybeTheme; // Android-style frame
    final controller = Get.find<AppState>();

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          // 三栏布局：60px 左栏 + 可伸缩中栏 + 剩余主内容
          // 投屏宽度优先处理
          final minWidth = MediaQuery.of(context).size.width;

          // 导航栏宽度：固定 60px
          const sideBarWidth = 60.0;

          // 中栏宽度：根据内容而定（折叠时为 0）
          final middleWidth = min(400, max(sideBarWidth, minWidth - sideBarWidth - 24));

          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // 主容器
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧导航栏（固定宽度）
                      SizedBox(
                        width: sideBarWidth,
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            size: Size(sideBarWidth, MediaQuery.of(context).size.height),
                          ),
                          builder: (context, __) => _buildSidebar(context),
                        ),
                      ),
                      // 中间 + 右侧主内容
                      Expanded(
                        child: _buildMainArea(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 侧边栏构建
  Widget _buildSidebar(BuildContext context) {
    final controller = AppState().to as AppState; // 获取全局状态

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头像+名称
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LUODA',
                  style: AppTextStyles.headline3.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              DeviceCard(name: '本地机器', icon: Icons.desktop_windows, count: 1),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  runAlignment: WrapAlignment.center,
                  children: [
                    NavigationTabItem(
                      selected: controller.nav.value == NavSection.contacts,
                      icon: Icons.contacts,
                      label: '通讯录',
                      onTap: () => controller.switchNav(NavSection.contacts),
                    ),
                    NavigationTabItem(
                      selected: controller.nav.value == NavSection.chats,
                      icon: Icons.chat_bubble,
                      label: '会话',
                      onTap: () => controller.switchNav(NavSection.chats),
                    ),
                    NavigationTabItem(
                      selected: controller.nav.value == NavSection.files,
                      icon: Icons.folder,
                      label: '文件',
                      onTap: () => controller.switchNav(NavSection.files),
                    ),
                    NavigationTabItem(
                      selected: controller.nav.value == NavSection.settings,
                      icon: Icons.settings,
                      label: '设置',
                      onTap: () => controller.switchNav(NavSection.settings),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        '在线: ${controller.totalUnread.value}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 辅助：导航栏顶部项目
class NavigationTabItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const NavigationTabItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.activeItemBackground : Colors.transparent;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? AppColors.primaryGreen : AppColors.textTertiary),
              SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: selected ? AppColors.primaryGreen : AppColors.textTertiary,
                fontSize: 12,
              )),
            ],
          ),
        ),
      ),
    );
  }
}