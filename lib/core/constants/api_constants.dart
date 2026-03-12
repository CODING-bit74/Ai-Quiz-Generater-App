class ApiConstants {
  ApiConstants._();

  // For Android emulator, pass:
  // --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String verifyEmail = '/auth/verify-email';
  static const String emailVerificationStatus = '/auth/email-verification-status';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';

  static const String quizNext = '/quiz/next';
  static const String quizSubmit = '/quiz/submit';
  static const String progress = '/progress';
  static const String exams = '/exams';
  static const String subjects = '/subjects';

  // Base URL here intentionally includes "/api"; health is outside that path.
  static const String health = '/health';
}
