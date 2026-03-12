class UserProgressModel {
  const UserProgressModel({
    required this.totalSolved,
    required this.correctAnswers,
  });

  final int totalSolved;
  final int correctAnswers;

  double get accuracy {
    if (totalSolved == 0) {
      return 0;
    }
    return correctAnswers / totalSolved;
  }

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      totalSolved: (json['totalSolved'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
    );
  }
}
