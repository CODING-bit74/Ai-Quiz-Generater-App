import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:test_project/core/constants/storage_keys.dart';

class StorageService extends GetxService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final RxnString _accessToken = RxnString();
  bool _isHydrated = false;

  Future<void> _hydrateTokens() async {
    if (_isHydrated) {
      return;
    }
    _isHydrated = true;
    _accessToken.value = await _secureStorage.read(key: StorageKeys.accessToken);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken.value = accessToken;
    await _secureStorage.write(
      key: StorageKeys.accessToken,
      value: accessToken,
    );
    await _secureStorage.write(
      key: StorageKeys.refreshToken,
      value: refreshToken,
    );
  }

  Future<String?> getRefreshToken() async {
    await _hydrateTokens();
    return _secureStorage.read(key: StorageKeys.refreshToken);
  }

  Future<String?> getAccessToken() async {
    await _hydrateTokens();
    return _accessToken.value;
  }

  Future<void> clearTokens() async {
    _accessToken.value = null;
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
  }
}
