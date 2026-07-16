// flutter/lib/ui/pages/settings_page.dart
// 设置页面（微信风格）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../states/app_state.dart';

class SettingsPage extends StatefulWidget {
 const SettingsPage({Key? key}) : super(key: key);

 @override
 State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
 final AppState _appState = Get.find<AppState>();
 String _language = 'zh_CN';
 bool _autoStart = true;
 bool _notifications = true;
 String _quality = 'high';

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(
 title: const Text('设置'),
 backgroundColor: AppColors.primaryGreen,
 ),
 body: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 // 外观
 _sectionTitle('外观'),
 Card(
 child: Column(children: [
 ListTile(
 leading: const Icon(Icons.dark_mode, color: AppColors.primaryGreen),
 title: const Text('深色模式'),
 trailing: Obx(() => Switch(
 value: _appState.isDarkMode.value,
 onChanged: (v) => _appState.setDarkMode(v),
 )),
 ),
 ListTile(
 leading: const Icon(Icons.language, color: AppColors.primaryGreen),
 title: const Text('语言'),
 subtitle: Text(_language == 'zh_CN' ? '简体中文' : 'English'),
 trailing: const Icon(Icons.chevron_right),
 onTap: () => _pickLanguage(),
 ),
 ]),
 ),

 const SizedBox(height: 16),
 // 常规
 _sectionTitle('常规'),
 Card(
 child: Column(children: [
 ListTile(
 leading: const Icon(Icons.auto_fix_high, color: AppColors.primaryGreen),
 title: const Text('开机自启'),
 trailing: Switch(value: _autoStart, onChanged: (v) => setState(() => _autoStart = v)),
 ),
 ListTile(
 leading: const Icon(Icons.notifications, color: AppColors.primaryGreen),
 title: const Text('桌面通知'),
 trailing: Switch(value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
 ),
 ]),
 ),

 const SizedBox(height: 16),
 // 远程桌面质量
 _sectionTitle('远程桌面'),
 Card(
 child: Column(children: [
 ListTile(
 leading: const Icon(Icons.hd, color: AppColors.primaryGreen),
 title: const Text('默认画质'),
 trailing: DropdownButton<String>(
 value: _quality,
 underline: const SizedBox(),
 items: const [
 DropdownMenuItem(value: 'high', child: Text('高清')),
 DropdownMenuItem(value: 'medium', child: Text('标清')),
 DropdownMenuItem(value: 'low', child: Text('流畅')),
 ],
 onChanged: (v) => setState(() => _quality = v!),
 ),
 ),
 ]),
 ),

 const SizedBox(height: 16),
 // 关于
 _sectionTitle('关于'),
 Card(
 child: Column(children: [
 ListTile(
 leading: const Icon(Icons.info, color: AppColors.primaryGreen),
 title: const Text('版本'),
 subtitle: const Text('LUODA v2.2.1'),
 ),
 ListTile(
 leading: const Icon(Icons.privacy_tip, color: AppColors.primaryGreen),
 title: const Text('隐私政策'),
 onTap: () {},
 ),
 ListTile(
 leading: const Icon(Icons.description, color: AppColors.primaryGreen),
 title: const Text('用户协议'),
 onTap: () {},
 ),
 ]),
 ),
 ],
 ),
 );
 }

 Widget _sectionTitle(String t) => Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Text(t, style: AppTextStyles.headline3.copyWith(color: AppColors.textSecondary)),
 );

 void _pickLanguage() {
 showModalBottomSheet(
 context: context,
 builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
 ListTile(title: const Text('简体中文'), onTap: () { setState(() => _language = 'zh_CN'); Navigator.pop(context); }),
 ListTile(title: const Text('English'), onTap: () { setState(() => _language = 'en_US'); Navigator.pop(context); }),
 ]),
 );
 }
}
