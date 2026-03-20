import 'package:veltro/veltro.dart';

import 'address.dart';
import 'role.dart';
import 'status.dart';
import 'user.dart';

part 'nullable_profile.g.dart';

@Veltro()
abstract class NullableProfile with _$NullableProfile {
  const factory NullableProfile({
    required User user,
    required Status status,
    required Role role,
    required Address location,
    String? website,
    int? followers,
    bool? marketingOptIn,
  }) = _NullableProfile;

  factory NullableProfile.fromJson(Map<String, dynamic> json) =>
      _NullableProfile.fromJson(json);
}
