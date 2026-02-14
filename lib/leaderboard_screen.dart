import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'controllers/history_controller.dart';
import 'models/history_model.dart';
import 'painters/confetti_painter.dart'; // Import ConfettiPainter

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryController controller = Get.find<HistoryController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Refresh history to ensure latest scores
    controller.loadHistory();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "HALL OF FAME",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E2C),
                        const Color(0xFF0F0F1A),
                        const Color(0xFF000000),
                      ]
                    : [
                        const Color(0xFFF0F4F8),
                        const Color(0xFFE1E8ED),
                        const Color(0xFFFFFFFF),
                      ],
              ),
            ),
          ),

          // Confetti for Celebration Atmosphere
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(painter: ConfettiPainter()),
            ),
          ),

          // Confetti for Celebration Atmosphere
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(painter: ConfettiPainter()),
            ),
          ),

          Obx(() {
            final topScores = controller.topScores;
            if (topScores.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No champions yet!",
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text("BE THE FIRST"),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                ),
                // Podium for Top 3 with Entrance Animation
                if (topScores.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Rank 2 (Left)
                        if (topScores.length > 1)
                          Positioned(
                            left: 20,
                            bottom: 0,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 300, end: 0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, value),
                                  child: child,
                                );
                              },
                              child: _buildPodiumStep(
                                context,
                                topScores[1],
                                2,
                                160,
                                Colors.grey.shade400,
                              ),
                            ),
                          ),
                        // Rank 3 (Right)
                        if (topScores.length > 2)
                          Positioned(
                            right: 20,
                            bottom: 0,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 300, end: 0),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, value),
                                  child: child,
                                );
                              },
                              child: _buildPodiumStep(
                                context,
                                topScores[2],
                                3,
                                130,
                                const Color(0xFFCD7F32),
                              ),
                            ),
                          ),
                        // Rank 1 (Center) - Gold
                        Positioned(
                          bottom: 0,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 300, end: 0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, value),
                                child: child,
                              );
                            },
                            child: _buildPodiumStep(
                              context,
                              topScores[0],
                              1,
                              210,
                              const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Remaining List with Glassmorphism
                if (topScores.length > 3)
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 100 * value),
                          child: Opacity(opacity: 1 - value, child: child),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withOpacity(isDark ? 0.6 : 0.8),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: topScores.length > 3
                                  ? topScores.length - 3
                                  : 0,
                              separatorBuilder: (context, index) => Divider(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                              ),
                              itemBuilder: (context, index) {
                                final realIndex = index + 3;
                                final result = topScores[realIndex];
                                final accuracy = result.percentage;
                                final timeAgo = _timeAgo(result.date);
                                final isExpanded =
                                    false.obs; // Local state for expansion

                                return Obx(
                                  () => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isExpanded.value
                                          ? Theme.of(
                                              context,
                                            ).cardColor.withOpacity(0.5)
                                          : Theme.of(
                                              context,
                                            ).cardColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isExpanded.value
                                            ? Colors.blue.withOpacity(0.3)
                                            : Theme.of(
                                                context,
                                              ).dividerColor.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          onTap: () => isExpanded.value =
                                              !isExpanded.value,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                          leading: Container(
                                            width: 40,
                                            height: 40,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).scaffoldBackgroundColor,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: _getRankColor(
                                                  realIndex + 1,
                                                ).withOpacity(0.5),
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              "#${realIndex + 1}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: _getRankColor(
                                                  realIndex + 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  result.topic,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (accuracy >= 90)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 4,
                                                  ),
                                                  child: Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            "${result.subject} • $timeAgo",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "${result.score}/${result.totalQuestions}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: _getPerformanceColor(
                                                    accuracy,
                                                  ),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                "${accuracy.toStringAsFixed(0)}%",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getPerformanceColor(
                                                    accuracy,
                                                  ).withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Expanded Details Section
                                        if (isExpanded.value)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              16,
                                            ),
                                            child: Column(
                                              children: [
                                                Divider(
                                                  color: Theme.of(context)
                                                      .dividerColor
                                                      .withOpacity(0.1),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    _buildDetailItem(
                                                      context,
                                                      Icons
                                                          .check_circle_outline,
                                                      "Correct",
                                                      "${result.score}",
                                                      Colors.green,
                                                    ),
                                                    _buildDetailItem(
                                                      context,
                                                      Icons.cancel_outlined,
                                                      "Missed",
                                                      "${result.totalQuestions - result.score}",
                                                      Colors.redAccent,
                                                    ),
                                                    _buildDetailItem(
                                                      context,
                                                      Icons.speed,
                                                      "Avg Time",
                                                      "~45s", // Placeholder until time tracking provided
                                                      Colors.blue,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getPerformanceColor(
                                                      accuracy,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          _getPerformanceColor(
                                                            accuracy,
                                                          ).withOpacity(0.2),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _getPerformanceTag(
                                                      accuracy,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _getPerformanceColor(
                                                            accuracy,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Helper Methods
  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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

  String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()}y ago";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey.shade500;
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 90) return Colors.greenAccent;
    if (percentage >= 70) return Colors.blueAccent;
    if (percentage >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getPerformanceTag(double percentage) {
    if (percentage >= 100) return "LEGENDARY PERFORMANCE 🏆";
    if (percentage >= 90) return "EXCELLENT WORK 🌟";
    if (percentage >= 75) return "GREAT JOB 🚀";
    if (percentage >= 50) return "GOOD EFFORT 👍";
    return "NEEDS PRACTICE 📚";
  }

  Widget _buildPodiumStep(
    BuildContext context,
    QuizResult result,
    int rank,
    double height,
    Color color,
  ) {
    bool isFirst = rank == 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar / Icon with Glow
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: isFirst ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 35 : 28,
            backgroundColor: Theme.of(context).cardColor,
            child: Icon(Icons.person, size: isFirst ? 30 : 24, color: color),
          ),
        ),
        const SizedBox(height: 8),

        // Name & Score Tag
        Container(
          width: isFirst ? 110 : 90,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Text(
                result.topic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${result.score} pts",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // The Glassmorphic Step
        Container(
          width: isFirst ? 120 : 100,
          height: height - 60, // Adjust based on avatar/text height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.9), color.withOpacity(0.3)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            "$rank",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
