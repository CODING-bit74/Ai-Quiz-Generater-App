import 'package:test_project/core/constants/api_constants.dart';
import 'package:test_project/core/services/api_service.dart';

class SubjectApiService {
  SubjectApiService(this._apiService);

  final ApiService _apiService;

  Future<List<String>> getSubjectsByExamId(String examId) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.subjects,
      queryParameters: {'examId': examId},
    );

    final data = _toMap(response.data);
    final subjectsRaw = data['subjects'];
    if (subjectsRaw is! List) {
      return const <String>[];
    }

    return subjectsRaw
        .whereType<Map>()
        .map((raw) => (raw['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
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
