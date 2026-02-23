import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final SupabaseClient _supabase = Supabase.instance.client;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to Auth State Changes
    _supabase.auth.onAuthStateChange.listen((data) {
      currentUser.value = data.session?.user;
    });
    currentUser.value = _supabase.auth.currentUser;
  }

  /// Sign Up with Email, Password & Name
  Future<String?> signUp(String email, String password, String name) async {
    isLoading.value = true;
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.testproject.app://login-callback',
        data: {'full_name': name}, // Store name in metadata
      );

      if (res.user != null) {
        if (res.session == null) {
          return "CONFIRM_EMAIL"; // Special code for UI
        }
        return null; // Success & Logged In
      } else {
        return "Sign up failed. Please try again.";
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    } finally {
      isLoading.value = false;
    }
  }

  /// Log In with Email & Password
  Future<String?> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        return null; // Success
      } else {
        return "Login failed.";
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get Current User ID
  String? get userId => currentUser.value?.id;

  /// Get Current Access Token
  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  /// Check if logged in
  bool get isLoggedIn => currentUser.value != null;
}
