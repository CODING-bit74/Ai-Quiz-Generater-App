import 'package:get/get.dart';
import '../models/history_model.dart';
import '../services/database_service.dart';

class HistoryController extends GetxController {
  var history = <QuizResult>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  // Fetch all results from the database
  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final results = await DatabaseService.instance.getAllResults();
      history.assignAll(results);
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a specific result
  Future<void> deleteResult(int id) async {
    await DatabaseService.instance.deleteResult(id);
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
}
