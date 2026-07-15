// flutter/lib/main.dart
// Main entry point for LUODA v2.2.1 with new WeChat-style UI

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ui/layout/main_layout.dart';
import '../ui/states/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure bindings are initialized before running any logic
  WidgetsFlutterBinding.instance.initializeEngine();
  Get.put(AppState());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LUODA Remote',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppState().isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          final state = Get.find<AppState>();
          // Use MainLayout for all navigation
          return MainLayout(key: UniqueKey());
        },
      ),
    );
  }
}