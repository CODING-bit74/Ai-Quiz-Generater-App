class SubmitAnswerResultModel {
  const SubmitAnswerResultModel({
    required this.correct,
    required this.explanation,
  });

  final bool correct;
  final String explanation;

  factory SubmitAnswerResultModel.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResultModel(
      correct: json['correct'] == true,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}
