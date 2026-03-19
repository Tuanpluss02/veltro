import 'package:veltro/veltro.dart';

import 'address.dart';
import 'status.dart';

part 'user.g.dart';

@Data()
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required int age,
    required bool isVerified,
    required Address address,
    required Status status,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
