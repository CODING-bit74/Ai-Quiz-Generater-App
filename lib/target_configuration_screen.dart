import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'screens/credit_history_screen.dart';
import 'screens/earn_credits_screen.dart';
import 'package:intl/intl.dart';
import 'controllers/quiz_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/economy_controller.dart';
import 'quiz_screen.dart';
import 'performance_lab_screen.dart';
import 'services/auth_service.dart';
import 'welcome_screen.dart';

import 'youtube_input_screen.dart';
import 'leaderboard_screen.dart';
import 'screens/auth/goal_selection_screen.dart';
import 'screens/syllabus_screen.dart';

class TargetConfigurationScreen extends StatelessWidget {
  const TargetConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final QuizController controller = Get.find<QuizController>();

    // Onboarding Check: Redirect new users if no goal is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isGoalSet.value) {
        Get.to(() => const GoalSelectionScreen());
      }
    });
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
                      _buildVideoStudioBanner(context),
                      const SizedBox(height: 12),
                      _buildHallOfFameBanner(context),
                      const SizedBox(height: 20),
                      _buildInputMethodSelector(context, controller, isDark),
                      const SizedBox(height: 24),
                      _buildTargetExamSettings(context, controller, isDark),
                      const SizedBox(height: 16),
                      _buildSubjectSelector(context, controller, isDark),
                      const SizedBox(height: 16),
                      Obx(
                        () => _buildContentSource(context, controller, isDark),
                      ),
                      const SizedBox(height: 16),

                      // 4. AI TUTOR SELECTOR (NEW)
                      _buildSectionHeader(
                        context,
                        "SELECT YOUR AI TUTOR",
                        Icons.psychology_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildAgentSelector(context, controller, isDark),
                      const SizedBox(height: 24),

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
          // Replaced Back Button with Dashboard Icon since this is the Home Screen
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.blue,
              size: 20,
            ),
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
          Row(
            children: [
              IconButton(
                onPressed: () => Get.to(() => const PerformanceLabScreen()),
                icon: Icon(
                  Icons.insights_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: "Open Performance Vault",
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent.withOpacity(0.8),
                ),
                tooltip: "Logout",
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withOpacity(0.85)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.power_settings_new_rounded,
                            size: 40,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Abort Mission?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Are you sure you want to terminate your current session at HQ?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Get.back(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "CANCEL",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await Get.find<AuthService>().signOut();
                                  Get.offAll(() => const WelcomeScreen());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "LOGOUT",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      barrierColor: Colors.black.withOpacity(0.5),
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
                  Get.find<QuizController>().currentAvatarPath,
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
                  const SizedBox(height: 4),
                  Obx(() {
                    final auth = Get.find<AuthService>();
                    final user = auth.currentUser.value;
                    final metadata = user?.userMetadata;
                    String displayName = "Guest Commander";

                    if (metadata != null && metadata['full_name'] != null) {
                      displayName = metadata['full_name'];
                    } else if (user?.email != null) {
                      displayName = user!.email!.split('@')[0].toUpperCase();
                    }

                    // Get Controller for Active Target
                    final quizController = Get.find<QuizController>();
                    final targetExam = quizController.selectedExam.value;

                    // Get Progress for this Target
                    final rankTitle = historyController.getTargetRank(
                      targetExam,
                    );
                    final progress = historyController.getTargetRankProgress(
                      targetExam,
                    );
                    final missionsLeft = historyController
                        .getTargetMissionsToNextRank(targetExam);

                    Color rankColor = Colors.blueGrey;
                    if (rankTitle == "LEGEND")
                      rankColor = Colors.amber;
                    else if (rankTitle == "MASTER")
                      rankColor = Colors.purpleAccent;
                    else if (rankTitle == "COMMANDER")
                      rankColor = Colors.blue;
                    else if (rankTitle == "OFFICER")
                      rankColor = Colors.cyan;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName, // Dynamic Name
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rankColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: rankColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                rankTitle,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: rankColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Active Target Display
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.ads_click_rounded,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                "${quizController.selectedSector.value} • ${targetExam}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Progress Bar
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  rankColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              missionsLeft > 0
                                  ? "$missionsLeft missions to promotion"
                                  : "Max Rank Achieved",
                              style: TextStyle(
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),

                        // --- DAILY MISSION UPDATE ---
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "DAILY MISSION", // Shortened text
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department,
                                          size: 10,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${historyController.dailyStreak} Day Streak",
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            (historyController
                                                        .quizzesDoneToday /
                                                    3)
                                                .clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.05),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.greenAccent,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${historyController.quizzesDoneToday}/3",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                historyController.quizzesDoneToday >= 3
                                    ? "Daily Target Achieved! 🎉"
                                    : "Complete 3 quizzes to maintain streak",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  // Mini Stats
                  // Mini Stats - Scrollable to prevent overflow
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _buildMiniStat(context, "$missionCount", "Missions"),
                        const SizedBox(width: 16),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () =>
                              Get.to(() => const CreditHistoryScreen()),
                          child: Container(
                            color: Colors.transparent,
                            child: Obx(() {
                              final EconomyController economyController =
                                  Get.find();
                              return _buildMiniStat(
                                context,
                                "${economyController.credits.value}",
                                "Credits",
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Get.to(() => EarnCreditsScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amberAccent,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.black,
                            ),
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
          _buildTypeTab(
            context,
            controller,
            'PYQ Search',
            Icons.manage_search_rounded,
          ),
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
          const SizedBox(height: 16),
          // View Intelligence Button
          InkWell(
            onTap: () => Get.to(() => const SyllabusScreen()),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "VIEW EXAM INTELLIGENCE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    return Obx(() {
      if (controller.selectedType.value != 'Topic') {
        return const SizedBox.shrink();
      }

      return _buildGlassCard(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownLabel(context, "Subject Focus"),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: controller.availableSubjects.map((subject) {
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
        ),
      );
    });
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
                              : "Enter topic/keyword for PYQ Search...",
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
    final EconomyController economyController = Get.find();

    return Obx(() {
      // Calculate Cost dynamically
      int cost = controller.selectedType.value == 'Topic' ? 10 : 20;

      return InkWell(
        onTap: () async {
          if (controller.isLoading.value) return;

          // 1. Validate Credits
          bool success = await economyController.deductCredits(cost);
          if (!success) return;

          // 2. Validate Inputs
          if (controller.selectedType.value == 'Link' ||
              controller.selectedType.value == 'PYQ Search') {
            if (controller.inputController.text.trim().isEmpty) {
              Get.snackbar(
                'Missing Content',
                'Please enter a topic or a link.',
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
          if (controller.selectedType.value == 'Topic' &&
              controller.selectedTopic.value.isEmpty) {
            Get.snackbar("Error", "Please select or enter a topic");
            return;
          }

          // 3. Generate
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "INITIATE MISSION (-$cost 💎)",
                style: const TextStyle(
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
    });
  }

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

  Widget _buildVideoStudioBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const YouTubeInputScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.redAccent.shade700, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Video Studio",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Generate quizzes directly from YouTube videos",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHallOfFameBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const LeaderboardScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.amber.shade700, Colors.amber],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hall of Fame",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Check the top ranked commanders",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentSelector(
    BuildContext context,
    QuizController controller,
    bool isDark,
  ) {
    final agents = [
      {
        'name': 'Professor',
        'icon': '👨‍🏫',
        'desc': 'Balanced & Academic',
        'color': Colors.blue,
      },
      {
        'name': 'Drill Sergeant',
        'icon': '🎖️',
        'desc': 'Strict & Fast-Paced',
        'color': Colors.red,
      },
      {
        'name': 'Study Buddy',
        'icon': '🤝',
        'desc': 'Fun & Encouraging',
        'color': Colors.green,
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: agents.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final agent = agents[index];
          final name = agent['name'] as String;
          final color = agent['color'] as Color;
          final desc = agent['desc'] as String;
          final icon = agent['icon'] as String;

          return Obx(() {
            final isSelected = controller.selectedAgentPersona.value == name;
            return InkWell(
              onTap: () => controller.selectedAgentPersona.value = name,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark ? Colors.white10 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
