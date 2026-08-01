class DeviceModel {
  const DeviceModel({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.platform,
    this.lastLoginAt,
    this.createdAt,
    this.isActive = false,
  });

  final int id;
  final String deviceId;
  final String? deviceName;
  final String? platform;
  final String? lastLoginAt;
  final String? createdAt;
  final bool isActive;

  String get platformLabel {
    switch (platform) {
      case 'ios':
        return 'iOS';
      case 'android':
        return 'Android';
      default:
        return platform ?? '—';
    }
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: _asInt(json['id']),
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: json['device_name']?.toString(),
      platform: json['platform']?.toString(),
      lastLoginAt: json['last_login_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      isActive: json['is_active'] == true,
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
