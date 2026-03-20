import 'package:veltro/veltro.dart';

import '../../../models/role.dart';
import '../../../models/status.dart';
import '../../../models/user.dart';

part 'user_updated.g.dart';

@Veltro()
abstract class UserUpdated with _$UserUpdated {
  const factory UserUpdated({
    required User user,
    required Status status,
    required Role role,
  }) = _UserUpdated;

  factory UserUpdated.fromJson(Map<String, dynamic> json) =>
      _UserUpdated.fromJson(json);
}
