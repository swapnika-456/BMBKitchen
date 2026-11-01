class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final String message;
  final T? data;
  final String? errorCode;

  ApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errorCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    dynamic data = json['data'];

    if (data is Map && data is! Map<String, dynamic>) {
      data = Map<String, dynamic>.from(data as Map);
    }

    return ApiResponse(
      success: json['ok'] == true || statusCode == 200 || statusCode == 201,
      statusCode: statusCode,
      message: json['message'] ?? 'Unknown error',
      data: data,
      errorCode: json['error_code'] ?? json['code'],
    );
  }
}
