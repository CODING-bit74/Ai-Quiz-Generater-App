import 'package:test_project/core/constants/api_constants.dart';
import 'package:test_project/core/services/api_service.dart';
import 'package:test_project/models/user_progress_model.dart';

class ProgressApiService {
  ProgressApiService(this._apiService);

  final ApiService _apiService;

  Future<UserProgressModel> getUserProgress({
    required String examId,
    required String subjectId,
    required String difficulty,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.progress,
      queryParameters: {
        'examId': examId,
        'subjectId': subjectId,
        'difficulty': difficulty,
      },
    );

    final data = _toMap(response.data);
    final rawProgress = data['progress'];
    if (rawProgress is Map) {
      return UserProgressModel.fromJson(
        rawProgress.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return const UserProgressModel(totalSolved: 0, correctAnswers: 0);
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
