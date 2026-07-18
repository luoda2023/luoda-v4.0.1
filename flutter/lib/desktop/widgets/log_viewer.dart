// 运行日志查看页：读取 RuntimeLogger 落盘的日志，支持复制与打开日志文件夹。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../runtime_logger.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({Key? key}) : super(key: key);

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = RuntimeLogger.instance.readLog();
  }

  Future<void> _refresh() async {
    setState(() => _future = RuntimeLogger.instance.readLog());
  }

  Future<void> _copy() async {
    final log = await _future;
    await Clipboard.setData(ClipboardData(text: log));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已复制全部日志到剪贴板')));
    }
  }

  Future<void> _openFolder() async {
    final p = RuntimeLogger.instance.logFilePath;
    if (p == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('日志尚未初始化')));
      }
      return;
    }
    final dir = File(p).parent.path;
    if (await Directory(dir).exists()) {
      await launchUrl(Uri.file(dir));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: _refresh),
          IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: '打开日志文件夹',
              onPressed: _openFolder),
          IconButton(
              icon: const Icon(Icons.copy),
              tooltip: '复制全部',
              onPressed: _copy),
        ],
      ),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final text = snap.data ?? '(空)';
          return SelectableText(
            text,
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 12, height: 1.4),
          );
        },
      ),
    );
  }
}
