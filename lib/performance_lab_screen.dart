import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/history_controller.dart';
import 'controllers/quiz_controller.dart';
import 'package:intl/intl.dart';

class PerformanceLabScreen extends StatelessWidget {
  const PerformanceLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryController historyController = Get.find();
    final QuizController quizController = Get.find();
    // final isDark = Theme.of(context).brightness == Brightness.dark; // Removed as per instruction

    return Scaffold(
      body: Stack(
        children: [
          // Background atmospheric orbs (Visual consistency)
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowingOrb(Colors.blue.withOpacity(0.2), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGlowingOrb(
              const Color(0xFF6366F1).withOpacity(0.2),
              250,
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Region
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "PERFORMANCE VAULT",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your AI Learning\nDashboard",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats Overview (Glass Cards)
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (historyController.history.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Mastery Ring Chart
                              _buildMasteryRing(
                                context,
                                historyController.averageScore,
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildStatCard(
                                      context,
                                      "Quizzes",
                                      historyController.history.length
                                          .toString(),
                                      Icons.auto_awesome_motion_rounded,
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatCard(
                                      context,
                                      "Accuracy",
                                      "${historyController.averageScore.toStringAsFixed(1)}%",
                                      Icons.grade_rounded,
                                      const Color(0xFF10B981),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  }),
                ),

                // Weak Areas & AI Re-Challenge
                SliverToBoxAdapter(
                  child: Obx(() {
                    final weak = historyController.weakSubjects;
                    if (weak.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildGlassSection(
                        context,
                        title: "Weak Subject Analysis",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Based on your performance, you may need practice in:",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: weak.map((subject) {
                                return _buildReChallengeChip(
                                  context,
                                  quizController,
                                  subject,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                // History List
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Text(
                      "ACTIVITY LOG",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),

                Obx(() {
                  if (historyController.isLoading.value) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (historyController.history.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No quiz history yet. Start learning!",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final res = historyController.history[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        curve: Curves.easeOutCubic,
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - opacity)),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: _buildHistoryItem(
                            context,
                            res,
                            historyController,
                          ),
                        ),
                      );
                    }, childCount: historyController.history.length),
                  );
                }),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildReChallengeChip(
    BuildContext context,
    QuizController quiz,
    String subject,
  ) {
    return GestureDetector(
      onTap: () {
        quiz.startReChallenge(subject);
        Get.back(); // Return to master lab
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flash_on_rounded,
              size: 16,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Text(
              "IMPROVE $subject",
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryRing(BuildContext context, double score) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 80
                    ? const Color(0xFF10B981)
                    : (score >= 50 ? Colors.orange : Colors.redAccent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${score.toInt()}%",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                "MASTERY",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    dynamic res,
    HistoryController controller,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String formattedDate = DateFormat('MMM dd, hh:mm a').format(res.date);

    // Dynamic icon based on subject
    IconData subjectIcon = Icons.subject_rounded;
    Color subjectColor = Colors.blue;
    if (res.subject.contains('Quant')) {
      subjectIcon = Icons.calculate_rounded;
      subjectColor = Colors.orange;
    } else if (res.subject.contains('Reasoning')) {
      subjectIcon = Icons.psychology_rounded;
      subjectColor = Colors.purple;
    } else if (res.subject.contains('English')) {
      subjectIcon = Icons.translate_rounded;
      subjectColor = Colors.blue;
    } else if (res.subject.contains('GA/GS')) {
      subjectIcon = Icons.public_rounded;
      subjectColor = Colors.green;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 12),
            leading: _buildScoreRing(res.percentage),
            title: Text(
              res.topic,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(subjectIcon, size: 10, color: subjectColor),
                const SizedBox(width: 4),
                Text(
                  res.subject,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subjectColor,
                  ),
                ),
                Text(
                  " • $formattedDate",
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _confirmDelete(context, controller, res.id!),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.redAccent.withOpacity(0.5),
              ),
            ),
            children: [_buildExpandedDetails(context, res)],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    HistoryController controller,
    int id,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.redAccent.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            const Text(
              "Delete Record?",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          "This action cannot be undone. You will lose this quiz history forever.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "CANCEL",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              controller.deleteResult(id);
              Get.back();
              Get.snackbar(
                "Deleted",
                "Record removed successfully.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                colorText: Colors.redAccent,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "DELETE",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(BuildContext context, dynamic res) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow("Exam", res.examName),
          _buildDetailRow("Total Questions", res.totalQuestions.toString()),
          _buildDetailRow("Score", "${res.percentage.toInt()}%"),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final QuizController quiz = Get.find();
              quiz.startTopicReChallenge(res.topic, res.subject, res.examName);
              Get.back(); // Close lab to show playground
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text("RE-PRACTICE THIS TOPIC"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing(double percentage) {
    Color color = percentage >= 80
        ? const Color(0xFF10B981)
        : (percentage >= 50 ? Colors.orange : Colors.redAccent);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(
          "${percentage.toInt()}%",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
