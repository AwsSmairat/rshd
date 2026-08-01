import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';

class DeviceService {
  DeviceService({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final vendorId = info.identifierForVendor;
        if (vendorId != null && vendorId.isNotEmpty) {
          return vendorId;
        }
      } else if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        if (info.id.isNotEmpty) {
          return info.id;
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('DeviceService.getDeviceId fallback: $error');
      }
    }

    return _getOrCreateStoredDeviceId();
  }

  Future<String> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name.isNotEmpty ? info.name : 'iOS Device';
      }
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final manufacturer = info.manufacturer;
        final model = info.model;
        return '$manufacturer $model'.trim().isNotEmpty
            ? '$manufacturer $model'.trim()
            : 'Android Device';
      }
    } catch (_) {}

    return defaultTargetPlatform.name;
  }

  Future<String> getPlatform() async {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return 'other';
  }

  Future<Map<String, String>> getDevicePayload() async {
    return {
      'device_id': await getDeviceId(),
      'device_name': await getDeviceName(),
      'platform': await getPlatform(),
    };
  }

  Future<String> _getOrCreateStoredDeviceId() async {
    final existing = await _secureStorage.read(StorageKeys.deviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateStableId();
    await _secureStorage.write(StorageKeys.deviceId, generated);
    return generated;
  }

  String _generateStableId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(secureStorage: ref.watch(secureStorageProvider));
});
