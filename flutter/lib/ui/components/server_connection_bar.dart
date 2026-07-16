// flutter/lib/ui/components/server_connection_bar.dart
// 主界面右下角:与 LUODA 服务器 (rev.dicad.cn) 的连接状态文字条。
// 由 AppState.serverStatus 驱动,显示三种状态:
//   connecting   -> "正在连接 LUODA 服务器 rev.dicad.cn..."
//   connected    -> "rev.dicad.cn 已连接"
//   disconnected -> "无法连接 LUODA 服务器(请检查网络)"

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../states/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 服务器主机名 (与 libs/hbb_common/src/config.rs 的 RENDEZVOUS_SERVERS[0] 对齐)
const String kLuodaRendezvousHost = 'rev.dicad.cn';

class ServerConnectionBar extends StatelessWidget {
 const ServerConnectionBar({Key? key}) : super(key: key);

 @override
 Widget build(BuildContext context) {
 return Obx(() {
 final status = appState.serverStatus;
 final color = _colorFor(status);
 final label = _labelFor(status);

 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: AppColors.background,
 borderRadius: const BorderRadius.only(
 topLeft: Radius.circular(8),
 topRight: Radius.circular(0),
 bottomLeft: Radius.circular(0),
 bottomRight: Radius.circular(0),
 ),
 border: Border(
 top: BorderSide(color: color.withValues(alpha: 0.25), width: 1),
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 // 小圆点 (绿/黄/红) 呼应文字状态
 Container(
 width: 8,
 height: 8,
 decoration: BoxDecoration(
 color: color,
 shape: BoxShape.circle,
 ),
 ),
 const SizedBox(width: 6),
 Flexible(
 child: Text(
 label,
 style: AppTextStyles.caption.copyWith(color: color),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 );
 });
 }

 Color _colorFor(ServerConnectionStatus s) {
 switch (s) {
 case ServerConnectionStatus.connecting:
 return AppColors.textSecondary;
 case ServerConnectionStatus.connected:
 return AppColors.online;
 case ServerConnectionStatus.disconnected:
 return AppColors.error;
 }
 }

 String _labelFor(ServerConnectionStatus s) {
 switch (s) {
 case ServerConnectionStatus.connecting:
 return '正在连接 LUODA 服务器 $kLuodaRendezvousHost...';
 case ServerConnectionStatus.connected:
 return '$kLuodaRendezvousHost 已连接';
 case ServerConnectionStatus.disconnected:
 return '无法连接 LUODA 服务器(请检查网络)';
 }
 }
}
