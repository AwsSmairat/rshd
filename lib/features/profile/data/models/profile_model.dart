import 'device_model.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.createdAt,
    this.activeDevice,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? createdAt;
  final DeviceModel? activeDevice;

  String get roleLabel {
    switch (role) {
      case 'student':
        return 'طالب';
      case 'instructor':
        return 'مدرّس';
      case 'admin':
        return 'مدير';
      default:
        return role;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'blocked':
        return 'موقوف';
      default:
        return status;
    }
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    DeviceModel? activeDevice;
    final deviceJson = json['active_device'];
    if (deviceJson is Map<String, dynamic>) {
      try {
        activeDevice = DeviceModel.fromJson(deviceJson);
      } catch (_) {
        activeDevice = null;
      }
    } else if (deviceJson is Map) {
      try {
        activeDevice = DeviceModel.fromJson(
          Map<String, dynamic>.from(deviceJson),
        );
      } catch (_) {
        activeDevice = null;
      }
    }

    return ProfileModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      activeDevice: activeDevice,
    );
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }
}
