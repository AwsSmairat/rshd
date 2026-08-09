class FileDownloadModel {
  const FileDownloadModel({required this.url, required this.expiresAt});

  final String url;
  final DateTime? expiresAt;

  factory FileDownloadModel.fromJson(Map<String, dynamic> json) {
    return FileDownloadModel(
      url: json['url']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }
}
