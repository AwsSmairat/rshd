class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.emailVerifiedAt,
    this.passwordSetAt,
    this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final String? emailVerifiedAt;
  final String? passwordSetAt;
  final String? createdAt;
  final String? updatedAt;
  final bool isEmailVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final emailVerifiedAt = json['email_verified_at']?.toString();
    final isEmailVerifiedRaw = json['is_email_verified'];

    return UserModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      phone: json['phone']?.toString(),
      emailVerifiedAt: emailVerifiedAt,
      passwordSetAt: json['password_set_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      isEmailVerified: isEmailVerifiedRaw is bool
          ? isEmailVerifiedRaw
          : (emailVerifiedAt != null && emailVerifiedAt.isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'email_verified_at': emailVerifiedAt,
      'is_email_verified': isEmailVerified,
      'password_set_at': passwordSetAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isStudent => role.toLowerCase() == 'student';
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final UserModel user;
}
