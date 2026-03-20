import 'package:veltro/veltro.dart';

part 'user_requested.g.dart';

@Veltro()
abstract class UserRequested with _$UserRequested {
  const factory UserRequested({
    required String userId,
    required bool forceReload,
    String? correlationId,
  }) = _UserRequested;

  factory UserRequested.fromJson(Map<String, dynamic> json) =>
      _UserRequested.fromJson(json);
}
