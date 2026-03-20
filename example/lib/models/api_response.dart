import 'package:veltro/veltro.dart';

part 'api_response.g.dart';

@Veltro()
abstract class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required T data,
    required String message,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _ApiResponse.fromJson(json, fromJsonT);
}
