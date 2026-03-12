import 'package:test_project/core/constants/api_constants.dart';
import 'package:test_project/core/services/api_service.dart';
import 'package:test_project/data/models/auth_response_model.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final ApiService _apiService;

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post<dynamic>(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(_toMap(response.data));
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
    required String deviceInfo,
  }) async {
    final response = await _apiService.post<dynamic>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'deviceInfo': deviceInfo,
      },
    );
    return AuthResponseModel.fromJson(_toMap(response.data));
  }

  Future<AuthResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiService.post<dynamic>(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    return AuthResponseModel.fromJson(_toMap(response.data));
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    await _apiService.post<dynamic>(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<bool> checkEmailVerificationStatus({
    required String email,
  }) async {
    final response = await _apiService.get<dynamic>(
      ApiConstants.emailVerificationStatus,
      queryParameters: {'email': email},
    );
    final data = _toMap(response.data);
    return data['isEmailVerified'] == true;
  }

  Future<void> resendVerificationEmail({
    required String email,
  }) async {
    await _apiService.post<dynamic>(
      ApiConstants.resendVerification,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiService.post<dynamic>(
      ApiConstants.resetPassword,
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout({
    required String refreshToken,
  }) async {
    await _apiService.post<dynamic>(
      ApiConstants.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const FormatException('Unexpected response format from API');
  }
}
