import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:test_project/routes/app_routes.dart';

class DeepLinkService extends GetxService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;
  String? _lastHandledLink;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('Deep link stream error: $error');
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (error) {
      debugPrint('Initial deep link error: $error');
    }
  }

  void _handleUri(Uri uri) {
    if (!_isResetPasswordUri(uri)) {
      return;
    }

    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) {
      return;
    }

    final linkKey = uri.toString();
    if (_lastHandledLink == linkKey) {
      return;
    }
    _lastHandledLink = linkKey;

    _openResetPassword(token);
  }

  bool _isResetPasswordUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'quizapp') {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host == 'reset-password') {
      return true;
    }

    final path = uri.path.toLowerCase();
    return path == '/reset-password' || path == 'reset-password';
  }

  void _openResetPassword(String token) {
    if (Get.key.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openResetPassword(token);
      });
      return;
    }

    if (Get.currentRoute == AppRoutes.resetPassword) {
      Get.offNamed(AppRoutes.resetPassword, arguments: token);
      return;
    }

    Get.toNamed(AppRoutes.resetPassword, arguments: token);
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
