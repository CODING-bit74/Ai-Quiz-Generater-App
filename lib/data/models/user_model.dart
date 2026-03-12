class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isEmailVerified,
  });

  final String id;
  final String email;
  final String name;
  final bool isEmailVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final hasEmailVerifiedKey = json.containsKey('isEmailVerified');
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isEmailVerified: hasEmailVerifiedKey ? json['isEmailVerified'] == true : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isEmailVerified': isEmailVerified,
    };
  }
}
