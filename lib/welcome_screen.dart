import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:test_project/target_configuration_screen.dart';
import 'controllers/theme_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/economy_controller.dart';
import 'controllers/quiz_controller.dart';

import 'services/auth_service.dart';
import 'screens/auth_screen.dart';

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

  late Timer _avatarTimer;
  int _currentAvatarIndex = 0;
  final List<String> _avatarAssets = [
    'assets/images/human_avatar.png',
    'assets/images/human_avatar_army.png',
    'assets/images/human_avatar_navy.png',
    'assets/images/human_avatar_police.png',
    'assets/images/human_avatar_ias.png',
    'assets/images/human_avatar_banking.png',
    'assets/images/human_avatar_civil_service.png',
    'assets/images/human_avatar_judiciary.png',
    'assets/images/human_avatar_medical.png',
    'assets/images/human_avatar_teaching.png',
    'assets/images/human_avatar_ssc.png',
  ];

  @override
  void initState() {
    super.initState();

    // Start Avatar Rotation Timer
    _avatarTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentAvatarIndex =
              (_currentAvatarIndex + 1) % _avatarAssets.length;
        });
      }
    });

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
    _avatarTimer.cancel();
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    final HistoryController historyController = Get.find();
    final EconomyController economyController = Get.find();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildThemeToggle(context, themeController)],
      ),
      body: Stack(
        children: [
          // Credit Badge (Top Right - only for logged in users)
          Obx(() {
            if (!AuthService.to.isLoggedIn) return const SizedBox.shrink();

            return Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${economyController.credits.value}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Background Mesh Gradient Effect
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -50 + _offsetAnimation1.value.dy,
                right: -50 + _offsetAnimation1.value.dx,
                child: Opacity(
                  opacity: 0.6 + (_controller1.value * 0.2),
                  child: Container(
                    width: 400 + (_controller1.value * 50),
                    height: 400 + (_controller1.value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
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
                  opacity: 0.6 + (_controller2.value * 0.2),
                  child: Container(
                    width: 300 + (_controller2.value * 30),
                    height: 300 + (_controller2.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.3),
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
                            // Dynamic Avatar Logic
                            Obx(() {
                              final AuthService auth = Get.find();
                              final QuizController quizController = Get.find();

                              // Default Carousel State (Guest or No Goal)
                              if (!auth.isLoggedIn ||
                                  !quizController.isGoalSet.value) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 40,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Pulsing Ring
                                    ScaleTransition(
                                      scale: Tween(begin: 0.95, end: 1.05)
                                          .animate(
                                            CurvedAnimation(
                                              parent: _controller1,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ClipOval(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(seconds: 1),
                                        transitionBuilder:
                                            (
                                              Widget child,
                                              Animation<double> animation,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                        child: Container(
                                          key: ValueKey<int>(
                                            _currentAvatarIndex,
                                          ),
                                          width: 160,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: AssetImage(
                                                _avatarAssets[_currentAvatarIndex],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // LOGGED IN & GOAL SET: Show Specific Avatar
                              return _buildTargetAvatar(
                                quizController.currentAvatarPath,
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Dynamic Welcome Text & Rank
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
                            Obx(() {
                              final isGoalSet =
                                  Get.find<QuizController>().isGoalSet.value;
                              final text = isGoalSet
                                  ? Get.find<QuizController>().currentRoleTitle
                                  : "WELCOME TO GOVPREP AI";

                              return TweenAnimationBuilder<int>(
                                key: ValueKey(
                                  text,
                                ), // Restart animation on text change
                                tween: IntTween(begin: 0, end: text.length),
                                duration: Duration(
                                  milliseconds: text.length * 100,
                                ),
                                builder: (context, value, child) {
                                  return Text(
                                    text.substring(0, value),
                                    style: GoogleFonts.orbitron(
                                      fontSize: 14,
                                      color: Colors.cyanAccent,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.cyan,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                            const SizedBox(height: 8),
                            Obx(
                              () => ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: isDark
                                        ? [Colors.white, Colors.blueAccent]
                                        : [Colors.black87, Colors.blue[800]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  historyController.currentRank,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Stats Pill
                            Obx(
                              () => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      Get.find<AuthService>().isLoggedIn
                                          ? "${historyController.history.length} MISSIONS COMPLETED"
                                          : "START YOUR JOURNEY",
                                      style: GoogleFonts.orbitron(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Primary CTA: Enter Playground
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              final AuthService auth = Get.find();
                              if (auth.isLoggedIn) {
                                Get.offAll(
                                  () => const TargetConfigurationScreen(),
                                );
                              } else {
                                Get.to(() => const AuthScreen());
                              }
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "ENTER PLAYGROUND",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      Text(
                        "Powered by 🌟StarAppAi",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildTargetAvatar(String avatarPath) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Static Glow for Selected Goal
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.2),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
        ClipOval(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(avatarPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Badge
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              "TARGET LOCKED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
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
