import 'package:veltro/veltro.dart';

part 'simple.g.dart';

@Data()
class User {
  const factory User({
    required String id,
    required String name,
    required int age,
  }) = _User;
}
