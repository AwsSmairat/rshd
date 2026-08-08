int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? fallback;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

class VideoPlaybackModel {
  const VideoPlaybackModel({
    required this.url,
    this.expiresAt,
    this.type,
  });

  final String url;
  final DateTime? expiresAt;
  final String? type;

  String get playbackType {
    final value = type?.trim();
    if (value == null || value.isEmpty) {
      return 'hls';
    }

    return value;
  }

  bool get isEmbed => playbackType == 'embed';

  bool get isHls => playbackType == 'hls';

  /// Prefer URL shape over stale `type` values after hot reload/cache.
  bool get usesEmbedPlayer {
    final value = url.trim().toLowerCase();
    return value.contains('iframe.mediadelivery.net') ||
        value.contains('player.mediadelivery.net');
  }

  bool get usesNativePlayer => !usesEmbedPlayer;

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }

    return DateTime.now().isAfter(expiry);
  }

  bool get shouldRefreshSoon {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }

    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)));
  }

  factory VideoPlaybackModel.fromJson(Map<String, dynamic> json) {
    return VideoPlaybackModel(
      url: json['url']?.toString() ?? '',
      expiresAt: _parseDateTime(json['expires_at']),
      type: json['type']?.toString() ?? 'hls',
    );
  }

  VideoPlaybackModel copyWith({
    String? url,
    DateTime? expiresAt,
    String? type,
    bool clearType = false,
  }) {
    return VideoPlaybackModel(
      url: url ?? this.url,
      expiresAt: expiresAt ?? this.expiresAt,
      type: clearType ? null : (type ?? this.type),
    );
  }
}

class VideoProgressModel {
  const VideoProgressModel({
    this.watchedSeconds = 0,
    this.currentPosition = 0,
    this.completionPercentage = 0,
    this.replayCount = 0,
    this.lastWatchedAt,
  });

  final int watchedSeconds;
  final int currentPosition;
  final int completionPercentage;
  final int replayCount;
  final String? lastWatchedAt;

  factory VideoProgressModel.fromJson(Map<String, dynamic> json) {
    return VideoProgressModel(
      watchedSeconds: _asInt(json['watched_seconds']),
      currentPosition: _asInt(json['current_position']),
      completionPercentage: _asInt(json['completion_percentage']),
      replayCount: _asInt(json['replay_count']),
      lastWatchedAt: json['last_watched_at']?.toString(),
    );
  }
}

class VideoModel {
  const VideoModel({
    required this.id,
    required this.lessonId,
    required this.title,
    this.playback,
    this.durationSeconds = 0,
    this.status = 'ready',
    this.isFree = false,
    this.isLocked = false,
    this.progress,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int lessonId;
  final String title;
  final VideoPlaybackModel? playback;
  final int durationSeconds;
  final String status;
  final bool isFree;
  final bool isLocked;
  final VideoProgressModel? progress;
  final String? createdAt;
  final String? updatedAt;

  bool get canPlay =>
      !isLocked && (playback?.url.trim().isNotEmpty ?? false);

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'];
    final playbackJson = json['playback'];
    final isFree = json['is_free'] == true || json['is_free'] == 1;
    final isLocked = json['is_locked'] == true || json['is_locked'] == 1;

    return VideoModel(
      id: _asInt(json['id']),
      lessonId: _asInt(json['lesson_id']),
      title: json['title']?.toString() ?? '',
      playback: playbackJson is Map<String, dynamic>
          ? VideoPlaybackModel.fromJson(playbackJson)
          : playbackJson is Map
              ? VideoPlaybackModel.fromJson(
                  Map<String, dynamic>.from(playbackJson),
                )
              : null,
      durationSeconds: _asInt(json['duration_seconds']),
      status: json['status']?.toString() ?? 'ready',
      isFree: isFree,
      isLocked: isLocked,
      progress: progressJson is Map<String, dynamic>
          ? VideoProgressModel.fromJson(progressJson)
          : progressJson is Map
              ? VideoProgressModel.fromJson(
                  Map<String, dynamic>.from(progressJson),
                )
              : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  VideoModel copyWith({
    VideoPlaybackModel? playback,
    VideoProgressModel? progress,
  }) {
    return VideoModel(
      id: id,
      lessonId: lessonId,
      title: title,
      playback: playback ?? this.playback,
      durationSeconds: durationSeconds,
      status: status,
      isFree: isFree,
      isLocked: isLocked,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'processing':
        return 'قيد المعالجة';
      case 'uploading':
        return 'جاري الرفع';
      case 'ready':
        return 'جاهز';
      case 'failed':
        return 'فشل';
      default:
        return status;
    }
  }

  bool get isPendingPlayback =>
      status == 'uploading' || status == 'processing';

  String get pendingPlaybackMessage {
    switch (status) {
      case 'uploading':
        return 'الفيديو قيد الرفع إلى Bunny Stream. انتظر قليلاً ثم اسحب للأسفل لتحديث الصفحة.';
      case 'processing':
        return 'الفيديو قيد المعالجة. سيظهر رابط التشغيل تلقائياً عند اكتمال الترميز.';
      case 'failed':
        return 'فشل تجهيز الفيديو. يرجى التواصل مع الدعم أو إعادة رفعه من لوحة الإدارة.';
      default:
        return 'رابط التشغيل غير متوفر حالياً';
    }
  }

  String get formattedDuration => formatVideoDuration(durationSeconds);

  static String formatVideoDuration(int seconds) {
    if (seconds <= 0) {
      return '—';
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
