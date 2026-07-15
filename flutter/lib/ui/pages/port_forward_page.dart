// flutter/lib/ui/pages/port_forward_page.dart
// 简单端口转发页面

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PortForwardPage extends StatefulWidget {
  const PortForwardPage({Key? key}) : super(key: key);

  @override
  State<PortForwardPage> createState() => _PortForwardPageState();
}

class _PortForwardPageState extends State<PortForwardPage> {
  // 端口列表
  final List<Map<String, String>> _portRules = [
    {'local_port': '8080', 'remote_port': '80', 'status': 'active'},
    {'local_port': '22', 'remote_port': '2222', 'status': 'inactive'},
    // ...更多规则
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('端口转发设置'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: ListView.builder(
        itemCount: _portRules.length,
        itemBuilder: (context, index) {
          final rule = _portRules[index];
          return ListTile(
            title: Text('${rule['local_port']} → ${rule['remote_port']}'),
            trailing: Switch(
              value: rule['status'] == 'active',
              onChanged: (val) {
                // TODO: 更新状态并通知核心服务
              },
            ),
            subtitle: Text(rule['status']),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          // 添加新端口转发规则
        },
      ),
    );
  }
}

class PortForwardRule {
  int localPort;
  String remoteHost;
  int remotePort;
  String protocol;
  String status; // "active" / "inactive"
  // other fields...
}