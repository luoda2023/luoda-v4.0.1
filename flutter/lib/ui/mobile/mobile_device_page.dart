// flutter/lib/ui/mobile/mobile_device_page.dart
// 手机端「设备」页（微信通讯录风格）。
//
// 与 PC 端 MainLayout / 通讯录共用同一份 ConversationState 数据源：
// 设备列表、在线状态(绿点)、平台图标完全一致。点按设备可发起远程控制
// (connect, 与 PC 端同一入口)，或从设备发起会话(跳到 消息 tab 聊天)。
//
// 文字尺寸遵循移动端人机规范（MobileTextStyles）：标题 17 / 名称 16 /
// 副信息 13，触摸目标 >= 48dp。

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../models/binding_model.dart';
import '../../mobile/pages/scan_page.dart';
import '../components/device_card.dart';
import '../states/app_state.dart';
import '../states/conversation_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 平台字符串 -> DeviceKind（与 PC 端 DeviceCard 一致）。
DeviceKind _kindOf(String platform) {
  switch (platform.toLowerCase()) {
    case 'windows':
      return DeviceKind.windows;
    case 'macos':
    case 'osx':
      return DeviceKind.macos;
    case 'linux':
      return DeviceKind.linux;
    case 'android':
      return DeviceKind.android;
    case 'ios':
      return DeviceKind.ios;
    case 'server':
      return DeviceKind.server;
    default:
      return DeviceKind.unknown;
  }
}

class MobileDevicePage extends StatefulWidget {
  /// 从设备发起会话：由 MobileMainLayout 处理（选中会话并切到 消息 tab）。
  final void Function(String conversationId) onStartChat;

  const MobileDevicePage({Key? key, required this.onStartChat})
      : super(key: key);

  @override
  State<MobileDevicePage> createState() => _MobileDevicePageState();
}

class _MobileDevicePageState extends State<MobileDevicePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addController = TextEditingController();

  ConversationState get _convState => Get.find<ConversationState>();
  AppState get _appState => Get.find<AppState>();

  @override
  void dispose() {
    _searchController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _addController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加设备', style: MobileTextStyles.listItem),
        content: TextField(
          controller: _addController,
          autofocus: true,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _addAndConnect(ctx),
          style: MobileTextStyles.input,
          decoration: InputDecoration(
            hintText: '输入对方 ID 或 IP:端口',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.textOnDark,
            ),
            onPressed: () => _addAndConnect(ctx),
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  void _addAndConnect(BuildContext ctx) {
    final id = _addController.text.trim();
    Navigator.pop(ctx);
    if (id.isEmpty) {
      Get.snackbar('提示', '请输入对方 ID 或 IP:端口',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    connect(context, id);
  }

  /// 长按已绑定设备 -> 确认解绑（不再每 30 分钟自动同步）。
  void _confirmUnbind(String id) {
    if (!Get.isRegistered<BindingState>() ||
        !Get.find<BindingState>().isBound(id)) {
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑设备', style: MobileTextStyles.listItem),
        content: const Text('确定不再自动同步该设备的状态吗？',
            style: MobileTextStyles.input),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.find<BindingState>().removeBinding(id);
              Navigator.pop(ctx);
              Get.snackbar('已解绑', '已取消自动同步',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('解绑'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(child: _buildDeviceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.background,
      child: Row(
        children: [
          const Text('设备', style: MobileTextStyles.navTitle),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner,
                size: 24, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ScanPage()),
            ),
            tooltip: '扫一扫绑定电脑',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                size: 24, color: AppColors.textPrimary),
            onPressed: _showAddDialog,
            tooltip: '添加设备',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      color: AppColors.background,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (v) => _appState.searchKeyword = v,
        style: MobileTextStyles.input,
        decoration: InputDecoration(
          hintText: '搜索设备',
          hintStyle: MobileTextStyles.inputHint,
          isDense: true,
          filled: true,
          fillColor: AppColors.cardBg,
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Obx(() {
      final keyword = _searchController.text.trim();
      final list = _convState.filtered(keyword: keyword);
      if (list.isEmpty) {
        return Center(
          child: Text('暂无设备', style: MobileTextStyles.sectionLabel),
        );
      }
          return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: list.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider, indent: 76),
        itemBuilder: (context, i) {
          final c = list[i];
          return _DeviceTile(
            conversation: c,
            onTap: () => widget.onStartChat(c.id),
            onConnect: c.peerId.isEmpty
                ? null
                : () => connect(context, c.peerId),
            onUnbind: () => _confirmUnbind(c.id),
          );
        },
      );
    });
  }
}

/// 设备列表项（微信通讯录风格：平台圆形图标 + 名称 16 + 状态 13 +
/// 在线绿点 + 右侧「远程」快捷按钮；整行高度 60，触摸友好）。
class _DeviceTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onUnbind;

  const _DeviceTile(
      {required this.conversation,
      required this.onTap,
      this.onConnect,
      this.onUnbind});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final kind = _kindOf(c.platform);
    final online = c.isOnline;
    return InkWell(
      onTap: onTap,
      onLongPress: onUnbind,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: AppColors.conversationListBg,
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kind.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(kind.icon, color: kind.color, size: 22),
                ),
                if (c.peerId.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: online ? AppColors.online : AppColors.offline,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.conversationListBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: MobileTextStyles.conversationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.peerId.isEmpty ? '示例设备' : (online ? '在线' : '离线'),
                          style: MobileTextStyles.conversationPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Obx(() {
                        final bound = Get.isRegistered<BindingState>() &&
                            Get.find<BindingState>().isBound(c.id);
                        return bound
                            ? Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('已绑定',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primaryGreen)),
                              )
                            : const SizedBox.shrink();
                      }),
                    ],
                  ),
                ],
              ),
            ),
            if (onConnect != null)
              IconButton(
                icon: const Icon(Icons.cast_connected,
                    size: 22, color: AppColors.primaryGreen),
                onPressed: onConnect,
                tooltip: '远程控制',
              ),
          ],
        ),
      ),
    );
  }
}
