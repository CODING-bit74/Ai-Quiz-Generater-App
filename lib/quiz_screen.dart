import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/quiz_controller.dart';
import 'painters/confetti_painter.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller
    final QuizController controller = Get.put(QuizController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E293B).withOpacity(0.5),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Obx(
                () => controller.isLoading.value
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: _buildBody(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final QuizController controller = Get.find();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  controller.isQuizActive.value = false;
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          Obx(
            () => Text(
              controller.isQuizActive.value
                  ? "QUESTION ${controller.currentQuestionIndex.value + 1}/${controller.questions.length}"
                  : "PREPARATION LAB",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const Opacity(
            opacity: 0,
            child: IconButton(icon: Icon(Icons.menu), onPressed: null),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(QuizController controller) {
    return Obx(() {
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
              const Text(
                "CRAFTING YOUR QUIZ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Applying SSC, Banking & UPSC Exam Standards",
                style: TextStyle(
                  color: Colors.blue[200],
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.isShowingPlayground.value) {
        return _buildPlaygroundView(controller);
      }

      if (controller.isQuizActive.value && controller.questions.isNotEmpty) {
        return _buildGameplayView(controller);
      }

      if (controller.isReviewing.value) {
        return _buildReviewView(controller);
      }

      if (controller.isQuizFinished.value && controller.questions.isNotEmpty) {
        return _buildResultsView(controller);
      }

      return _buildConfigurationView(controller);
    });
  }

  Widget _buildPlaygroundView(QuizController controller) {
    return Stack(
      children: [
        // Dynamic Background Elements
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
                          color: Colors.white.withOpacity(0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3 * value),
                              blurRadius: 40 * value,
                              spreadRadius: 10 * value,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          controller.gameLogos[controller
                              .currentLogoIndex
                              .value],
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                "QUIZ PLAYGROUND",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.blueAccent, blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Prepare for glory...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
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
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(),
      ),
    );
  }

  Widget _buildConfigurationView(QuizController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      child: Column(
        children: [
          // 1. Header & Avatar
          Center(
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
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
                const Text(
                  'MASTER LAB',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Configure your perfect exam session',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. Input Method Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeTab(controller, 'Topic', Icons.auto_awesome),
                ),
                Expanded(
                  child: _buildTypeTab(controller, 'Link', Icons.link_rounded),
                ),
                Expanded(
                  child: _buildTypeTab(
                    controller,
                    'Text',
                    Icons.article_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 3. TARGET CONFIGURATION CARD
          _buildGlassCard(
            title: "Target Configuration",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sector Selector
                const Text(
                  "Exam Sector",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
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
                            backgroundColor: Colors.white.withOpacity(0.05),
                            selectedColor: Colors.blue[700],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
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
                                    : Colors.white10,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      });
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Exam Name Dropdown
                const Text(
                  "Specific Exam",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedExam.value,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.blue,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
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
                ),
                const SizedBox(height: 20),

                // Subject Selector
                const Text(
                  "Subject Focus",
                  style: TextStyle(
                    color: Colors.white70,
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
                            controller.selectedSubject.value == subject;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(subject),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) controller.setSubject(subject);
                            },
                            backgroundColor: Colors.white.withOpacity(0.05),
                            selectedColor: Colors.purple[700],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.purple
                                    : Colors.white10,
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
            ),
          ),
          const SizedBox(height: 24),

          // 4. CONTENT SOURCE CARD
          Obx(
            () => _buildGlassCard(
              title: controller.selectedType.value == 'Topic'
                  ? "Topic Selection"
                  : "Reference Material",
              child: controller.selectedType.value == 'Topic'
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detailed Topic",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.selectedTopic.value,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1E293B),
                              icon: const Icon(
                                Icons.category_rounded,
                                color: Colors.blue,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
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
                  : TextField(
                      controller: controller.inputController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: controller.selectedType.value == 'Link'
                            ? "Paste URL here (e.g., https://...)"
                            : "Paste your study notes or text here...",
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. PREFERENCES CARD
          _buildGlassCard(
            title: "Session Preferences",
            child: Column(
              children: [
                // Language
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Language",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(
                          () => DropdownButton<String>(
                            value: controller.selectedLanguage.value,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(
                              Icons.language,
                              color: Colors.blue,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
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
                // Difficulty
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Difficulty",
                      style: TextStyle(
                        color: Colors.white60,
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
                                child: _buildDifficultyChip(controller, level),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Question Count Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Question Count",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                        divisions: 3,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.white10,
                        onChanged: (val) => controller.setNumQuestions(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // GENERATE BUTTON
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

  Widget _buildGameplayView(QuizController controller) {
    // Determine current question and options
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
          Obx(
            () => LinearProgressIndicator(
              value:
                  (controller.currentQuestionIndex.value + 1) /
                  controller.questions.length,
              backgroundColor: Colors.white10,
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Obx(
                () => Text(
                  "QUESTION ${controller.currentQuestionIndex.value + 1}/${controller.questions.length}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = userSelection == index;

                Color borderColor = Colors.white.withOpacity(0.1);
                Color bgColor = const Color(0xFF1E293B);

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
                                        : Colors.grey[400],
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

  Widget _buildResultsView(QuizController controller) {
    if (controller.questions.isEmpty) return const SizedBox.shrink();

    final percentage =
        (controller.score.value / controller.questions.length * 100).toInt();
    final correct = controller.score.value;
    final total = controller.questions.length;
    final wrong = total - correct;

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
        if (percentage >= 80)
          Positioned.fill(child: CustomPaint(painter: ConfettiPainter())),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B).withValues(alpha: 0.9),
                        const Color(0xFF0F172A).withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Badge/Icon
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

                      // Score Display
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: CircularProgressIndicator(
                              value: percentage / 100,
                              strokeWidth: 16,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
                              color: gradientColors[0],
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "$percentage%",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "SCORE",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
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

                      // Improvements Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPremiumStat(
                              "CORRECT",
                              "$correct",
                              Colors.greenAccent,
                              Icons.check_circle,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white10,
                            ),
                            _buildPremiumStat(
                              "WRONG",
                              "$wrong",
                              Colors.redAccent,
                              Icons.cancel,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white10,
                            ),
                            _buildPremiumStat(
                              "TOTAL",
                              "$total",
                              Colors.white,
                              Icons.list_alt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: controller.enterReviewMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 10,
                      shadowColor: Colors.white.withValues(alpha: 0.2),
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
                      side: const BorderSide(color: Colors.white30, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
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

  Widget _buildPremiumStat(
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
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

Widget _buildReviewView(QuizController controller) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: controller.exitReviewMode,
            ),
            const SizedBox(width: 8),
            const Text(
              "REVIEW ANSWERS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.questions.length,
          itemBuilder: (context, index) {
            final question = controller.questions[index];
            final options = question['options'] as List<dynamic>;
            final userIndex = controller.userAnswers[index];
            final correctAnswer = question['answer'];

            int correctIndex = -1;
            for (int i = 0; i < options.length; i++) {
              if (options[i] == correctAnswer) {
                correctIndex = i;
                break;
              }
            }

            final bool isCorrect =
                userIndex != null && options[userIndex] == correctAnswer;
            final bool isSkipped = userIndex == null || userIndex == -1;

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                                color: isThisCorrect || isSelected
                                    ? Colors.white
                                    : Colors.white60,
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
                            color: Colors.blue[100],
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

Widget _buildTypeTab(QuizController controller, String label, IconData icon) {
  return GestureDetector(
    onTap: () => controller.setType(label),
    child: Obx(() {
      bool isSelected = controller.selectedType.value == label;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }),
  );
}

Widget _buildDifficultyChip(QuizController controller, String level) {
  return GestureDetector(
    onTap: () => controller.setDifficulty(level),
    child: Obx(() {
      bool isSelected = controller.difficulty.value == level;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue[400]!
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              level.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.blue[200] : Colors.grey[600],
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

Widget _buildGlassCard({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.blue[200],
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: child,
          ),
        ),
      ),
    ],
  );
}
