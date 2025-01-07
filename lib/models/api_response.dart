class ApiResponse<T> {
  final String message;
  final T? data;

  ApiResponse({required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) =>
      ApiResponse(
        message: json['msg'] as String,
        data: json['data'] != null ? fromJsonT!(json['data']) : null,
      );
}
