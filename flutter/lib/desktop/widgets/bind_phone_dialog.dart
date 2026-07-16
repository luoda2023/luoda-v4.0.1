// flutter/lib/desktop/widgets/bind_phone_dialog.dart
// PC 端「绑定手机」弹窗：展示二维码，手机扫码即与这台 PC 建立直连绑定。
//
// 二维码内容：ldesk://bind?id=<PC的ID>&name=<PC名称>
// 手机端 ScanPage 识别该 scheme 后写入 BindingState（持久化 + 每 30 分钟
// 局域网自动同步），全程不经过任何中继/账号服务器。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../common.dart';
import '../../models/platform_model.dart';
import '../../ui/theme/app_colors.dart';

/// 弹出「绑定手机」对话框（PC 端）。
Future<void> showBindPhoneDialog(BuildContext context) async {
  // PC 自身的 ID（绑定身份）。
  final id = await bind.mainGetMyId();
  // 友好名称：优先别名，其次主机名，最后回退到 ID。
  String name = id;
  try {
    final alias = await bind.mainGetPeerOption(id: id, key: 'alias');
    final hostname = await bind.mainGetPeerOption(id: id, key: 'hostname');
    if (alias.isNotEmpty) {
      name = alias;
    } else if (hostname.isNotEmpty) {
      name = hostname;
    }
  } catch (_) {
    // 取不到名称就用 ID。
  }

  final uri =
      'ldesk://bind?id=${Uri.encodeComponent(id)}&name=${Uri.encodeComponent(name)}';

  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('绑定手机', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '用手机端 LDesk 扫一扫，绑定后手机将每 30 分钟自动同步该电脑状态（局域网直连，不经服务器）。',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SelectableText(
              '本机 ID：$id',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
