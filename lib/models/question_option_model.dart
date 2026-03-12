class QuestionOptionModel {
  const QuestionOptionModel({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}
