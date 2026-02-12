import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Business logic and state management controller
import 'controllers/quiz_controller.dart';
// Custom painter for the results celebration effect
import 'painters/confetti_painter.dart';

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
                    const Color(0xFF1E293B).withOpacity(0.5),
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
      // 1. Initial generation loading state
      if (controller.isLoading.value && controller.questions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => Text(
                  controller.loadingMessage.value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Applying SSC, Banking & UPSC Exam Standards",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }

      // 2. Playground transition state
      if (controller.isShowingPlayground.value) {
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

      // 6. Default: Selection and configuration UI
      return _buildConfigurationView(context, controller);
    });
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
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3 * value),
                              blurRadius: 40 * value,
                              spreadRadius: 10 * value,
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.1),
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
              const SizedBox(height: 60),
              // Main playground title with neon shadow effect
              Text(
                "QUIZ PLAYGROUND",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Prepare for glory...",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              // Visual progress bar for the delay
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  color: Colors.blue,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
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
        color: color.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
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

  /// Main configuration layout for setting up the quiz
  Widget _buildConfigurationView(
    BuildContext context,
    QuizController controller,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      // Padding for better touch safety at bottom
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      child: Column(
        children: [
          // 1. BRANDING & HEADER
          Center(
            child: Column(
              children: [
                // Avatar container with premium glow
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/images/quiz_agent.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MASTER LAB',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Configure your perfect exam session',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. INPUT METHOD NAV BAR (Glassmorphic)
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // iOS-style bouncing feel
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeTab(
                      context,
                      controller,
                      'Topic',
                      Icons.psychology_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeTab(
                      context,
                      controller,
                      'Link',
                      Icons.auto_fix_high_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeTab(
                      context,
                      controller,
                      'Text',
                      Icons.smart_toy_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildTypeTab(
                      context,
                      controller,
                      'Document',
                      Icons.memory_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 3. TARGET EXAM SETTINGS (Enabled for all modes)
          _buildGlassCard(
            context,
            title: "Target Configuration",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic heading based on mode
                Obx(
                  () => Text(
                    controller.selectedType.value == 'Topic'
                        ? "Exam Sector"
                        : "Target Pattern",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Scrollable sector chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: controller.examSectors.keys.map((sector) {
                      return Obx(() {
                        bool isSelected =
                            controller.selectedSector.value == sector;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sector),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) controller.setSector(sector);
                            },
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            selectedColor: Colors.blue[700],
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.blue
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      });
                    }).toList(),
                  ),
                ),
                // Specific Exam Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Specific Exam",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black26
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedExam.value,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).cardColor,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.blue,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          items: controller
                              .examSectors[controller.selectedSector.value]!
                              .map((exam) {
                                return DropdownMenuItem(
                                  value: exam,
                                  child: Text(exam),
                                );
                              })
                              .toList(),
                          onChanged: (val) => controller.setExam(val!),
                        ),
                      ),
                    ),
                  ],
                ),
                // Subject Selection (Only for Topic-based search)
                Obx(
                  () => controller.selectedType.value == 'Topic'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Subject Focus",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: controller.subjects.map((subject) {
                                  return Obx(() {
                                    bool isSelected =
                                        controller.selectedSubject.value ==
                                        subject;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(subject),
                                        selected: isSelected,
                                        onSelected: (val) {
                                          if (val)
                                            controller.setSubject(subject);
                                        },
                                        backgroundColor: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.05),
                                        selectedColor: Colors.purple[700],
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.purple
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.1),
                                          ),
                                        ),
                                        showCheckmark: false,
                                      ),
                                    );
                                  });
                                }).toList(),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // 4. CONTENT SOURCE (Topic Dropdown or Text Field)
          Obx(
            () => _buildGlassCard(
              context,
              title: controller.selectedType.value == 'Topic'
                  ? "Topic Selection"
                  : (controller.selectedType.value == 'Document'
                        ? "Book / Notes Selection"
                        : "Reference Material"),
              child: controller.selectedType.value == 'Topic'
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detailed Topic",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black26
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.selectedTopic.value,
                              isExpanded: true,
                              dropdownColor: Theme.of(context).cardColor,
                              icon: const Icon(
                                Icons.category_rounded,
                                color: Colors.blue,
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              items: controller
                                  .subjectTopics[controller
                                      .selectedSubject
                                      .value]!
                                  .map((topic) {
                                    return DropdownMenuItem(
                                      value: topic,
                                      child: Text(topic),
                                    );
                                  })
                                  .toList(),
                              onChanged: (val) => controller.setTopic(val!),
                            ),
                          ),
                        ),
                      ],
                    )
                  : (controller.selectedType.value == 'Document'
                        ? _buildDocumentSourceCard(context, controller)
                        : TextField(
                            controller: controller.inputController,
                            maxLines: 5,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: controller.selectedType.value == 'Link'
                                  ? "Paste URL here (e.g., https://...)"
                                  : "Paste your study notes or text here...",
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )),
            ),
          ),
          Obx(
            () => controller.selectedType.value == 'Document'
                ? const SizedBox.shrink()
                : const SizedBox(height: 24),
          ),

          // 5. SESSION PREFERENCES
          _buildGlassCard(
            context,
            title: "Session Preferences",
            child: Column(
              children: [
                // Language Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Language",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black26
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(
                          () => DropdownButton<String>(
                            value: controller.selectedLanguage.value,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardColor,
                            icon: const Icon(
                              Icons.language,
                              color: Colors.blue,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            items: controller.languages
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(l),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => controller.setLanguage(val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 5b. DIFFICULTY LEVEL SELECTOR
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Difficulty",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Easy', 'Medium', 'Hard']
                          .map(
                            (level) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: _buildDifficultyChip(
                                  context,
                                  controller,
                                  level,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 5c. QUESTION COUNT ADJUSTER
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Question Count",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Real-time value display
                        Obx(
                          () => Text(
                            "${controller.numQuestions.value.toInt()}",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Obx(
                      () => Slider(
                        value: controller.numQuestions.value,
                        min: 5,
                        max: 20,
                        divisions: 3, // Steps: 5, 10, 15, 20
                        activeColor: Colors.blue,
                        inactiveColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                        onChanged: (val) => controller.setNumQuestions(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // 6. PRIMARY ACTION: GENERATE
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: controller.generateQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.blue.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'GENERATE QUIZ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Active quiz session interface
  Widget _buildGameplayView(BuildContext context, QuizController controller) {
    // Current state extraction
    final question =
        controller.questions[controller.currentQuestionIndex.value];
    final options = question['options'] as List<dynamic>;
    final userSelection =
        controller.userAnswers[controller.currentQuestionIndex.value];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session progress bar (top)
          Obx(
            () => LinearProgressIndicator(
              value:
                  (controller.currentQuestionIndex.value + 1) /
                  controller.questions.length,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.1),
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Custom timer badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Obx(
                      () => Text(
                        "${controller.remainingSeconds.value}s",
                        style: TextStyle(
                          // Alert color for low time
                          color: controller.remainingSeconds.value < 10
                              ? Colors.red
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Step counter (e.g., 2/10)
              Obx(
                () => Text(
                  "QUESTION ${controller.currentQuestionIndex.value + 1}/${controller.questions.length}",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // THE QUESTION TEXT
          Text(
            question['question'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          // INTERACTIVE OPTIONS LIST
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = userSelection == index;

                Color borderColor = Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.1);
                Color bgColor = Theme.of(context).cardColor;

                // Visual feedback for selection
                if (isSelected) {
                  borderColor = Colors.blue;
                  bgColor = Colors.blue.withOpacity(0.1);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => controller.handleOptionSelected(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        // Frosted glass effect for options
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive results breakdown and post-game actions
  Widget _buildResultsView(BuildContext context, QuizController controller) {
    if (controller.questions.isEmpty) return const SizedBox.shrink();

    // Stats calculations
    final percentage =
        (controller.score.value / controller.questions.length * 100).toInt();
    final correct = controller.score.value;
    final total = controller.questions.length;
    final wrong = total - correct;

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
      performanceMessage = "KEEP LEARNING";
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
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.9),
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
                      // Mastery Badge
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
                              color: gradientColors[0].withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          performanceIcon,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        performanceMessage,
                        style: TextStyle(
                          color: gradientColors[0],
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // THE SCORE ORB
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: CircularProgressIndicator(
                              value: percentage / 100,
                              strokeWidth: 16,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                              color: gradientColors[0],
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "$percentage%",
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                "SCORE",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // GRANULAR PERFORMANCE STATS
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPremiumStat(
                              context,
                              "CORRECT",
                              "$correct",
                              Colors.greenAccent,
                              Icons.check_circle,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                            _buildPremiumStat(
                              context,
                              "WRONG",
                              "$wrong",
                              Colors.redAccent,
                              Icons.cancel,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                            _buildPremiumStat(
                              context,
                              "TOTAL",
                              "$total",
                              Theme.of(context).colorScheme.onSurface,
                              Icons.list_alt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // POST-QUIZ FLOW ACTIONS
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: controller.enterReviewMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'REVIEW ANSWERS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: controller.startNewQuiz,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text(
                      'START NEW QUIZ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 16,
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

  /// Reusable stat cell for results summary
  Widget _buildPremiumStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  /// Handles switching between upload zone and file dashboard
  Widget _buildDocumentSourceCard(
    BuildContext context,
    QuizController controller,
  ) {
    return Obx(() {
      final hasFile = controller.pickedFileName.value != null;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: hasFile
            ? _buildFileDashboard(context, controller)
            : _buildUploadZone(context, controller),
      );
    });
  }

  /// Render the interactive upload catchment area
  Widget _buildUploadZone(BuildContext context, QuizController controller) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => controller.pickFile(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Floating cloud icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Tap to select book/notes",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "PDF format only (Max 200MB)",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders file-specific management controls once picked
  Widget _buildFileDashboard(BuildContext context, QuizController controller) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // PDF Icon with themed background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Filename and status info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.pickedFileName.value ?? "",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Document Ready",
                  style: TextStyle(
                    color: Colors.greenAccent.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Removal trigger
          IconButton(
            onPressed: () => controller.removeFile(),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            tooltip: "Remove file",
          ),
        ],
      ),
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
            final options = question['options'] as List<dynamic>;
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
                ).colorScheme.onSurface.withOpacity(isDark ? 0.05 : 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCorrect
                      ? Colors.green.withOpacity(0.5)
                      : (isSkipped
                            ? Colors.orange.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5)),
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
                              ? Colors.green.withOpacity(0.2)
                              : (isSkipped
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2)),
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
                      tileColor = Colors.green.withOpacity(0.1);
                      contentColor = Colors.green;
                      icon = Icons.check_circle;
                    } else if (isSelected) {
                      tileColor = Colors.red.withOpacity(0.1);
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
                            ? Border.all(color: contentColor.withOpacity(0.5))
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
                                                .withOpacity(0.6)),
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
                      color: Colors.blue.withOpacity(0.1),
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
                            ).colorScheme.onSurface.withOpacity(0.8),
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

/// Helper builder for the navigation category tabs
Widget _buildTypeTab(
  BuildContext context,
  QuizController controller,
  String label,
  IconData icon,
) {
  return GestureDetector(
    onTap: () => controller.setType(label),
    child: Obx(() {
      bool isSelected = controller.selectedType.value == label;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: AnimatedScale(
          // Subtle scale feedback when active
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: isSelected ? 0.5 : 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

/// Specialized chip for difficulty level selection
Widget _buildDifficultyChip(
  BuildContext context,
  QuizController controller,
  String level,
) {
  return GestureDetector(
    onTap: () => controller.setDifficulty(level),
    child: Obx(() {
      bool isSelected = controller.difficulty.value == level;
      bool isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.1)
              : (isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue[400]!
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              level.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? Colors.blue[400]
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      );
    }),
  );
}

/// Generic wrapper for sections with glass effect and consistent headers
Widget _buildGlassCard(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section title with premium spacing
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      // Frosted Glass Content Area
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.6)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: child,
          ),
        ),
      ),
    ],
  );
}
