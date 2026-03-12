import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:test_project/core/constants/api_constants.dart';
import 'package:test_project/core/services/storage_service.dart';
import 'package:test_project/routes/app_routes.dart';

class ApiService extends GetxService {
  ApiService(this._storageService) {
    _configureInterceptors();
  }

  final StorageService _storageService;
  Future<String?>? _refreshFuture;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  void _configureInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final requestOptions = error.requestOptions;
          final hasRetried = requestOptions.extra['hasRetried'] == true;
          final isRefreshRequest =
              requestOptions.path.endsWith(ApiConstants.refresh);

          final shouldRefresh =
              statusCode == 401 && !isRefreshRequest && !hasRetried;

          if (!shouldRefresh) {
            handler.next(error);
            return;
          }

          final newAccessToken = await _refreshAccessToken();
          if (newAccessToken == null || newAccessToken.isEmpty) {
            await _handleRefreshFailure();
            handler.next(error);
            return;
          }

          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          requestOptions.extra['hasRetried'] = true;

          try {
            final retryResponse = await dio.fetch<dynamic>(requestOptions);
            handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  Future<String?> _refreshAccessToken() async {
    _refreshFuture ??= _executeRefresh();
    final token = await _refreshFuture;
    _refreshFuture = null;
    return token;
  }

  Future<String?> _executeRefresh() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await _refreshDio.post<dynamic>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      final payload = _safeMap(response.data);
      final newAccessToken = payload['accessToken']?.toString() ?? '';
      final newRefreshToken = payload['refreshToken']?.toString() ?? refreshToken;

      if (newAccessToken.isEmpty) {
        return null;
      }

      await _storageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } on DioException {
      return null;
    }
  }

  Future<void> _handleRefreshFailure() async {
    await _storageService.clearTokens();
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Map<String, dynamic> _safeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
