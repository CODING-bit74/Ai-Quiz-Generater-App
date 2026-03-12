import 'package:get/get.dart';
import 'package:test_project/core/services/api_service.dart';
import 'package:test_project/core/services/storage_service.dart';
import 'package:test_project/data/repositories/auth_repository.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
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

    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          Get.find<AuthRepository>(),
          Get.find<StorageService>(),
        ),
        permanent: true,
      );
    }
  }
}
