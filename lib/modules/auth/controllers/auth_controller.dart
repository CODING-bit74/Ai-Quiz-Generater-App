import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:test_project/modules/app/controllers/app_state_controller.dart';
import 'package:test_project/core/services/storage_service.dart';
import 'package:test_project/data/models/auth_response_model.dart';
import 'package:test_project/data/models/user_model.dart';
import 'package:test_project/data/repositories/auth_repository.dart';
import 'package:test_project/routes/app_routes.dart';

class AuthController extends GetxController {
  AuthController(this._authRepository, this._storageService);

  final AuthRepository _authRepository;
  final StorageService _storageService;
  final GetStorage _localStorage = GetStorage();
  static const int _resendCooldownSeconds = 120;

  final RxBool isLoading = false.obs;
  final RxBool isSessionLoading = false.obs;
  final RxBool isVerificationChecking = false.obs;
  final RxBool isResendingVerification = false.obs;
  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isAuthenticated = false.obs;
  final RxString resetPasswordToken = ''.obs;
  bool _isSessionBootstrapped = false;

  @override
  void onInit() {
    super.onInit();
    bootstrapSession();
  }

  Future<void> bootstrapSession() async {
    if (_isSessionBootstrapped) {
      return;
    }
    _isSessionBootstrapped = true;
    isSessionLoading.value = true;

    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      isSessionLoading.value = false;
      return;
    }

    try {
      final response = await _authRepository.refreshToken(
        refreshToken: refreshToken,
      );
      await _saveTokens(response, fallbackRefreshToken: refreshToken);
      if (response.user != null) {
        user.value = response.user;
      }
      isAuthenticated.value = true;
    } catch (_) {
      await _storageService.clearTokens();
      isAuthenticated.value = false;
      user.value = null;
    } finally {
      isSessionLoading.value = false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String deviceInfo,
  }) async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
        deviceInfo: deviceInfo,
      );
      await _saveTokens(response);
      user.value = response.user;
      isAuthenticated.value = true;
      await _localStorage.remove('pending_verification_email');
      await _localStorage.remove(
        _resendCooldownKey(email.trim().toLowerCase()),
      );
      _goToAuthenticatedDestination();

      Get.snackbar(
        'Success',
        'Login successful',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      if (_isEmailVerificationRequired(error)) {
        await _localStorage.write('pending_verification_email', email.trim());
        Get.offAllNamed(
          AppRoutes.emailVerification,
          arguments: {'email': email.trim()},
        );
        Get.snackbar(
          'Verify email',
          'Please verify your email first.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _showError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      await _saveTokens(response);
      user.value = response.user;
      isAuthenticated.value = response.user?.isEmailVerified == true;

      if (response.user?.isEmailVerified == true) {
        await _localStorage.remove('pending_verification_email');
        _goToAuthenticatedDestination();
        Get.snackbar(
          'Success',
          'Registration successful',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _localStorage.write('pending_verification_email', email.trim());
        _setResendCooldown(email.trim());
        Get.offAllNamed(
          AppRoutes.emailVerification,
          arguments: {'email': email.trim()},
        );
        Get.snackbar(
          'Success',
          'Registration successful. Verify your email to continue.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      await _authRepository.forgotPassword(email: email);
      Get.snackbar(
        'Email sent',
        'Password reset instructions sent to your email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      _showError(error);
    } finally {
      isLoading.value = false;
    }
  }

  void setResetPasswordToken(String token) {
    resetPasswordToken.value = token.trim();
  }

  Future<void> resetPassword(String newPassword) async {
    if (isLoading.value) {
      return;
    }

    final token = resetPasswordToken.value.trim();
    if (token.isEmpty) {
      Get.snackbar(
        'Invalid link',
        'Reset token is missing. Please open the reset link from your email.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      await _authRepository.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      resetPasswordToken.value = '';
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Success',
        'Password reset successful. Please log in.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      _showError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authRepository.logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // Network failure during logout should not block local logout.
    } finally {
      await _storageService.clearTokens();
      await _localStorage.remove('pending_verification_email');
      user.value = null;
      isAuthenticated.value = false;
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  String? get pendingVerificationEmail {
    final stored = _localStorage.read<String>('pending_verification_email');
    if (stored == null || stored.trim().isEmpty) {
      return null;
    }
    return stored.trim();
  }

  Future<bool> checkEmailVerificationStatus({
    required String email,
    bool showFeedback = true,
  }) async {
    if (isVerificationChecking.value) {
      return false;
    }

    isVerificationChecking.value = true;
    try {
      final isVerified = await _authRepository.checkEmailVerificationStatus(
        email: email,
      );

      if (isVerified) {
        isAuthenticated.value = true;
        await _localStorage.remove('pending_verification_email');
        await _localStorage.remove(
          _resendCooldownKey(email.trim().toLowerCase()),
        );
        _goToAuthenticatedDestination();
        return true;
      }

      if (showFeedback) {
        Get.snackbar(
          'Not verified yet',
          'Please verify your email and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    } catch (error) {
      if (showFeedback) {
        _showError(error);
      }
      return false;
    } finally {
      isVerificationChecking.value = false;
    }
  }

  Future<bool> resendVerificationEmail({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    if (isResendingVerification.value) {
      return false;
    }

    final remaining = getResendSecondsRemaining(normalizedEmail);
    if (remaining > 0) {
      Get.snackbar(
        'Please wait',
        'You can resend in ${_formatDuration(remaining)}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isResendingVerification.value = true;
    try {
      await _authRepository.resendVerificationEmail(email: normalizedEmail);
      _setResendCooldown(normalizedEmail);
      Get.snackbar(
        'Sent',
        'Verification email sent again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (error) {
      _showError(error);
      return false;
    } finally {
      isResendingVerification.value = false;
    }
  }

  int getResendSecondsRemaining(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return 0;
    }

    final key = _resendCooldownKey(normalizedEmail);
    final nextAllowedAt = _localStorage.read<int>(key) ?? 0;
    final diffMs = nextAllowedAt - DateTime.now().millisecondsSinceEpoch;
    if (diffMs <= 0) {
      return 0;
    }

    return (diffMs / 1000).ceil();
  }

  void _setResendCooldown(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return;
    }

    final nextAllowedAt = DateTime.now()
        .add(const Duration(seconds: _resendCooldownSeconds))
        .millisecondsSinceEpoch;
    _localStorage.write(_resendCooldownKey(normalizedEmail), nextAllowedAt);
  }

  String _resendCooldownKey(String normalizedEmail) {
    return 'resend_verification_next_at_$normalizedEmail';
  }

  Future<void> _saveTokens(
    AuthResponseModel response, {
    String? fallbackRefreshToken,
  }) async {
    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken.isNotEmpty
        ? response.refreshToken
        : (fallbackRefreshToken ?? '');

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('Invalid token response');
    }

    await _storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  void _showError(Object error) {
    Get.snackbar(
      'Error',
      _extractErrorMessage(error),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['message'] != null) {
          return data['message'].toString();
        }
        final nestedError = data['error'];
        if (nestedError is Map && nestedError['message'] != null) {
          return nestedError['message'].toString();
        }
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }

  bool _isEmailVerificationRequired(Object error) {
    final message = _extractErrorMessage(error).toLowerCase();
    return message.contains('verify your email');
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _goToAuthenticatedDestination() {
    final appState = Get.find<AppStateController>();
    if (appState.hasSelectedPath) {
      Get.offAllNamed(AppRoutes.appShell);
      return;
    }
    Get.offAllNamed(AppRoutes.pathSelection);
  }
}
