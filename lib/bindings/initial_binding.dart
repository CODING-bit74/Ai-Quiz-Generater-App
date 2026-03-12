import 'package:get/get.dart';
import 'package:test_project/core/services/api_service.dart';
import 'package:test_project/core/services/storage_service.dart';
import 'package:test_project/data/repositories/auth_repository.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/app/controllers/main_nav_controller.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';
import 'package:test_project/modules/progress/controllers/progress_controller.dart';
import 'package:test_project/services/exam_api_service.dart';
import 'package:test_project/services/progress_api_service.dart';
import 'package:test_project/services/quiz_api_service.dart';
import 'package:test_project/services/subject_api_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(StorageService(), permanent: true);
    }

    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(
        ApiService(Get.find<StorageService>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepository(Get.find<ApiService>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ExamApiService>()) {
      Get.put<ExamApiService>(
        ExamApiService(Get.find<ApiService>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<SubjectApiService>()) {
      Get.put<SubjectApiService>(
        SubjectApiService(Get.find<ApiService>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AppStateController>()) {
      Get.put<AppStateController>(
        AppStateController(
          Get.find<ExamApiService>(),
          Get.find<SubjectApiService>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          Get.find<AuthRepository>(),
          Get.find<StorageService>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<QuizApiService>()) {
      Get.put<QuizApiService>(
        QuizApiService(Get.find<ApiService>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ProgressApiService>()) {
      Get.put<ProgressApiService>(
        ProgressApiService(Get.find<ApiService>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ProgressController>()) {
      Get.put<ProgressController>(
        ProgressController(
          Get.find<ProgressApiService>(),
          Get.find<AppStateController>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<MainNavController>()) {
      Get.put<MainNavController>(MainNavController(), permanent: true);
    }
  }
}
