int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? fallback;
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
    this.videoUrl,
    this.durationSeconds = 0,
    this.status = 'ready',
    this.storageProvider,
    this.isFree = false,
    this.isLocked = false,
    this.progress,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int lessonId;
  final String title;
  final String? videoUrl;
  final int durationSeconds;
  final String status;
  final String? storageProvider;
  final bool isFree;
  final bool isLocked;
  final VideoProgressModel? progress;
  final String? createdAt;
  final String? updatedAt;

  bool get canPlay => !isLocked && (videoUrl?.trim().isNotEmpty ?? false);

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'];
    final isFree = json['is_free'] == true || json['is_free'] == 1;
    final isLocked = json['is_locked'] == true || json['is_locked'] == 1;

    return VideoModel(
      id: _asInt(json['id']),
      lessonId: _asInt(json['lesson_id']),
      title: json['title']?.toString() ?? '',
      videoUrl: json['video_url']?.toString(),
      durationSeconds: _asInt(json['duration_seconds']),
      status: json['status']?.toString() ?? 'ready',
      storageProvider: json['storage_provider']?.toString(),
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

  String get statusLabel {
    switch (status) {
      case 'processing':
        return 'قيد المعالجة';
      case 'ready':
        return 'جاهز';
      case 'failed':
        return 'فشل';
      default:
        return status;
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
