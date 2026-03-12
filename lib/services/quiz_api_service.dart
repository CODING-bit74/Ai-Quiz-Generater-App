import 'package:test_project/core/constants/api_constants.dart';
import 'package:test_project/core/services/api_service.dart';
import 'package:test_project/models/quiz_question_model.dart';
import 'package:test_project/models/submit_answer_result_model.dart';

class QuizApiService {
  QuizApiService(this._apiService);

  final ApiService _apiService;

  Future<QuizQuestionModel?> getNextQuestion({
    required String examId,
    required String subjectId,
    required String difficulty,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.quizNext,
      queryParameters: {
        'examId': examId,
        'subjectId': subjectId,
        'difficulty': difficulty,
      },
    );

    if (response.statusCode == 204 || response.data == null) {
      return null;
    }

    final data = _toMap(response.data);
    final questionRaw = data['question'];
    if (questionRaw is! Map) {
      return null;
    }

    return QuizQuestionModel.fromJson(
      questionRaw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<SubmitAnswerResultModel> submitAnswer({
    required int questionIndex,
    required List<String> selectedOptions,
    required String examId,
    required String subjectId,
    required String difficulty,
  }) async {
    final response = await _apiService.post<dynamic>(
      ApiConstants.quizSubmit,
      data: {
        'questionIndex': questionIndex,
        'selectedOptions': selectedOptions,
        'examId': examId,
        'subjectId': subjectId,
        'difficulty': difficulty,
      },
    );

    return SubmitAnswerResultModel.fromJson(_toMap(response.data));
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
