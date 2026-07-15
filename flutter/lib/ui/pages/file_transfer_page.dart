// flutter/lib/ui/pages/file_transfer_page.dart
// 文件传输页面（双栏风格：本地/远程 + 传输队列）

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../components/avatar.dart';
import '../components/search_bar.dart';
import '../theme/app_theme.dart';

class FileTransferPage extends StatefulWidget {
  final String deviceId;
  const FileTransferPage({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  final RxList<TransferItem> _queue = <TransferItem>[].obs;
  String _localPath = '/home/user';
  String _remotePath = '/home/user';
  final _localCtrl = TextEditingController();
  final _remoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localCtrl.text = _localPath;
    _remoteCtrl.text = _remotePath;
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _remoteCtrl.dispose();
    super.dispose();
  }

  void _pickAndSend() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final f in result.files) {
        _queue.add(TransferItem(
          name: f.name,
          size: f.size,
          status: TransferStatus.pending,
          direction: TransferDirection.upload,
        ));
      }
      _processQueue();
    }
  }

  void _processQueue() {
    // 模拟传输进度
    for (var item in _queue.where((i) => i.status == TransferStatus.pending)) {
      item.status = TransferStatus.transferring;
      _queue.refresh();
      _simulateProgress(item);
    }
  }

  Future<void> _simulateProgress(TransferItem item) async {
    for (int p = 0; p <= 100; p += 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      item.progress = p / 100;
      _queue.refresh();
    }
    item.status = TransferStatus.done;
    _queue.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('文件传输 - ${widget.deviceId}'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickAndSend,
            tooltip: '发送文件',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRemote,
            tooltip: '刷新远程列表',
          ),
        ],
      ),
      body: Column(
        children: [
          // 路径栏
          _buildPathBar(),
          // 双栏文件列表
          Expanded(
            child: Row(
              children: [
                _buildFilePanel('本地', _localPath, true),
                const VerticalDivider(width: 1, color: AppColors.divider),
                _buildFilePanel('远程', _remotePath, false),
              ],
            ),
          ),
          // 传输队列
          _buildTransferQueue(),
        ],
      ),
    );
  }

  Widget _buildPathBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.cardBg,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _localCtrl,
              decoration: const InputDecoration(
                labelText: '本地路径',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => setState(() => _localPath = v),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.primaryGreen),
            onPressed: () {
              final t = _localCtrl.text;
              _localCtrl.text = _remoteCtrl.text;
              _remoteCtrl.text = t;
              setState(() {
                final tmp = _localPath;
                _localPath = _remotePath;
                _remotePath = tmp;
              });
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _remoteCtrl,
              decoration: const InputDecoration(
                labelText: '远程路径',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => setState(() => _remotePath = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePanel(String title, String path, bool isLocal) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: AppTextStyles.headline3),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _buildFileList(isLocal),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(bool isLocal) {
    // 示例数据
    final files = [
      FileItem(name: 'Documents', isDir: true, size: 0),
      FileItem(name: 'Pictures', isDir: true, size: 0),
      FileItem(name: 'Downloads', isDir: true, size: 0),
      FileItem(name: 'readme.txt', isDir: false, size: 1024),
      FileItem(name: 'photo.jpg', isDir: false, size: 2048576),
      FileItem(name: 'video.mp4', isDir: false, size: 104857600),
    ];

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (_, i) {
        final f = files[i];
        return ListTile(
          leading: Icon(
            f.isDir ? Icons.folder : Icons.insert_drive_file,
            color: f.isDir ? AppColors.primaryGreen : AppColors.textSecondary,
          ),
          title: Text(f.name, style: AppTextStyles.bodyText1),
          trailing: f.isDir
              ? null
              : Text(_formatSize(f.size), style: AppTextStyles.caption),
          onTap: () {
            if (f.isDir) {
              // 进入目录
            } else if (isLocal) {
              // 下载远程文件
            } else {
              // 上传本地文件
            }
          },
          onLongPress: () {
            if (!isLocal) {
              _queue.add(TransferItem(
                name: f.name,
                size: f.size,
                status: TransferStatus.pending,
                direction: TransferDirection.download,
              ));
              _processQueue();
            }
          },
        );
      },
    );
  }

  Widget _buildTransferQueue() {
    return Obx(() {
      if (_queue.isEmpty) return const SizedBox.shrink();
      return Container(
        height: 160,
        color: AppColors.cardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text('传输队列', style: AppTextStyles.headline3),
                  const Spacer(),
                  Text('${_queue.length} 项', style: AppTextStyles.caption),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                itemCount: _queue.length,
                itemBuilder: (_, i) {
                  final item = _queue[i];
                  return _buildQueueItem(item);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQueueItem(TransferItem item) {
    final isUpload = item.direction == TransferDirection.upload;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isUpload ? AppColors.primaryGreenLight : AppColors.primaryGreen.withOpacity(0.1),
            child: Icon(isUpload ? Icons.upload : Icons.download, size: 16, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.bodyText2, overflow: TextOverflow.ellipsis),
                LinearProgressIndicator(
                  value: item.status == TransferStatus.transferring ? item.progress : (item.status == TransferStatus.done ? 1 : 0),
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(item.status == TransferStatus.error ? AppColors.error : AppColors.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.status == TransferStatus.transferring
                ? '${(item.progress * 100).toInt()}%'
                : item.status.name,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          if (item.status == TransferStatus.transferring) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel, size: 18),
              onPressed: () {
                item.status = TransferStatus.cancelled;
                _queue.refresh();
              },
            ),
          ],
        ],
      ),
    );
  }

  void _refreshRemote() {
    // TODO: 请求远程目录列表
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已刷新远程列表')),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

enum TransferStatus { pending, transferring, done, error, cancelled }
enum TransferDirection { upload, download }

class TransferItem {
  final String name;
  final int size;
  Rx<TransferStatus> status;
  RxDouble progress = 0.0.obs;
  final TransferDirection direction;

  TransferItem({
    required this.name,
    required this.size,
    required this.status,
    required this.direction,
  });
}

class FileItem {
  final String name;
  final bool isDir;
  final int size;

  FileItem({required this.name, required this.isDir, required this.size});
}