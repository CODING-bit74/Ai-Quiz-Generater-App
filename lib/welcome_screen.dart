import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/quiz_screen.dart';
import 'package:test_project/performance_lab_screen.dart';
import 'controllers/theme_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<Offset> _offsetAnimation1;
  late Animation<Offset> _offsetAnimation2;

  @override
  void initState() {
    super.initState();

    // Controller 1: Top Right Orb (Float + Pulse)
    _controller1 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(20, 20),
    ).animate(CurvedAnimation(parent: _controller1, curve: Curves.easeInOut));

    // Controller 2: Bottom Left Orb (Float + Pulse)
    _controller2 = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-20, -20),
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _buildThemeToggle(context, themeController),

      body: Stack(
        children: [
          // Background Mesh Gradient Effect
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -50 + _offsetAnimation1.value.dy,
                right: -50 + _offsetAnimation1.value.dx,
                child: Opacity(
                  opacity: 0.8 + (_controller1.value * 0.2), // Pulse opacity
                  child: Container(
                    width: 400 + (_controller1.value * 50), // Pulse size
                    height: 400 + (_controller1.value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Positioned(
                bottom: -50 + _offsetAnimation2.value.dy,
                left: -50 + _offsetAnimation2.value.dx,
                child: Opacity(
                  opacity: 0.8 + (_controller2.value * 0.2), // Pulse opacity
                  child: Container(
                    width: 300 + (_controller2.value * 30), // Pulse size
                    height: 300 + (_controller2.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Animated Hero Avatar with Glass Circle
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.03),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                        'assets/images/quiz_agent.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Animated Text Polish
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 20, end: 0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, value),
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              "AI QUIZ AGENT",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                "Your Smart Ai Exam Companion",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.blue[100]
                                      : Colors.blue[900],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // CTA Button with Glass Polish
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 1),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const QuizScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.9),
                                        const Color(
                                          0xFF2563EB,
                                        ).withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "GET STARTED",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Performance Lab Secondary CTA
                      TextButton.icon(
                        onPressed: () =>
                            Get.to(() => const PerformanceLabScreen()),
                        icon: const Icon(Icons.analytics_rounded, size: 18),
                        label: const Text(
                          "VIEW PERFORMANCE VAULT",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white38
                              : Colors.black38,
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        "Powered by 🌟StarAppAi",
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return GestureDetector(
        onTap: themeController.toggleTheme,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutBack,
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFFACC15), const Color(0xFFEAB308)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.blue : Colors.orange).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.5),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(
                    turns: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey<bool>(isDark),
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
