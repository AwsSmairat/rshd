class ApiMeta {
  const ApiMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      currentPage: _asInt(json['current_page']),
      lastPage: _asInt(json['last_page']),
      perPage: _asInt(json['per_page']),
      total: _asInt(json['total']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? 0;
  }
}

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.meta,
    this.errors,
  });

  final bool success;
  final String? message;
  final T? data;
  final ApiMeta? meta;
  final Map<String, dynamic>? errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final rawData = json['data'];
    T? parsedData;

    if (fromJsonT != null && rawData != null) {
      parsedData = fromJsonT(rawData);
    } else if (rawData is T) {
      parsedData = rawData;
    }

    return ApiResponse(
      success: json['success'] == true,
      message: json['message'] as String?,
      data: parsedData,
      meta: json['meta'] is Map<String, dynamic>
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] is Map
          ? Map<String, dynamic>.from(json['errors'] as Map)
          : null,
    );
  }
}
