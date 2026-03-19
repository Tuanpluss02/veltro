import 'package:veltro/veltro.dart';
part 'nested.g.dart';

@Data()
class Address {
  const factory Address({
    required String street,
    required String city,
  }) = _Address;
}

@Data()
class Person {
  const factory Person({
    required String name,
    required Address address,
  }) = _Person;
}
