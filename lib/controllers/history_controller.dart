import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/history_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class HistoryController extends GetxController {
  var history = <QuizResult>[].obs;
  var isLoading = false.obs;

  // User Profile Stats
  // User Profile Stats - Rank logic handles the rest

  @override
  void onInit() {
    super.onInit();
    loadHistory();

    // Listen for Auth Changes to refresh history for new users
    ever(AuthService.to.currentUser, (_) {
      debugPrint(
        "HistoryController: Auth state changed, refreshing mission history...",
      );
      loadHistory();
    });
  }

  // Fetch all results from the database
  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final userId = Get.find<AuthService>().userId;
      // Use a timeout to prevent indefinite hangs
      final results = await DatabaseService.instance
          .getAllResults(userId: userId)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint("History loading timed out.");
              return [];
            },
          );
      history.assignAll(results);
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a specific result
  Future<void> deleteResult(String id) async {
    await DatabaseService.instance.deleteResult(id);
    loadHistory();
  }

  // Clear all history
  Future<void> resetHistory() async {
    await DatabaseService.instance.clearAllResults();
    loadHistory();
  }

  // Calculate analytics
  double get averageScore {
    if (history.isEmpty) return 0.0;
    double total = history.fold(0, (sum, item) => sum + item.percentage);
    return total / history.length;
  }

  // Identify weak subjects (percentage < 60)
  List<String> get weakSubjects {
    Map<String, List<double>> subjectScores = {};
    for (var res in history) {
      subjectScores.putIfAbsent(res.subject, () => []).add(res.percentage);
    }

    List<String> weak = [];
    subjectScores.forEach((subject, scores) {
      double avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < 70) {
        // Using 70% as the threshold for "weak"
        weak.add(subject);
      }
    });

    return weak;
  }

  // Performance stats for charts
  Map<String, double> get subjectMastery {
    Map<String, List<double>> subjectScores = {};
    for (var res in history) {
      subjectScores.putIfAbsent(res.subject, () => []).add(res.percentage);
    }

    Map<String, double> mastery = {};
    subjectScores.forEach((subject, scores) {
      mastery[subject] = scores.reduce((a, b) => a + b) / scores.length;
    });
    return mastery;
  }

  // Rank Logic
  String get currentRank {
    int count = history.length;
    if (count > 50) return "LEGEND";
    if (count > 30) return "MASTER";
    if (count > 15) return "COMMANDER";
    if (count > 5) return "OFFICER";
    return "GOVPrpeAi";
  }

  String get nextRankTitle {
    int count = history.length;
    if (count > 50) return "MAX RANK";
    if (count > 30) return "LEGEND";
    if (count > 15) return "MASTER";
    if (count > 5) return "COMMANDER";
    return "OFFICER";
  }

  int get missionsToNextRank {
    int count = history.length;
    if (count > 50) return 0;
    if (count > 30) return 51 - count;
    if (count > 15) return 31 - count;
    if (count > 5) return 16 - count;
    return 6 - count;
  }

  double get rankProgress {
    int count = history.length;
    if (count > 50) return 1.0;

    int lowerBound = 0;
    int upperBound = 6;

    if (count > 30) {
      lowerBound = 30;
      upperBound = 51;
    } else if (count > 15) {
      lowerBound = 15;
      upperBound = 31;
    } else if (count > 5) {
      lowerBound = 5;
      upperBound = 16;
    }

    return (count - lowerBound) / (upperBound - lowerBound);
  }

  // Leaderboard Logic: Get top 20 results sorted by score
  List<QuizResult> get topScores {
    // Create a copy to avoid modifying the original observable list in place if using sort directly
    List<QuizResult> sortedHistory = List.from(history);

    // Sort by Score Descending, then by Date Descending (newest first for ties)
    sortedHistory.sort((a, b) {
      int scoreComp = b.score.compareTo(a.score);
      if (scoreComp != 0) return scoreComp;
      return b.date.compareTo(a.date);
    });

    // Return top 20
    return sortedHistory.take(20).toList();
  }

  // --- TARGET SPECIFIC LOGIC ---

  List<QuizResult> getTargetSpecificHistory(String targetExamName) {
    return history.where((r) => r.examName == targetExamName).toList();
  }

  String getTargetRank(String targetExamName) {
    int count = getTargetSpecificHistory(targetExamName).length;
    if (count > 50) return "LEGEND";
    if (count > 30) return "MASTER";
    if (count > 15) return "COMMANDER";
    if (count > 5) return "OFFICER";
    return "ROOKIE";
  }

  double getTargetRankProgress(String targetExamName) {
    int count = getTargetSpecificHistory(targetExamName).length;
    if (count > 50) return 1.0;

    int lowerBound = 0;
    int upperBound = 6;

    if (count > 30) {
      lowerBound = 30;
      upperBound = 51;
    } else if (count > 15) {
      lowerBound = 15;
      upperBound = 31;
    } else if (count > 5) {
      lowerBound = 5;
      upperBound = 16;
    }

    return (count - lowerBound) / (upperBound - lowerBound);
  }

  int getTargetMissionsToNextRank(String targetExamName) {
    int count = getTargetSpecificHistory(targetExamName).length;
    if (count > 50) return 0;
    if (count > 30) return 51 - count;
    if (count > 15) return 31 - count;
    if (count > 5) return 16 - count;
    return 6 - count;
  }

  // --- DAILY MISSION LOGIC ---

  int get quizzesDoneToday {
    final now = DateTime.now();
    return history.where((r) {
      return r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day;
    }).length;
  }

  int get dailyStreak {
    if (history.isEmpty) return 0;

    // Sort by date descending
    final sorted = List<QuizResult>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final now = DateTime.now();

    // Reset time components for accurate date comparison
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    // Check if we did a quiz today
    bool didQuizToday = sorted.any(
      (r) =>
          r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day,
    );

    // If we haven't done a quiz today, the streak continues from yesterday
    if (!didQuizToday) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    Set<String> processedDates = {};

    for (var r in sorted) {
      // Create a date-only string key to handle multiple quizzes on same day
      final dateKey = "${r.date.year}-${r.date.month}-${r.date.day}";

      if (processedDates.contains(dateKey)) continue;
      processedDates.add(dateKey);

      final quizDate = DateTime(r.date.year, r.date.month, r.date.day);

      // If quiz date matches the expected streak date
      if (quizDate.isAtSameMomentAs(currentDate)) {
        streak++;
        // Move expected date back by one day
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (quizDate.isBefore(currentDate)) {
        // Gap found, streak ends
        break;
      }
      // If quiz is *after* current date (shouldn't happen with sorted list but safe to ignore), continue
    }

    return streak;
  }
}
