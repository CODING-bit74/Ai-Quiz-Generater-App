import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/services.dart'; // For Clipboard
import 'quiz_screen.dart'; // Ensure this import exists for navigation
import 'controllers/quiz_controller.dart'; // Ensure this import exists
import 'controllers/economy_controller.dart';
import 'screens/auth/goal_selection_screen.dart';

class YouTubeInputScreen extends StatefulWidget {
  const YouTubeInputScreen({super.key});

  @override
  State<YouTubeInputScreen> createState() => _YouTubeInputScreenState();
}

class _YouTubeInputScreenState extends State<YouTubeInputScreen>
    with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final QuizController _quizController = Get.find<QuizController>();

  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Hindi',
    'Hinglish',
    'Gujarati',
    'Marathi',
    'Tamil',
    'Telugu',
    'Bengali',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Odia',
    'Assamese',
    'Urdu',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Background Animation Controllers
  late AnimationController _orbController1;
  late AnimationController _orbController2;
  late Animation<Offset> _orbOffset1;
  late Animation<Offset> _orbOffset2;

  @override
  void initState() {
    super.initState();

    // UI Fade In
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Background Orbs
    _orbController1 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _orbOffset1 =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(20, 20),
        ).animate(
          CurvedAnimation(parent: _orbController1, curve: Curves.easeInOut),
        );

    _orbController2 = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _orbOffset2 =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(-20, -20),
        ).animate(
          CurvedAnimation(parent: _orbController2, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _fadeController.dispose();
    _orbController1.dispose();
    _orbController2.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      if (data.text!.contains('youtube.com') ||
          data.text!.contains('youtu.be')) {
        setState(() {
          _urlController.text = data.text!;
        });
        Get.snackbar(
          "Link Pasted",
          "YouTube link detected!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 16,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "No Link Found",
          "Clipboard does not contain a valid YouTube link",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 16,
        );
      }
    }
  }

  void _generateQuiz() {
    if (_urlController.text.isEmpty) {
      Get.snackbar(
        "Oops!",
        "Please enter a YouTube URL",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return;
    }

    // Credit Check (Premium Feature)
    final EconomyController economyController = Get.find();

    // We need to await the deduction, so make this function async or handle future
    _processGeneration(economyController);
  }

  Future<void> _processGeneration(EconomyController economyController) async {
    bool success = await economyController.deductCredits(20);
    if (!success) return;

    // Call the controller to generate quiz (FIRE AND FORGET)
    // We do NOT await here so that we can navigate immediately to the QuizScreen
    // which displays the "AI Loading / Thinking" state.
    _quizController.generateQuiz(
      topic: _urlController.text.trim(),
      inputType: 'link', // The backend will detect it's a YouTube link
      language: _selectedLanguage,
      difficulty: 'Medium', // Default for now
    );

    // Navigate immediately to show the AI loading animation
    Get.to(() => const QuizScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Onboarding Check: Redirect new users if no goal is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_quizController.isGoalSet.value) {
        Get.to(() => const GoalSelectionScreen());
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Quiz Studio"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Base Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
              ),
            ),
          ),

          // 2. Animated Orbs
          AnimatedBuilder(
            animation: _orbController1,
            builder: (context, child) {
              return Positioned(
                top: -100 + _orbOffset1.value.dy,
                right: -100 + _orbOffset1.value.dx,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.2),
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
            animation: _orbController2,
            builder: (context, child) {
              return Positioned(
                bottom: -50 + _orbOffset2.value.dy,
                left: -50 + _orbOffset2.value.dx,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // YouTube Icon with Glow
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 72,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Gradient Title
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isDark
                              ? [Colors.white, Colors.redAccent.shade100]
                              : [Colors.black87, Colors.red.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          "Video to Quiz",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Paste a YouTube link to instantly generate\nan interactive quiz. (Captions Required)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Target Goal Configuration
                      _buildTargetExamSettings(
                        context,
                        _quizController,
                        isDark,
                      ),

                      const SizedBox(height: 24),

                      // Glassmorphic Input Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Video Link",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // URL Input
                            TextField(
                              controller: _urlController,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: "https://youtu.be/...",
                                hintStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.link_rounded),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.paste_rounded,
                                    size: 20,
                                  ),
                                  onPressed: _pasteFromClipboard,
                                  tooltip: "Paste Link",
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              "Quiz Language",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Language Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedLanguage,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Theme.of(context).cardColor,
                                  items: _languages.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedLanguage = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Generate Button
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _quizController.isLoading.value
                                ? null
                                : _generateQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.redAccent
                                  .withOpacity(0.5),
                              elevation: 8,
                              shadowColor: Colors.redAccent.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _quizController.isLoading.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "GENERATE QUIZ (-20 💎)",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildTargetExamSettings(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    return Obx(() {
      if (!controller.isGoalSet.value) {
        return _buildGoalActionCard(context);
      }

      return _buildSelectedGoalCard(context, controller, isDark);
    });
  }

  Widget _buildGoalActionCard(BuildContext context) {
    return _buildGlassCard(
      context,
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            "CHOOSE YOUR TARGET",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select an exam goal to personalize your mission.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.to(() => const GoalSelectionScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("SET YOUR GOAL"),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedGoalCard(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.05)]
              : [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "ACTIVE TARGET",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.to(() => const GoalSelectionScreen()),
                child: const Text(
                  "CHANGE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            controller.selectedSector.value.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.selectedExam.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(isDark ? 0.3 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
