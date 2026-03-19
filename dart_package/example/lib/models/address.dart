import 'package:veltro/veltro.dart';

part 'address.g.dart';

@Data()
abstract class Address with _$Address {
  const factory Address({
    required String street,
    required String city,
    required String country,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}
