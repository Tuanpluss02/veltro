import 'package:veltro/veltro.dart';

part 'user_state_loading.g.dart';

@Veltro()
abstract class UserStateLoading with _$UserStateLoading {
  const factory UserStateLoading({
    required bool isLoading,
    String? message,
  }) = _UserStateLoading;

  factory UserStateLoading.fromJson(Map<String, dynamic> json) =>
      _UserStateLoading.fromJson(json);
}
