import 'package:veltro/veltro.dart';

import '../models/address.dart';

part 'device.g.dart';

enum DeviceType { mobile, web, tablet }

@Veltro()
abstract class Device with _$Device {
  const factory Device({
    required String deviceId,
    required DeviceType type,
    required Address address,
    String? osVersion,
    bool? isActive,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _Device.fromJson(json);
}
