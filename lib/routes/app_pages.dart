import 'package:get/get.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/modules/app/views/main_shell_screen.dart';
import 'package:test_project/modules/auth/controllers/auth_controller.dart';
import 'package:test_project/modules/auth/views/email_verification_screen.dart';
import 'package:test_project/modules/auth/views/forgot_password_screen.dart';
import 'package:test_project/modules/auth/views/login_screen.dart';
import 'package:test_project/modules/auth/views/register_screen.dart';
import 'package:test_project/modules/auth/views/reset_password_screen.dart';
import 'package:test_project/modules/path/controllers/path_selection_controller.dart';
import 'package:test_project/modules/path/views/path_selection_screen.dart';
import 'package:test_project/modules/progress/controllers/progress_controller.dart';
import 'package:test_project/modules/quiz/controllers/quiz_session_controller.dart';
import 'package:test_project/modules/quiz/views/quiz_session_screen.dart';
import 'package:test_project/modules/splash/controllers/splash_controller.dart';
import 'package:test_project/modules/splash/views/splash_screen.dart';
import 'package:test_project/routes/app_routes.dart';
import 'package:test_project/services/quiz_api_service.dart';

class AppPages {
  AppPages._();

  static String get initial => AppRoutes.splash;

  static String _extractResetPasswordToken() {
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      return args.trim();
    }
    if (args is Map && args['token'] != null) {
      final token = args['token'].toString().trim();
      if (token.isNotEmpty) {
        return token;
      }
    }
    final queryToken = Get.parameters['token']?.trim();
    if (queryToken != null && queryToken.isNotEmpty) {
      return queryToken;
    }
    final baseToken = Uri.base.queryParameters['token']?.trim();
    if (baseToken != null && baseToken.isNotEmpty) {
      return baseToken;
    }
    return '';
  }

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      binding: BindingsBuilder(() {
        Get.put<SplashController>(
          SplashController(
            Get.find<AuthController>(),
            Get.find<AppStateController>(),
          ),
        );
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginScreen.new,
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.register,
      page: RegisterScreen.new,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.emailVerification,
      page: EmailVerificationScreen.new,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: ForgotPasswordScreen.new,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => ResetPasswordScreen(token: _extractResetPasswordToken()),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.pathSelection,
      page: PathSelectionScreen.new,
      binding: BindingsBuilder(() {
        Get.put<PathSelectionController>(
          PathSelectionController(Get.find<AppStateController>()),
        );
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.appShell,
      page: MainShellScreen.new,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.quizSession,
      page: QuizSessionScreen.new,
      binding: BindingsBuilder(() {
        Get.put<QuizSessionController>(
          QuizSessionController(
            Get.find<QuizApiService>(),
            Get.find<AppStateController>(),
            Get.find<ProgressController>(),
          ),
        );
      }),
      transition: Transition.rightToLeft,
    ),
  ];
}
