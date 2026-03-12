import 'package:get/get.dart';
import 'package:test_project/models/user_progress_model.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/services/progress_api_service.dart';

class ProgressController extends GetxController {
  ProgressController(this._progressApiService, this._appStateController);

  final ProgressApiService _progressApiService;
  final AppStateController _appStateController;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserProgressModel> progress =
      const UserProgressModel(totalSolved: 0, correctAnswers: 0).obs;

  @override
  void onInit() {
    super.onInit();
    everAll([
      _appStateController.selectedPath,
      _appStateController.selectedSubject,
      _appStateController.selectedDifficulty,
    ], (_) {
      fetchProgress();
    });
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    if (!_appStateController.hasSelectedPath) {
      progress.value = const UserProgressModel(totalSolved: 0, correctAnswers: 0);
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final value = await _progressApiService.getUserProgress(
        examId: _appStateController.activeExamId,
        subjectId: _appStateController.selectedSubject.value,
        difficulty: _appStateController.selectedDifficulty.value,
      );
      progress.value = value;
    } catch (error) {
      errorMessage.value = _extractErrorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  String _extractErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('SocketException')) {
      return 'Cannot connect to backend. Start server at http://localhost:4000';
    }
    return 'Failed to load progress';
  }
}
