import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Business logic and state management controller
import 'controllers/quiz_controller.dart';
import 'controllers/history_controller.dart';
// Custom painter for the results celebration effect
import 'painters/confetti_painter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the global singleton instance of QuizController
    final QuizController controller = Get.find<QuizController>();

    // Local variable to track dark mode for manual UI adjustments
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Dynamic background color from the system theme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Prevents UI overflow when the keyboard is active
      resizeToAvoidBottomInset: true,
      body: Container(
        // Premium background gradient for a high-end feel
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1E293B).withValues(alpha: 0.5),
                    const Color(0xFF0F172A),
                  ]
                : [Colors.white, const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          // Ensures content avoids notch/system bars
          child: Column(
            children: [
              // Custom glass-styled app bar
              _buildCustomAppBar(context),
              // Reactive loading indicator for generation process
              Obx(
                () => controller.isLoading.value
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      )
                    : const SizedBox.shrink(),
              ),
              // Main content area that switches based on controller state
              Expanded(child: _buildBody(context, controller)),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders a dynamic app bar with contextual navigation
  Widget _buildCustomAppBar(BuildContext context) {
    final QuizController controller = Get.find();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Switch between 'Close' (mid-quiz) and 'Back' (config)
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isQuizActive.value
                    ? Icons.close
                    : Icons.arrow_back_ios_new,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: () {
                if (controller.isQuizActive.value) {
                  // Exit active quiz session
                  controller.isQuizActive.value = false;
                } else {
                  // Close the entire screen
                  Navigator.pop(context);
                }
              },
            ),
          ),
          // Dynamic title based on session phase
          Obx(
            () => Text(
              controller.isQuizActive.value
                  ? "QUESTION ${controller.currentQuestionIndex.value + 1}/${controller.questions.length}"
                  : "PREPARATION LAB",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          // Balanced layout spacer
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// Orchestrates the view selection using reactive state
  Widget _buildBody(BuildContext context, QuizController controller) {
    return Obx(() {
      // 1. Unified Loading / Playground state
      if ((controller.isLoading.value && controller.questions.isEmpty) ||
          controller.isShowingPlayground.value) {
        return _buildPlaygroundView(context, controller);
      }

      // 3. Active gameplay state
      if (controller.isQuizActive.value && controller.questions.isNotEmpty) {
        return _buildGameplayView(context, controller);
      }

      // 4. Review mode (viewing correct answers)
      if (controller.isReviewing.value) {
        return _buildReviewView(context, controller);
      }

      // 5. Results summary state
      if (controller.isQuizFinished.value && controller.questions.isNotEmpty) {
        return _buildResultsView(context, controller);
      }

      // 6. Error State
      if (controller.errorMessage.value != null) {
        return _buildErrorView(context, controller);
      }

      // 7. Default fallback / Empty State
      return _buildErrorView(
        context,
        controller,
        customMessage: "Ready to Start",
        showStartButton: false,
      );
    });
  }

  Widget _buildErrorView(
    BuildContext context,
    QuizController controller, {
    String? customMessage,
    bool showStartButton = true,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (customMessage ?? controller.errorMessage.value ?? "").contains(
                    "captions",
                  )
                  ? Icons.closed_caption_disabled_rounded
                  : Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              "Oops!",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              customMessage ??
                  controller.errorMessage.value ??
                  "Unknown error occurred.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (showStartButton)
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text("GO BACK"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Renders a visually immersive loading experience
  Widget _buildPlaygroundView(BuildContext context, QuizController controller) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Decorative glowing background elements
        Positioned(
          top: -100,
          right: -100,
          child: _buildGlowingOrb(Colors.blue, 300),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _buildGlowingOrb(Colors.purple, 250),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cycling gaming logos with elastic animations
                    Obx(
                      () => TweenAnimationBuilder<double>(
                        key: ValueKey(controller.currentLogoIndex.value),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3 * value),
                                    blurRadius: 40 * value,
                                    spreadRadius: 10 * value,
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                controller.gameLogos[controller
                                    .currentLogoIndex
                                    .value],
                                size: 80,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Main playground title with neon shadow effect
                    Obx(
                      () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _getPlaygroundTitle(controller.selectedType.value),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          controller.loadingMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 13,
                            letterSpacing: 1.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Visual progress bar for the delay
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                          color: Colors.blueAccent,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Educational Tip Carousel
                    Obx(() {
                      if (controller.currentTip.value.isEmpty) {
                        return const SizedBox(height: 80);
                      }
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          key: ValueKey(controller.currentTip.value),
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "BRAIN BOOST",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.amber,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                controller.currentTip.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Utility to create blurred atmospheric orbs
  Widget _buildGlowingOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
      child: BackdropFilter(
        // Blurs underlying content for a frosted glass orb effect
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(),
      ),
    );
  }

  String _getPlaygroundTitle(String type) {
    switch (type.toLowerCase()) {
      case 'link':
        return "VIDEO INTELLIGENCE";
      case 'document':
        return "DOCUMENT PROCESSOR";
      case 'text':
        return "CONTENT ANALYSIS";
      case 'topic':
      default:
        return "KNOWLEDGE MAPPING";
    }
  }

  /// Active quiz session interface
  Widget _buildGameplayView(BuildContext context, QuizController controller) {
    // Current state extraction
    final question =
        controller.questions[controller.currentQuestionIndex.value];
    final options =
        (question['options'] as List<dynamic>?) ?? ['A', 'B', 'C', 'D'];
    final userSelection =
        controller.userAnswers[controller.currentQuestionIndex.value];

    // Using CustomScrollView for a premium, scrollable experience
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Session progress bar (top)
              Obx(
                () => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        (controller.currentQuestionIndex.value + 1) /
                        controller.questions.length,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    color: Colors.blueAccent,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Timer and Step Counter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Custom timer badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Obx(
                          () => Text(
                            "${controller.remainingSeconds.value}s",
                            style: TextStyle(
                              color: controller.remainingSeconds.value < 10
                                  ? Colors.redAccent
                                  : Colors.blueAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Step counter
                  Obx(
                    () => Text(
                      "QUESTION ${controller.currentQuestionIndex.value + 1} OF ${controller.questions.length}",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 3. Structured Question Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Decorative quote icon
                    Icon(
                      Icons.format_quote_rounded,
                      size: 40,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question['question'],
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Roboto', // Or your app's font
                      ),
                    ),
                    if (question['markdown_diagram'] != null &&
                        question['markdown_diagram']
                            .toString()
                            .trim()
                            .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: MarkdownBody(
                          data: question['markdown_diagram'].toString(),
                          styleSheet: MarkdownStyleSheet(
                            code: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            codeblockPadding: const EdgeInsets.all(12),
                            codeblockDecoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black26
                                  : Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Options Header
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                child: Text(
                  "SELECT AN OPTION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // 5. Scrollable Options List (as slivers)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final option = options[index];
              final isSelected = userSelection == index;

              Color borderColor = Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1);
              Color bgColor = Theme.of(context).cardColor;
              Color textColor = Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8);

              // Visual feedback for selection
              if (isSelected) {
                borderColor = Colors.blueAccent;
                bgColor = Colors.blueAccent.withValues(alpha: 0.1);
                textColor = Colors.blueAccent;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => controller.handleOptionSelected(index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical:
                          20, // More vertical padding for multi-line options
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align top for long text
                      children: [
                        // Radio-like indicator
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(
                            top: 2,
                          ), // Align with text
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blueAccent,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Option Text
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: options.length),
          ),
        ),
        // Extra padding at bottom for safety
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  /// Interactive results breakdown and post-game actions
  Widget _buildResultsView(BuildContext context, QuizController controller) {
    if (controller.questions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Stats calculations
    final percentage =
        (controller.score.value / controller.questions.length * 100).toInt();
    final correct = controller.score.value;
    final total = controller.questions.length;
    final wrong = total - correct;

    // Get HistoryController for Rank Logic
    final HistoryController historyController =
        Get.isRegistered<HistoryController>()
        ? Get.find<HistoryController>()
        : Get.put(HistoryController());

    // Visual theme selection based on performance
    String performanceMessage;
    IconData performanceIcon;
    List<Color> gradientColors;

    if (percentage == 100) {
      performanceMessage = "LEGENDARY!";
      performanceIcon = Icons.military_tech;
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFE6AC00)];
    } else if (percentage >= 80) {
      performanceMessage = "EXCELLENT";
      performanceIcon = Icons.stars;
      gradientColors = [const Color(0xFF4ADE80), const Color(0xFF22C55E)];
    } else if (percentage >= 50) {
      performanceMessage = "GOOD JOB";
      performanceIcon = Icons.thumb_up;
      gradientColors = [const Color(0xFF60A5FA), const Color(0xFF3B82F6)];
    } else {
      performanceMessage = "TRAINING NEEDED";
      performanceIcon = Icons.refresh;
      gradientColors = [const Color(0xFFF87171), const Color(0xFFEF4444)];
    }

    return Stack(
      children: [
        // Celebrate success with confetti
        if (percentage >= 80)
          Positioned.fill(child: CustomPaint(painter: ConfettiPainter())),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // MAIN RESULT CARD
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mastery Badge with Rank Progress
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              performanceIcon,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Rank Progress Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      historyController.currentRank,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      historyController.nextRankTitle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Colors.grey.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: historyController.rankProgress,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      gradientColors.first,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${historyController.missionsToNextRank} missions to promotion",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        performanceMessage,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: gradientColors.first,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Animated Score
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percentage.toDouble()),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, child) {
                          return Text(
                            "${value.toInt()}%",
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1,
                            ),
                          );
                        },
                      ),

                      Text(
                        "SCORE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Detailed Stats Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            context,
                            "$correct",
                            "CORRECT",
                            Colors.green,
                            Icons.check_circle_outline,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Theme.of(context).dividerColor,
                          ),
                          _buildStatItem(
                            context,
                            "$wrong",
                            "WRONG",
                            Colors.redAccent,
                            Icons.cancel_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.enterReviewMode();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: const Text(
                      'REVIEW ANSWERS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        controller.startNewQuiz();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'RETURN TO BASE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// Standalone view for post-quiz answer correction and learning
Widget _buildReviewView(BuildContext context, QuizController controller) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Column(
    children: [
      // View Header
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: controller.exitReviewMode,
            ),
            const SizedBox(width: 8),
            Text(
              "REVIEW ANSWERS",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      // Scrollable list of all questions with results
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.questions.length,
          itemBuilder: (context, index) {
            final question = controller.questions[index];
            final options =
                (question['options'] as List<dynamic>?) ?? ['A', 'B', 'C', 'D'];
            final userIndex = controller.userAnswers[index];
            final correctAnswer = question['answer'];

            // Locate the index of the correct answer string in the options list
            int correctIndex = -1;
            for (int i = 0; i < options.length; i++) {
              if (options[i] == correctAnswer) {
                correctIndex = i;
                break;
              }
            }

            // Status determination
            final bool isCorrect =
                userIndex != null && options[userIndex] == correctAnswer;
            final bool isSkipped = userIndex == null || userIndex == -1;

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.5)
                      : (isSkipped
                            ? Colors.orange.withValues(alpha: 0.5)
                            : Colors.red.withValues(alpha: 0.5)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question header (Tag + Text)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withValues(alpha: 0.2)
                              : (isSkipped
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Q${index + 1}",
                          style: TextStyle(
                            color: isCorrect
                                ? Colors.green
                                : (isSkipped ? Colors.orange : Colors.red),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question['question'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (question['markdown_diagram'] != null &&
                      question['markdown_diagram'].toString().trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: MarkdownBody(
                        data: question['markdown_diagram'].toString(),
                        styleSheet: MarkdownStyleSheet(
                          code: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          codeblockPadding: const EdgeInsets.all(12),
                          codeblockDecoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Render all options with correctness highlights
                  ...List.generate(options.length, (optIndex) {
                    final option = options[optIndex];
                    final bool isSelected = userIndex == optIndex;
                    final bool isThisCorrect = optIndex == correctIndex;

                    Color tileColor = Colors.transparent;
                    Color contentColor = Colors.grey;
                    IconData? icon;

                    if (isThisCorrect) {
                      tileColor = Colors.green.withValues(alpha: 0.1);
                      contentColor = Colors.green;
                      icon = Icons.check_circle;
                    } else if (isSelected) {
                      tileColor = Colors.red.withValues(alpha: 0.1);
                      contentColor = Colors.red;
                      icon = Icons.cancel;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isThisCorrect || isSelected
                            ? Border.all(color: contentColor.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: isThisCorrect
                                    ? Colors.green[700]
                                    : (isSelected
                                          ? Colors.red[700]
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6)),
                                fontWeight: isThisCorrect || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (icon != null)
                            Icon(icon, color: contentColor, size: 20),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  // AI-Generated Explanation Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "EXPLANATION",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question['explanation'] ?? "No explanation provided.",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
