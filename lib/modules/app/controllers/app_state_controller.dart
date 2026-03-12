import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:test_project/models/exam_path_model.dart';
import 'package:test_project/services/exam_api_service.dart';
import 'package:test_project/services/subject_api_service.dart';

class AppStateController extends GetxController {
  AppStateController(this._examApiService, this._subjectApiService);

  static const String _selectedExamIdKey = 'selected_exam_id';
  static const String _selectedExamTitleKey = 'selected_exam_title';
  static const String _selectedExamSubtitleKey = 'selected_exam_subtitle';

  final GetStorage _storage = GetStorage();
  final ExamApiService _examApiService;
  final SubjectApiService _subjectApiService;

  final RxList<ExamPathModel> examPaths = <ExamPathModel>[].obs;
  final RxBool isExamPathsLoading = false.obs;
  final RxString examPathsError = ''.obs;

  final RxList<String> subjects = <String>[].obs;
  final RxBool isSubjectsLoading = false.obs;
  final RxString subjectsError = ''.obs;
  final List<String> difficulties = const ['easy', 'medium', 'hard'];

  final Rxn<ExamPathModel> selectedPath = Rxn<ExamPathModel>();
  final RxString selectedSubject = 'math'.obs;
  final RxString selectedDifficulty = 'easy'.obs;
  final RxInt dailyTarget = 10.obs;
  final RxInt todayAnswered = 0.obs;

  bool get hasSelectedPath => selectedPath.value != null;

  String get activeExamId {
    final selectedId = selectedPath.value?.id;
    if (selectedId != null && selectedId.isNotEmpty) {
      return selectedId;
    }
    if (examPaths.isNotEmpty) {
      return examPaths.first.id;
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSelectedPath();
    ever<ExamPathModel?>(selectedPath, (_) => fetchSubjectsForSelectedExam());
    fetchExamPaths();
  }

  Future<void> fetchExamPaths() async {
    isExamPathsLoading.value = true;
    examPathsError.value = '';
    try {
      final paths = await _examApiService.getExamPaths();
      examPaths.assignAll(paths);
      _syncSelectedPathWithFetchedData();
      await fetchSubjectsForSelectedExam();
      if (paths.isEmpty) {
        examPathsError.value = 'No exams found from backend';
      }
    } catch (_) {
      examPaths.clear();
      examPathsError.value =
          'Cannot connect to backend. Start server at http://localhost:4000';
    } finally {
      isExamPathsLoading.value = false;
    }
  }

  void selectPath(ExamPathModel path) {
    selectedPath.value = path;
    _storage.write(_selectedExamIdKey, path.id);
    _storage.write(_selectedExamTitleKey, path.title);
    _storage.write(_selectedExamSubtitleKey, path.subtitle);
  }

  void clearPath() {
    selectedPath.value = null;
    _storage.remove(_selectedExamIdKey);
    _storage.remove(_selectedExamTitleKey);
    _storage.remove(_selectedExamSubtitleKey);
  }

  void setSubject(String subjectId) {
    selectedSubject.value = subjectId;
  }

  void setDifficulty(String difficulty) {
    selectedDifficulty.value = difficulty;
  }

  void incrementTodayAnswered() {
    todayAnswered.value++;
  }

  void _restoreSelectedPath() {
    final savedId = _storage.read<String>(_selectedExamIdKey);
    final savedTitle = _storage.read<String>(_selectedExamTitleKey);
    final savedSubtitle = _storage.read<String>(_selectedExamSubtitleKey);

    if (savedId == null || savedId.trim().isEmpty) {
      return;
    }

    final matched = examPaths.where((item) => item.id == savedId).toList();
    if (matched.isNotEmpty) {
      selectedPath.value = matched.first;
      return;
    }

    if ((savedTitle ?? '').trim().isEmpty) {
      return;
    }

    selectedPath.value = ExamPathModel(
      id: savedId,
      title: savedTitle!.trim(),
      subtitle: (savedSubtitle ?? '').trim(),
    );
  }

  void _syncSelectedPathWithFetchedData() {
    final current = selectedPath.value;
    if (current == null) {
      return;
    }

    final matched = examPaths.where((item) => item.id == current.id).toList();
    if (matched.isEmpty) {
      clearPath();
      return;
    }

    selectedPath.value = matched.first;
  }

  Future<void> fetchSubjectsForSelectedExam() async {
    final examId = activeExamId;
    if (examId.isEmpty) {
      subjects.clear();
      subjectsError.value = '';
      return;
    }

    isSubjectsLoading.value = true;
    subjectsError.value = '';
    try {
      final fetchedSubjects = await _subjectApiService.getSubjectsByExamId(examId);
      subjects.assignAll(fetchedSubjects);
      if (subjects.isEmpty) {
        selectedSubject.value = '';
        subjectsError.value = 'No subjects found for selected exam';
      } else if (!subjects.contains(selectedSubject.value)) {
        selectedSubject.value = subjects.first;
      }
    } catch (_) {
      subjects.clear();
      selectedSubject.value = '';
      subjectsError.value =
          'Cannot load subjects. Ensure backend is running and exam has subjects.';
    } finally {
      isSubjectsLoading.value = false;
    }
  }
}
