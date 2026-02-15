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
}
