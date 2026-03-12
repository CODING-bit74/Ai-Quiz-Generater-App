import 'package:get/get.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/routes/app_routes.dart';

class PathSelectionController extends GetxController {
  PathSelectionController(this._appStateController);

  final AppStateController _appStateController;
  final RxString selectedPathId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    selectedPathId.value = _appStateController.selectedPath.value?.id ?? '';
  }

  void selectPath(String pathId) {
    selectedPathId.value = pathId;
  }

  void continueToApp() {
    if (_appStateController.isExamPathsLoading.value) {
      Get.snackbar('Please wait', 'Exam paths are loading.');
      return;
    }

    if (_appStateController.examPaths.isEmpty) {
      Get.snackbar('No paths', 'Exam paths are not available right now.');
      return;
    }

    final selected = _appStateController.examPaths
        .where((item) => item.id == selectedPathId.value)
        .toList();
    if (selected.isEmpty) {
      Get.snackbar('Select path', 'Choose one exam path to continue.');
      return;
    }

    _appStateController.selectPath(selected.first);
    Get.offAllNamed(AppRoutes.appShell);
  }
}
