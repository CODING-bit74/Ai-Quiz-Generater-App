import 'package:test_project/data/models/user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final UserModel? user;
  final String accessToken;
  final String refreshToken;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthResponseModel(
      user: userJson is Map<String, dynamic> ? UserModel.fromJson(userJson) : null,
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
