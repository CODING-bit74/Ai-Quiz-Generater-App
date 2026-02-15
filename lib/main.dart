import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/welcome_screen.dart';
import 'controllers/theme_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/economy_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kymemcfwjgliytgdzwrc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5bWVtY2Z3amdsaXl0Z2R6d3JjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTk0NDksImV4cCI6MjA4NjY3NTQ0OX0.Tf49SZ0MOiKqtgAfNmNO9A_N_l6tbSz3AOI7OkXbJfs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: BindingsBuilder(() {
        Get.put(ThemeController());
        Get.put(AuthService());
        Get.put(HistoryController());
        Get.put(EconomyController());
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
