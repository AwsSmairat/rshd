import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

const appLocaleArabic = 'ar';
const appLocaleEnglish = 'en';

String normalizeAppLocale(String? value) {
  return value == appLocaleEnglish ? appLocaleEnglish : appLocaleArabic;
}

Locale localeFromPreference(String preference) {
  return Locale(normalizeAppLocale(preference));
}

TextDirection textDirectionFromPreference(String preference) {
  return normalizeAppLocale(preference) == appLocaleEnglish
      ? TextDirection.ltr
      : TextDirection.rtl;
}

class AppLocaleController extends StateNotifier<String> {
  AppLocaleController(this._storage) : super(appLocaleArabic) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    final saved = await _storage.read(StorageKeys.appLocale);
    if (saved == appLocaleEnglish || saved == appLocaleArabic) {
      state = saved!;
    }
  }

  Future<void> setLocale(String preference) async {
    final normalized = normalizeAppLocale(preference);
    if (state == normalized) {
      await _storage.write(StorageKeys.appLocale, normalized);
      return;
    }
    state = normalized;
    await _storage.write(StorageKeys.appLocale, normalized);
  }
}

final appLocaleControllerProvider =
    StateNotifierProvider<AppLocaleController, String>((ref) {
      return AppLocaleController(ref.watch(secureStorageProvider));
    });
