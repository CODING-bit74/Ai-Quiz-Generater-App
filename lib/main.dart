import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/welcome_screen.dart';
import 'controllers/theme_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/quiz_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: BindingsBuilder(() {
        Get.put(ThemeController());
        Get.put(HistoryController());
        Get.put(
          QuizController(),
        ); // Also making QuizController global for easy access
      }),
      title: 'AI Quiz Generator',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          surface: Color(0xFF1E293B),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          surface: Colors.white,
          onSurface: Color(0xFF0F172A), // Slate 900
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
