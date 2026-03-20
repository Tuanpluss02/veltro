import 'package:veltro/veltro.dart';

part 'user_state_error.g.dart';

@Veltro()
abstract class UserStateError with _$UserStateError {
  const factory UserStateError({
    required String errorCode,
    String? errorMessage,
  }) = _UserStateError;

  factory UserStateError.fromJson(Map<String, dynamic> json) =>
      _UserStateError.fromJson(json);
}
