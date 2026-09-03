import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';
import '../constants/storage_keys.dart';

const appThemePreferenceLight = 'light';
const appThemePreferenceDark = 'dark';
const appThemePreferenceSystem = 'system';

ThemeMode themeModeFromPreference(String preference) {
  return switch (preference) {
    appThemePreferenceDark => ThemeMode.dark,
    appThemePreferenceSystem => ThemeMode.system,
    _ => ThemeMode.light,
  };
}

class AppThemeController extends StateNotifier<String> {
  AppThemeController(this._storage) : super(appThemePreferenceLight) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    final saved = await _storage.read(StorageKeys.appTheme);
    if (saved == appThemePreferenceLight ||
        saved == appThemePreferenceDark ||
        saved == appThemePreferenceSystem) {
      state = saved!;
    }
  }

  Future<void> setTheme(String preference) async {
    final normalized = switch (preference) {
      appThemePreferenceDark => appThemePreferenceDark,
      appThemePreferenceSystem => appThemePreferenceSystem,
      _ => appThemePreferenceLight,
    };
    if (state == normalized) {
      await _storage.write(StorageKeys.appTheme, normalized);
      return;
    }
    state = normalized;
    await _storage.write(StorageKeys.appTheme, normalized);
  }
}

final appThemeControllerProvider =
    StateNotifierProvider<AppThemeController, String>((ref) {
      return AppThemeController(ref.watch(secureStorageProvider));
    });
