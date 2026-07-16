import 'package:flutter/material.dart';
import 'package:luoda_flutter/common.dart';
import 'package:luoda_flutter/consts.dart';
import 'package:luoda_flutter/models/platform_model.dart';
import 'package:luoda_flutter/ui/theme/app_colors.dart';

/// 一次性授权状态：
///  - 'none'     : 从未处理过（首次启动）
///  - 'done'     : 用户已完成授权引导
///  - 'skipped'  : 用户选择稍后，不再自动弹出
const String kMobilePermSetupDone = "mobile_perm_setup_done";
const String kMobilePermSetupSkipped = "mobile_perm_setup_skipped";

Future<String> getPermissionSetupState() async {
  if (bind.mainGetLocalOption(key: kMobilePermSetupDone) == 'Y') return 'done';
  if (bind.mainGetLocalOption(key: kMobilePermSetupSkipped) == 'Y') {
    return 'skipped';
  }
  return 'none';
}

Future<void> markPermissionSetupDone() async {
  await bind.mainSetLocalOption(key: kMobilePermSetupDone, value: 'Y');
  await bind.mainSetLocalOption(key: kMobilePermSetupSkipped, value: 'N');
}

Future<void> markPermissionSetupSkipped() async {
  await bind.mainSetLocalOption(key: kMobilePermSetupSkipped, value: 'Y');
}

class _PermRow {
  final String id;
  final String title;
  final String desc;
  final bool granted;
  final Future<void> Function() grant;

  _PermRow(this.id, this.title, this.desc, this.granted, this.grant);
}

/// 授权中心：一次性引导用户完成全部所需权限，避免在使用过程中反复弹窗。
class PermissionSetupSheet extends StatefulWidget {
  const PermissionSetupSheet({Key? key}) : super(key: key);

  @override
  State<PermissionSetupSheet> createState() => _PermissionSetupSheetState();
}

class _PermissionSetupSheetState extends State<PermissionSetupSheet> {
  bool _busy = false;
  final Map<String, bool> _status = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final sm = gFFI.serverModel;
    await sm.checkAndroidPermission();
    _status['screen'] = sm.mediaOk;
    _status['input'] = sm.inputOk;
    _status['file'] = sm.fileOk;
    _status['audio'] = sm.audioOk;
    _status['clipboard'] = sm.clipboardOk;
    _status['notification'] =
        await AndroidPermissionManager.check(kAndroid13Notification);
    _status['overlay'] = await AndroidPermissionManager.check(kSystemAlertWindow);
    _status['battery'] =
        await AndroidPermissionManager.check(kRequestIgnoreBatteryOptimizations);
    if (mounted) setState(() {});
  }

  Future<void> _grantScreen() async {
    if (!gFFI.serverModel.mediaOk) {
      await gFFI.serverModel.toggleService();
      await _refresh();
    }
  }

  Future<void> _grantInput() async {
    if (!gFFI.serverModel.inputOk) {
      await gFFI.serverModel.toggleInput();
      await _refresh();
    }
  }

  Future<void> _grantClipboard() async {
    if (!gFFI.serverModel.clipboardOk) {
      gFFI.serverModel.toggleClipboard();
      await _refresh();
    }
  }

  /// 顺序请求可批量授权的特殊权限（每个弹出各自的系统页面，已授权则跳过）。
  Future<void> _grantAll() async {
    setState(() => _busy = true);
    try {
      final batch = [
        kManageExternalStorage,
        kRecordAudio,
        kAndroid13Notification,
        kSystemAlertWindow,
        kRequestIgnoreBatteryOptimizations,
      ];
      for (final t in batch) {
        if (!await AndroidPermissionManager.check(t)) {
          await AndroidPermissionManager.request(t);
        }
      }
      if (!gFFI.serverModel.clipboardOk) gFFI.serverModel.toggleClipboard();
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<_PermRow> _rows() {
    return [
      _PermRow('screen', '屏幕捕捉', '远程控制对方时显示 / 捕捉你的屏幕',
          _status['screen'] ?? false, _grantScreen),
      _PermRow('input', '输入控制', '允许对方操控你的设备（辅助功能）',
          _status['input'] ?? false, _grantInput),
      _PermRow(
          'file',
          '文件传输',
          '在设备之间互传文件',
          _status['file'] ?? false,
          () => AndroidPermissionManager.request(kManageExternalStorage)),
      _PermRow('audio', '音频采集', '远程通话时采集你的麦克风声音',
          _status['audio'] ?? false, () => AndroidPermissionManager.request(kRecordAudio)),
      _PermRow('clipboard', '剪贴板同步', '远程同步剪贴板内容',
          _status['clipboard'] ?? false, _grantClipboard),
      _PermRow(
          'notification',
          '通知权限',
          '在通知栏常驻服务、接收连接提醒',
          _status['notification'] ?? false,
          () => AndroidPermissionManager.request(kAndroid13Notification)),
      _PermRow(
          'overlay',
          '悬浮窗',
          '显示悬浮窗以便快速操作',
          _status['overlay'] ?? false,
          () => AndroidPermissionManager.request(kSystemAlertWindow)),
      _PermRow(
          'battery',
          '电池优化白名单',
          '后台保活，避免服务被系统杀掉',
          _status['battery'] ?? false,
          () => AndroidPermissionManager.request(kRequestIgnoreBatteryOptimizations)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
              child: Text('一次性授权，后续不再打扰',
                  style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
        ]),
        Text('为获得完整远程协助能力，建议首次使用时完成以下授权。'
            '已授权的项目不会重复弹窗。',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ...rows.map((r) => _buildRow(r)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _busy ? null : _grantAll,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('一键授权'),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
              onPressed: () async {
                await markPermissionSetupSkipped();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('稍后')),
        ]),
      ]),
    );
  }

  Widget _buildRow(_PermRow r) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
          r.granted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: r.granted ? Colors.green : Colors.grey),
      title: Text(r.title),
      subtitle:
          Text(r.desc, style: Theme.of(context).textTheme.bodySmall),
      trailing: r.granted
          ? null
          : TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await r.grant();
                        await _refresh();
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: const Text('授权')),
    );
  }
}

void showPermissionSetup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PermissionSetupSheet(),
  );
}

/// 常驻的非阻塞横幅：未完全授权时提示用户进入授权中心（不强制、不重复弹窗）。
class PermissionSetupBanner extends StatelessWidget {
  const PermissionSetupBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getPermissionSetupState(),
      builder: (context, snap) {
        if (snap.data == 'done') return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            const Icon(Icons.verified_user,
                color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text('完成一次性授权，即可获得完整远程协助能力',
                    style: TextStyle(
                        color: AppColors.primaryGreen, fontSize: 13))),
            TextButton(
                onPressed: () => showPermissionSetup(context),
                child: const Text('去授权')),
          ]),
        );
      },
    );
  }
}
