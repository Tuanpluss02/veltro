import 'package:veltro/veltro.dart';
part 'generic.g.dart';

@Data()
class ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required T data,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}
