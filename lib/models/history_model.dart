import 'dart:convert';

class QuizResult {
  final int? id;
  final String topic;
  final String examName;
  final String subject;
  final int score;
  final int totalQuestions;
  final DateTime date;
  final String quizDataJson; // Stores the full quiz JSON for re-reviewing

  QuizResult({
    this.id,
    required this.topic,
    required this.examName,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.date,
    required this.quizDataJson,
  });

  // Convert a QuizResult into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'examName': examName,
      'subject': subject,
      'score': score,
      'totalQuestions': totalQuestions,
      'date': date.toIso8601String(),
      'quizDataJson': quizDataJson,
    };
  }

  // Extract a QuizResult object from a Map.
  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'],
      topic: map['topic'],
      examName: map['examName'],
      subject: map['subject'],
      score: map['score'],
      totalQuestions: map['totalQuestions'],
      date: DateTime.parse(map['date']),
      quizDataJson: map['quizDataJson'],
    );
  }

  // Helper to get raw quiz data as list of maps
  List<dynamic> getQuizData() {
    return jsonDecode(quizDataJson);
  }

  // Calculate percentage
  double get percentage =>
      (totalQuestions > 0) ? (score / totalQuestions) * 100 : 0.0;
}
