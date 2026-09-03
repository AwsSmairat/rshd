import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

const appFontSizeSmall = 'small';
const appFontSizeMedium = 'medium';
const appFontSizeLarge = 'large';

const appVideoQualityAuto = 'auto';
const appVideoQualityLow = 'low';
const appVideoQualityMedium = 'medium';
const appVideoQualityHigh = 'high';

@immutable
class AppDisplayPreferences {
  const AppDisplayPreferences({
    this.fontSize = appFontSizeMedium,
    this.autoPlayVideo = false,
    this.saveWatchPosition = true,
    this.videoQuality = appVideoQualityAuto,
  });

  final String fontSize;
  final bool autoPlayVideo;
  final bool saveWatchPosition;
  final String videoQuality;

  double get textScale => switch (fontSize) {
    appFontSizeSmall => 0.88,
    appFontSizeLarge => 1.18,
    _ => 1.0,
  };

  double resolvedTextScale(double systemFactor) {
    return (systemFactor * textScale).clamp(0.8, 1.5);
  }

  AppDisplayPreferences copyWith({
    String? fontSize,
    bool? autoPlayVideo,
    bool? saveWatchPosition,
    String? videoQuality,
  }) {
    return AppDisplayPreferences(
      fontSize: fontSize ?? this.fontSize,
      autoPlayVideo: autoPlayVideo ?? this.autoPlayVideo,
      saveWatchPosition: saveWatchPosition ?? this.saveWatchPosition,
      videoQuality: videoQuality ?? this.videoQuality,
    );
  }

  Map<String, Object> toJson() {
    return {
      'font_size': fontSize,
      'auto_play_video': autoPlayVideo,
      'save_watch_position': saveWatchPosition,
      'default_video_quality': videoQuality,
    };
  }

  factory AppDisplayPreferences.fromJson(Map<String, dynamic> json) {
    return AppDisplayPreferences(
      fontSize: _normalizeFontSize(json['font_size']?.toString()),
      autoPlayVideo: json['auto_play_video'] == true,
      saveWatchPosition: json['save_watch_position'] != false,
      videoQuality: _normalizeVideoQuality(
        json['default_video_quality']?.toString(),
      ),
    );
  }
}

String _normalizeFontSize(String? value) {
  return switch (value) {
    appFontSizeSmall || appFontSizeLarge => value!,
    _ => appFontSizeMedium,
  };
}

String _normalizeVideoQuality(String? value) {
  return switch (value) {
    appVideoQualityLow ||
    appVideoQualityMedium ||
    appVideoQualityHigh => value!,
    _ => appVideoQualityAuto,
  };
}

class AppDisplayPreferencesController
    extends StateNotifier<AppDisplayPreferences> {
  AppDisplayPreferencesController(this._storage)
    : super(const AppDisplayPreferences()) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    final raw = await _storage.read(StorageKeys.appDisplayPreferences);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        state = AppDisplayPreferences.fromJson(decoded);
      } else if (decoded is Map) {
        state = AppDisplayPreferences.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      // Keep defaults if stored JSON is invalid.
    }
  }

  Future<void> apply({
    String? fontSize,
    bool? autoPlayVideo,
    bool? saveWatchPosition,
    String? videoQuality,
  }) async {
    final next = state.copyWith(
      fontSize: fontSize == null ? null : _normalizeFontSize(fontSize),
      autoPlayVideo: autoPlayVideo,
      saveWatchPosition: saveWatchPosition,
      videoQuality: videoQuality == null
          ? null
          : _normalizeVideoQuality(videoQuality),
    );
    if (next.fontSize == state.fontSize &&
        next.autoPlayVideo == state.autoPlayVideo &&
        next.saveWatchPosition == state.saveWatchPosition &&
        next.videoQuality == state.videoQuality) {
      return;
    }
    state = next;
    await _persist();
  }

  Future<void> applyFromSettings({
    required String fontSize,
    required bool autoPlayVideo,
    required bool saveWatchPosition,
    required String videoQuality,
  }) {
    return apply(
      fontSize: fontSize,
      autoPlayVideo: autoPlayVideo,
      saveWatchPosition: saveWatchPosition,
      videoQuality: videoQuality,
    );
  }

  Future<void> _persist() {
    return _storage.write(
      StorageKeys.appDisplayPreferences,
      jsonEncode(state.toJson()),
    );
  }
}

final appDisplayPreferencesProvider =
    StateNotifierProvider<
      AppDisplayPreferencesController,
      AppDisplayPreferences
    >((ref) {
      return AppDisplayPreferencesController(ref.watch(secureStorageProvider));
    });
