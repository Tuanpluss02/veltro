import 'package:veltro/veltro.dart';

import '../../../models/address.dart';
import '../../../models/role.dart';
import '../../../models/status.dart';
import '../../../models/user.dart';

part 'user_state_loaded.g.dart';

@Veltro()
abstract class UserStateLoaded with _$UserStateLoaded {
  const factory UserStateLoaded({
    required User user,
    required Address lastKnownAddress,
    required Role role,
    required Status status,
  }) = _UserStateLoaded;

  factory UserStateLoaded.fromJson(Map<String, dynamic> json) =>
      _UserStateLoaded.fromJson(json);
}
