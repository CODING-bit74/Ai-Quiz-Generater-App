import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/history_controller.dart';
import 'quiz_screen.dart';
import 'performance_lab_screen.dart';

class TargetConfigurationScreen extends StatelessWidget {
  const TargetConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final QuizController controller = Get.find<QuizController>();
    // Ensure HistoryController is available
    final HistoryController historyController =
        Get.isRegistered<HistoryController>()
        ? Get.find<HistoryController>()
        : Get.put(HistoryController());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Container(
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
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PROFILE HEADER
                      _buildProfileHeader(context, historyController),
                      const SizedBox(height: 32),

                      // 2. MISSION CONFIGURATION
                      _buildSectionHeader(
                        context,
                        "MISSION CONTROL",
                        Icons.tune_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildInputMethodSelector(context, controller, isDark),
                      const SizedBox(height: 24),
                      _buildTargetExamSettings(context, controller, isDark),
                      const SizedBox(height: 16),
                      Obx(
                        () => _buildContentSource(context, controller, isDark),
                      ),
                      const SizedBox(height: 16),
                      _buildSessionPreferences(context, controller, isDark),
                      const SizedBox(height: 32),
                      _buildGenerateButton(context, controller),
                      const SizedBox(height: 48),

                      // 3. RECENT ACTIVITY
                      _buildSectionHeader(
                        context,
                        "RECENT BRIEFINGS",
                        Icons.history_edu_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildRecentActivity(context, historyController),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.blue,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "COMMAND CENTER",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            onPressed: () => Get.to(() => const PerformanceLabScreen()),
            icon: Icon(
              Icons.insights_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: "Open Performance Vault",
          ),
        ],
      ),
    );
  }

  // --- 1. PROFILE HEADER ---

  Widget _buildProfileHeader(
    BuildContext context,
    HistoryController historyController,
  ) {
    return Obx(() {
      final missionCount = historyController.history.length;
      final avgScore = historyController.averageScore;

      // Determine Rank
      String rank = "GOVPrpeAi";
      Color rankColor = Colors.blueGrey;
      if (missionCount > 30) {
        rank = "MASTER";
        rankColor = Colors.amber;
      } else if (missionCount > 15) {
        rank = "COMMANDER";
        rankColor = Colors.purpleAccent;
      } else if (missionCount > 5) {
        rank = "OFFICER";
        rankColor = Colors.blue;
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor.withOpacity(0.5), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/govprpeai_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rank,
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.verified_user_rounded,
                        color: rankColor,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "User Profile", // Could be dynamic name later
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mini Stats
                  Row(
                    children: [
                      _buildMiniStat(context, "$missionCount", "Missions"),
                      const SizedBox(width: 16),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      const SizedBox(width: 16),
                      Obx(
                        () => _buildMiniStat(
                          context,
                          "${historyController.credits.value}",
                          "Credits",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      const SizedBox(width: 16),
                      _buildMiniStat(
                        context,
                        "${avgScore.toInt()}%",
                        "Accuracy",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMiniStat(BuildContext context, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        if (title == "RECENT BRIEFINGS")
          TextButton(
            onPressed: () => Get.to(() => const PerformanceLabScreen()),
            child: const Text("VIEW ALL", style: TextStyle(fontSize: 10)),
          ),
      ],
    );
  }

  // --- 2. MISSION CONFIG COMPONENTS ---

  Widget _buildInputMethodSelector(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeTab(context, controller, 'Topic', Icons.psychology_rounded),
          const SizedBox(width: 8),
          _buildTypeTab(
            context,
            controller,
            'Link',
            Icons.auto_fix_high_rounded,
          ),
          const SizedBox(width: 8),
          _buildTypeTab(context, controller, 'Text', Icons.smart_toy_rounded),
          const SizedBox(width: 8),
          _buildTypeTab(context, controller, 'Document', Icons.memory_rounded),
        ],
      ),
    );
  }

  Widget _buildTypeTab(
    BuildContext context,
    QuizController controller,
    String type,
    IconData icon,
  ) {
    return Obx(() {
      bool isSelected = controller.selectedType.value == type;
      bool isDark = Theme.of(context).brightness == Brightness.dark;
      return GestureDetector(
        onTap: () => controller.setType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.blue
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTargetExamSettings(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    return _buildGlassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Sector
          _buildDropdownLabel(context, "Exam Sector / Category"),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.examSectors.keys.map((sector) {
                return Obx(() {
                  bool isSelected = controller.selectedSector.value == sector;
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
          const SizedBox(height: 20),

          // Specific Exam
          _buildDropdownLabel(context, "Specific Goal"),
          const SizedBox(height: 8),
          _buildDropdownContainer(
            context,
            isDark,
            Obx(
              () => DropdownButton<String>(
                value: controller.selectedExam.value,
                isExpanded: true,
                dropdownColor: Theme.of(context).cardColor,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                items: controller.examSectors[controller.selectedSector.value]!
                    .map(
                      (exam) =>
                          DropdownMenuItem(value: exam, child: Text(exam)),
                    )
                    .toList(),
                onChanged: (val) => controller.setExam(val!),
              ),
            ),
          ),

          // Subject Focus (Only for Topic mode)
          Obx(() {
            if (controller.selectedType.value != 'Topic')
              return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildDropdownLabel(context, "Subject Focus"),
                const SizedBox(height: 8),
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
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            selectedColor: Colors.purple[700],
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
                                    ? Colors.purple
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
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContentSource(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    String title = "Resource Material";
    if (controller.selectedType.value == 'Topic')
      title = "Concept Topic";
    else if (controller.selectedType.value == 'Document')
      title = "Upload PDF/Text";

    return _buildGlassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownLabel(context, title),
          const SizedBox(height: 10),
          controller.selectedType.value == 'Topic'
              ? _buildDropdownContainer(
                  context,
                  isDark,
                  DropdownButton<String>(
                    value: controller.selectedTopic.value,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).cardColor,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.category_rounded,
                      color: Colors.blue,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    items: controller
                        .subjectTopics[controller.selectedSubject.value]!
                        .map(
                          (topic) => DropdownMenuItem(
                            value: topic,
                            child: Text(topic),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => controller.setTopic(val!),
                  ),
                )
              : (controller.selectedType.value == 'Document'
                    ? _buildDocumentSourceCard(context, controller)
                    : TextField(
                        controller: controller.inputController,
                        maxLines: 4,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? Colors.black26
                              : Colors.white.withOpacity(0.5),
                          hintText: controller.selectedType.value == 'Link'
                              ? "Paste URL here..."
                              : "Paste your text/notes here...",
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      )),
        ],
      ),
    );
  }

  Widget _buildSessionPreferences(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    return _buildGlassCard(
      context,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownLabel(context, "Language"),
                    const SizedBox(height: 8),
                    _buildDropdownContainer(
                      context,
                      isDark,
                      Obx(
                        () => DropdownButton<String>(
                          value: controller.selectedLanguage.value,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).cardColor,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.language,
                            color: Colors.blue,
                            size: 18,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: controller.languages
                              .map(
                                (l) =>
                                    DropdownMenuItem(value: l, child: Text(l)),
                              )
                              .toList(),
                          onChanged: (val) => controller.setLanguage(val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownLabel(context, "Difficulty"),
                    const SizedBox(height: 8),
                    _buildDropdownContainer(
                      context,
                      isDark,
                      Obx(
                        () => DropdownButton<String>(
                          value: controller.difficulty.value,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).cardColor,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.bar_chart_rounded,
                            color: Colors.blue,
                            size: 18,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: controller.difficulties
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          onChanged: (val) => controller.setDifficulty(val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                "Question Count",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Obx(
                () => Text(
                  "${controller.numQuestions.value.toInt()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
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
              label: controller.numQuestions.value.toString(),
              activeColor: Colors.blue,
              onChanged: (val) => controller.setNumQuestions(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, QuizController controller) {
    return GestureDetector(
      onTap: () {
        // Validation logic
        if (controller.selectedType.value == 'Link' ||
            controller.selectedType.value == 'Text') {
          if (controller.inputController.text.trim().isEmpty) {
            Get.snackbar(
              'Missing Content',
              'Please enter text or a link.',
              backgroundColor: Colors.orangeAccent,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
        }
        if (controller.selectedType.value == 'Document') {
          if (controller.pickedFilePath.value == null ||
              controller.pickedFilePath.value!.isEmpty) {
            Get.snackbar(
              'No Document',
              'Please upload a PDF.',
              backgroundColor: Colors.orangeAccent,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
        }

        controller.generateQuiz();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
      },
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "INITIATE MISSION",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. RECENT ACTIVITY ---

  Widget _buildRecentActivity(
    BuildContext context,
    HistoryController historyController,
  ) {
    return Obx(() {
      if (historyController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (historyController.history.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                "No past missions found.",
                style: TextStyle(color: Colors.grey.withOpacity(0.5)),
              ),
            ],
          ),
        );
      }

      // Show last 5 items horizontally
      final recentHistory = historyController.history.take(5).toList();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: recentHistory.map((res) {
            String date = DateFormat('MMM dd').format(res.date);
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreBadge(res.percentage),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    res.topic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res.subject,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildScoreBadge(double percentage) {
    Color color = percentage >= 80
        ? Colors.greenAccent
        : (percentage >= 50 ? Colors.orangeAccent : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "${percentage.toInt()}%",
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdownContainer(
    BuildContext context,
    bool isDark,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _buildDocumentSourceCard(
    BuildContext context,
    QuizController controller,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (controller.pickedFileName.value != null &&
            controller.pickedFileName.value!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.pickedFileName.value!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.pickedFilePath.value = '';
                    controller.pickedFileName.value = '';
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'txt'],
              );
              if (result != null) {
                controller.pickedFilePath.value = result.files.single.path!;
                controller.pickedFileName.value = result.files.single.name;
              }
            },
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  // style: BorderStyle.solid, // Default
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 32,
                    color: Colors.blue.withOpacity(0.8),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap to upload PDF",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
