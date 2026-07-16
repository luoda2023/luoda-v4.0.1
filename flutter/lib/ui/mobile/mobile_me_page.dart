// flutter/lib/ui/mobile/mobile_me_page.dart
// 手机端「我」页（微信「我」风格）。
//
// 顶部绿色个人卡（设备名 + LUODA ID），下方功能入口复用 PC 端同一份
// SettingsPage（ui/pages/settings_page.dart），通过 AppState 共享深色模式
// 等设置状态。点「设置」整页跳转，SettingsPage 自带 AppBar，体验与 PC 端一致。
//
// 文字尺寸遵循移动端人机规范（MobileTextStyles）：个人名 17 / ID 13 /
// 列表项 16，触摸目标 >= 48dp。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../pages/settings_page.dart';
import '../states/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MobileMePage extends StatelessWidget {
  const MobileMePage({Key? key}) : super(key: key);

  AppState get _appState => Get.find<AppState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildProfileCard()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildSettingsGroup(context)),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildAboutGroup(context)),
            const SliverToBoxAdapter(
                child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// 微信「我」绿色个人卡：头像 + 设备名 + LUODA ID（可复制）。
  Widget _buildProfileCard() {
    return Obx(() {
      final id = gFFI.serverModel.serverId.value.text.trim();
      final displayId = id.isEmpty ? '未连接服务器' : id;
      final name = id.isEmpty ? '我的设备' : 'LUODA 设备';
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGreen, Color(0xFF1F9E5A)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('L',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text('LUODA ID: $displayId',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (id.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: id));
                            Get.snackbar('已复制', 'LUODA ID 已复制到剪贴板',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 1));
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.copy,
                                size: 16, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSettingsGroup(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Obx(() => _Row(
                icon: Icons.dark_mode,
                title: '深色模式',
                trailing: Switch(
                  value: _appState.isDarkMode.value,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) => _appState.setDarkMode(v),
                ),
              )),
          const _Divider(),
          _Row(
            icon: Icons.settings,
            title: '设置',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutGroup(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const _Row(icon: Icons.info_outline, title: '版本', trailingText: 'LUODA v4.0.1'),
          const _Divider(),
          _Row(
            icon: Icons.privacy_tip,
            title: '隐私政策',
            onTap: () {},
          ),
          const _Divider(),
          _Row(
            icon: Icons.description,
            title: '用户协议',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// 通用列表行（微信风格）。
class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? trailingText;

  const _Row({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    Widget? right = trailing;
    final String? tt = trailingText;
    if (right == null && tt != null) {
      right = Text(tt, style: MobileTextStyles.conversationPreview);
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryGreen),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: MobileTextStyles.listItem),
            ),
            if (right != null) ...[
              right,
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: AppColors.divider,
    );
  }
}
