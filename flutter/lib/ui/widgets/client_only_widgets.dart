// flutter/lib/ui/widgets/client_only_widgets.dart
// 独立客户端 EXE 专属 UI：
//   1) ClientTitleBar  —— 自定义标题栏(应用名 "LDesk" + 最小化/最大化/关闭),整条可拖动窗口
//   2) ClientDeviceInfoPage —— 本机信息卡,展示本机 ID / 临时密码 / 直连 IP,供对方连接本机
//
// 视觉对齐 UI-REDESIGN/luoda-wechat-ui.html(微信风格:深色导航条 + 白卡片 + 微信绿强调色)。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:luoda_flutter/consts.dart';
import 'package:luoda_flutter/models/platform_model.dart';

import '../../common.dart';
import '../theme/app_colors.dart';

/// 自定义标题栏：应用名 "LDesk" + 最小化/最大化/关闭,整条可拖动窗口。
class ClientTitleBar extends StatefulWidget {
  const ClientTitleBar({Key? key}) : super(key: key);
  @override
  State<ClientTitleBar> createState() => _ClientTitleBarState();
}

class _ClientTitleBarState extends State<ClientTitleBar> {
  bool _max = false;

  @override
  void initState() {
    super.initState();
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _max = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.navigationBarBg,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              child: const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text('LDesk',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          _TitleBtn(icon: Icons.remove, onTap: () => windowManager.minimize()),
          _TitleBtn(
            icon: _max ? Icons.filter_none : Icons.crop_square,
            onTap: () async {
              if (_max) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
              final m = await windowManager.isMaximized();
              if (mounted) setState(() => _max = m);
            },
          ),
          _TitleBtn(
              icon: Icons.close,
              hoverRed: true,
              onTap: () => windowManager.close()),
        ],
      ),
    );
  }
}

class _TitleBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hoverRed;
  const _TitleBtn(
      {required this.icon, required this.onTap, this.hoverRed = false});
  @override
  State<_TitleBtn> createState() => _TitleBtnState();
}

class _TitleBtnState extends State<_TitleBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 44,
          height: 44,
          color: _hover && widget.hoverRed
              ? const Color(0xFFE0383F)
              : (_hover ? const Color(0x22FFFFFF) : Colors.transparent),
          child: Icon(widget.icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

/// 本机信息卡:展示本机 ID / 临时密码 / 直连 IP,供对方连接本机。
///
/// 重要:serverModel 的 ID/密码/直连 IP 在 startService() 之后才由异步回调解出
/// (main.dart 中 startService 未 await,首次渲染时可能仍是占位符/"暂不可用")。
/// 因此本页必须监听 serverModel 的变更并重建,否则卡片会停留在占位值、永不刷新。
class ClientDeviceInfoPage extends StatefulWidget {
  const ClientDeviceInfoPage({Key? key}) : super(key: key);
  @override
  State<ClientDeviceInfoPage> createState() => _ClientDeviceInfoPageState();
}

class _ClientDeviceInfoPageState extends State<ClientDeviceInfoPage> {
  @override
  void initState() {
    super.initState();
    // serverModel 是 ChangeNotifier,ID/密码到达时会 notifyListeners → 触发重建
    gFFI.serverModel.addListener(_onModelChanged);
    // 公网/内网直连 IP 由网络发现稍后填好,首帧可能尚空,延迟一拍再读一次
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() {});
    });
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    gFFI.serverModel.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    final publicIP = bind.mainGetOptionSync(key: 'public-ip');
    final lanIP = bind.mainGetOptionSync(key: 'lan-ip');
    final directPort = bind.mainGetOptionSync(key: kOptionDirectAccessPort);
    String publicAddr = publicIP;
    String lanAddr = lanIP;
    if (directPort.isNotEmpty) {
      if (publicIP.isNotEmpty) publicAddr = '$publicIP:$directPort';
      if (lanIP.isNotEmpty) lanAddr = '$lanIP:$directPort';
    }

    return Container(
      color: AppColors.contentAreaBg,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本机信息',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('将以下信息发给对方,对方即可连接本机',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(
                      label: '本机 ID',
                      value: model.serverId.text,
                      copy: model.serverId.text),
                  const Divider(height: 20, color: AppColors.divider),
                  _InfoRow(
                      label: '临时密码',
                      value: model.serverPasswd.text,
                      copy: model.serverPasswd.text,
                      monospace: true),
                  const Divider(height: 20, color: AppColors.divider),
                  _InfoRow(
                      label: '公网直连',
                      value:
                          publicAddr.isNotEmpty ? publicAddr : '暂不可用',
                      copy: publicAddr),
                  if (lanAddr.isNotEmpty) ...[
                    const Divider(height: 20, color: AppColors.divider),
                    _InfoRow(
                        label: '内网直连', value: lanAddr, copy: lanAddr),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String copy;
  final bool monospace;
  const _InfoRow(
      {required this.label,
      required this.value,
      required this.copy,
      this.monospace = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 30,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0x73191919))),
              const SizedBox(height: 4),
              SelectableText(value,
                  style: TextStyle(
                      fontSize: monospace ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: monospace ? 'monospace' : null,
                      letterSpacing: monospace ? 1.0 : 0,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: copy));
            showToast(translate('Copied'));
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.copy,
                size: 18, color: AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }
}
