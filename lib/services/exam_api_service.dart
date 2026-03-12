import 'package:test_project/core/constants/api_constants.dart';
import 'package:test_project/core/services/api_service.dart';
import 'package:test_project/models/exam_path_model.dart';

class ExamApiService {
  ExamApiService(this._apiService);

  final ApiService _apiService;

  Future<List<ExamPathModel>> getExamPaths() async {
    final response = await _apiService.get<dynamic>(ApiConstants.exams);
    final data = _toMap(response.data);
    final examsRaw = data['exams'];
    if (examsRaw is! List) {
      return const <ExamPathModel>[];
    }

    return examsRaw
        .whereType<Map>()
        .map((raw) => ExamPathModel(
              id: (raw['id'] ?? '').toString(),
              title: (raw['name'] ?? '').toString(),
              subtitle: (raw['description'] ?? '').toString(),
            ))
        .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
        .toList();
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
