import 'package:test_project/models/question_option_model.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.questionIndex,
    required this.text,
    required this.options,
  });

  final int questionIndex;
  final String text;
  final List<QuestionOptionModel> options;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final optionItems = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((option) => QuestionOptionModel.fromJson(
              option.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();

    return QuizQuestionModel(
      questionIndex: (json['questionIndex'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
      options: optionItems,
    );
  }
}
