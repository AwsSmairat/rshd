import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'models/student_settings_model.dart';

class SettingsRepository {
  SettingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<StudentSettingsModel> getSettings() async {
    return _parseSettings(
      await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.studentSettings),
    );
  }

  Future<StudentSettingsModel> updateProfile({
    required String name,
    String? phone,
    String? birthDate,
    String? gender,
    String? country,
  }) async {
    return _parseSettings(
      await _apiClient.patch<Map<String, dynamic>>(
        ApiEndpoints.studentProfile,
        data: {
          'name': name,
          'phone': phone,
          'birth_date': birthDate,
          'gender': gender,
          'country': country,
        },
      ),
    );
  }

  Future<StudentSettingsModel> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });

    return _parseSettings(
      await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.studentAvatar,
        data: formData,
      ),
    );
  }

  Future<StudentSettingsModel> deleteAvatar() async {
    return _parseSettings(
      await _apiClient.delete<Map<String, dynamic>>(ApiEndpoints.studentAvatar),
    );
  }

  /// Authenticated download. Returns null when the endpoint is missing (405)
  /// or the student has no photo (404) — never hits the public `/storage` URL.
  Future<Uint8List?> downloadAvatar() async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        ApiEndpoints.studentAvatar,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
          headers: const {
            'Accept': 'image/*,application/octet-stream',
            'Content-Type': 'application/octet-stream',
          },
        ),
      );

      final bytes = response.data;
      if (response.statusCode != 200 || bytes == null || bytes.isEmpty) {
        return null;
      }

      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.studentPassword,
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    _ensureSuccess(response);
  }

  Future<StudentSettingsModel> updatePreferences(
    Map<String, dynamic> patch,
  ) async {
    return _parseSettings(
      await _apiClient.patch<Map<String, dynamic>>(
        ApiEndpoints.studentPreferences,
        data: patch,
      ),
    );
  }

  Future<StudentSettingsModel> revokeDevice(int deviceId) async {
    return _parseSettings(
      await _apiClient.delete<Map<String, dynamic>>(
        ApiEndpoints.studentDevice(deviceId),
      ),
    );
  }

  Future<void> logoutAllDevices() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.studentLogoutAllDevices,
    );
    _ensureSuccess(response);
  }

  Future<void> deleteAccount({required String password}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.studentDeleteAccount,
      data: {'password': password, 'confirmation': 'حذف'},
    );
    _ensureSuccess(response);
  }

  StudentSettingsModel _parseSettings(Response<Map<String, dynamic>> response) {
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تحميل الإعدادات',
        errors: apiResponse.errors,
      );
    }

    return StudentSettingsModel.fromJson(apiResponse.data!);
  }

  void _ensureSuccess(Response<Map<String, dynamic>> response) {
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تنفيذ العملية',
        errors: apiResponse.errors,
      );
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(apiClient: ref.watch(apiClientProvider));
});
