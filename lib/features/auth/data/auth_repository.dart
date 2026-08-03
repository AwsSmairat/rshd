import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/device_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'models/user_model.dart';

class LoginOutcome {
  const LoginOutcome._({
    this.session,
    this.verificationEmail,
  });

  final AuthSession? session;
  final String? verificationEmail;

  bool get requiresEmailVerification => verificationEmail != null;

  factory LoginOutcome.success(AuthSession session) {
    return LoginOutcome._(session: session);
  }

  factory LoginOutcome.requiresVerification(String email) {
    return LoginOutcome._(verificationEmail: email);
  }
}

class RegisterOutcome {
  const RegisterOutcome._({
    this.session,
    this.verificationEmail,
  });

  final AuthSession? session;
  final String? verificationEmail;

  bool get requiresEmailVerification => verificationEmail != null;

  factory RegisterOutcome.requiresVerification(String email) {
    return RegisterOutcome._(verificationEmail: email);
  }

  factory RegisterOutcome.session(AuthSession session) {
    return RegisterOutcome._(session: session);
  }
}

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required DeviceService deviceService,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _deviceService = deviceService;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final DeviceService _deviceService;

  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final devicePayload = await _deviceService.getDevicePayload();

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          ...devicePayload,
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        (json) => Map<String, dynamic>.from(json as Map),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ApiException(
          message: apiResponse.message ?? 'فشل تسجيل الدخول.',
          errors: apiResponse.errors,
        );
      }

      final session = _parseSession(apiResponse.data!);
      await _persistSession(session);
      return LoginOutcome.success(session);
    } on ApiException catch (error) {
      if (error.requiresEmailVerification) {
        return LoginOutcome.requiresVerification(
          error.responseEmail ?? email,
        );
      }
      rethrow;
    }
  }

  Future<RegisterOutcome> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final devicePayload = await _deviceService.getDevicePayload();

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        ...devicePayload,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'فشل إنشاء الحساب.',
        errors: apiResponse.errors,
      );
    }

    final data = apiResponse.data!;
    if (data['requires_email_verification'] == true) {
      return RegisterOutcome.requiresVerification(
        data['email']?.toString() ?? email,
      );
    }

    final token = data['token']?.toString();
    final userJson = data['user'];

    if (token == null || token.isEmpty || userJson is! Map) {
      throw ApiException(message: 'استجابة التسجيل غير صالحة.');
    }

    final session = AuthSession(
      token: token,
      user: UserModel.fromJson(Map<String, dynamic>.from(userJson)),
    );
    await _persistSession(session);
    return RegisterOutcome.session(session);
  }

  Future<AuthSession> verifyEmail({
    required String email,
    required String code,
  }) async {
    final devicePayload = await _deviceService.getDevicePayload();

    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.verifyEmail,
      data: {
        'email': email,
        'code': code,
        ...devicePayload,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر تأكيد البريد الإلكتروني.',
        errors: apiResponse.errors,
      );
    }

    final session = _parseSession(apiResponse.data!);
    await _persistSession(session);
    return session;
  }

  Future<void> resendVerificationCode({required String email}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.resendVerificationEmail,
      data: {'email': email},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر إرسال رمز التحقق.',
        errors: apiResponse.errors,
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> logout() async {
    try {
      if (await _secureStorage.hasToken()) {
        await _apiClient.post<Map<String, dynamic>>(ApiEndpoints.logout);
      }
    } catch (_) {
      // Always clear local session even if remote logout fails.
    } finally {
      await _secureStorage.clearAll();
    }
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.me);

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (json) => Map<String, dynamic>.from(json as Map),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message ?? 'تعذر جلب بيانات المستخدم.',
        errors: apiResponse.errors,
        statusCode: response.statusCode,
      );
    }

    final user = UserModel.fromJson(apiResponse.data!);
    await _secureStorage.saveUser(user.toJson());
    return user;
  }

  Future<UserModel?> getCachedUser() async {
    final cached = await _secureStorage.getUser();
    if (cached == null) {
      return null;
    }
    return UserModel.fromJson(cached);
  }

  Future<bool> hasToken() => _secureStorage.hasToken();

  AuthSession _parseSession(Map<String, dynamic> data) {
    final token = data['token']?.toString();
    final userJson = data['user'];

    if (token == null || token.isEmpty || userJson is! Map) {
      throw ApiException(message: 'استجابة المصادقة غير صالحة.');
    }

    return AuthSession(
      token: token,
      user: UserModel.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }

  Future<void> _persistSession(AuthSession session) async {
    await _secureStorage.saveToken(session.token);
    await _secureStorage.saveUser(session.user.toJson());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
    deviceService: ref.watch(deviceServiceProvider),
  );
});
