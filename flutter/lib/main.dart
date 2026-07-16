// flutter/lib/main.dart
// Main entry point for LUODA v4.0.1 with new WeChat-style UI

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/layout/main_layout.dart';
import '../ui/states/app_state.dart';
import '../ui/states/conversation_state.dart';
import '../ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局状态：先放 AppState，再放依赖它的 ConversationState
  Get.put(AppState());
  Get.put(ConversationState());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Get.find<AppState>();
    return Obx(
      () => GetMaterialApp(
        title: 'LUODA Remote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode:
            appState.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        home: MainLayout(key: UniqueKey()),
      ),
    );
  }
}
