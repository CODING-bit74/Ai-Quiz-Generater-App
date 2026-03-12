import 'package:get/get.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';
import 'package:test_project/routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController(this._authController, this._appStateController);

  final AuthController _authController;
  final AppStateController _appStateController;
  bool _isNavigated = false;

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_isNavigated) {
      return;
    }

    await _authController.bootstrapSession();

    final pendingEmail = _authController.pendingVerificationEmail;
    if (pendingEmail != null && pendingEmail.isNotEmpty) {
      _isNavigated = true;
      Get.offAllNamed(
        AppRoutes.emailVerification,
        arguments: {'email': pendingEmail},
      );
      return;
    }

    if (_authController.isAuthenticated.value) {
      _isNavigated = true;
      if (_appStateController.hasSelectedPath) {
        Get.offAllNamed(AppRoutes.appShell);
      } else {
        Get.offAllNamed(AppRoutes.pathSelection);
      }
      return;
    }

    _isNavigated = true;
    Get.offAllNamed(AppRoutes.login);
  }
}
