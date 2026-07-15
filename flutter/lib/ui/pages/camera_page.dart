// flutter/lib/ui/pages/camera_page.dart
// 摄像头视图页面（微信风格）

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';

class CameraPage extends StatefulWidget {
  final String deviceId;

  const CameraPage({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  double _zoomLevel = 1.0;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      _initializeControllerFuture = _controller.initialize();
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('摄像头初始化失败: $e')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isInitialized) {
        _initCamera();
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      
      final image = await _controller.takePicture();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('照片已保存: ${image.path}'),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍摄失败: $e')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (!_controller.value.isRecordingVideo) {
      try {
        await _controller.startVideoRecording();
        setState(() => _isRecording = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始录制')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录制失败: $e')),
        );
      }
    } else {
      try {
        final video = await _controller.stopVideoRecording();
        setState(() => _isRecording = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('视频已保存: ${video.path}'),
            action: SnackBarAction(
              label: '播放',
              onPressed: () {},
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录制失败: $e')),
        );
      }
    }
  }

  void _toggleFlash() {
    setState(() => _flashEnabled = !_flashEnabled);
    // TODO: 实现闪光灯控制
  }

  void _zoomIn() {
    setState(() => _zoomLevel = (_zoomLevel * 1.2).clamp(1.0, 10.0));
    // TODO: 设置摄像头缩放
  }

  void _zoomOut() {
    setState(() => _zoomLevel = (_zoomLevel / 1.2).clamp(1.0, 10.0));
    // TODO: 设置摄像头缩放
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('摄像头 - ${widget.deviceId}'),
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Stack(
                      children: [
                        CameraPreview(_controller),
                        _buildZoomControls(),
                      ],
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    );
                  }
                },
              ),
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _zoomIn,
          ),
          Text('${_zoomLevel.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: _zoomOut,
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library, size: 32),
            onPressed: _browseGallery,
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 2),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: _isRecording ? Colors.red : AppColors.primaryGreen,
              child: IconButton(
                icon: Icon(_isRecording ? Icons.videocam : Icons.camera_alt, size: 32, color: Colors.white),
                onPressed: _isRecording ? _toggleRecording : _takePicture,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(_isRecording ? Icons.videocam_off : Icons.videocam, size: 32),
            onPressed: _toggleRecording,
            color: _isRecording ? Colors.red : AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  void _switchCamera() {
    // TODO: 切换前置/后置摄像头
  }

  void _browseGallery() {
    // TODO: 浏览相册
  }
}