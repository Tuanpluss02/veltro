import 'package:veltro/veltro.dart';

import 'device.dart';

part 'audit_log.g.dart';

@Veltro()
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required int timestamp,
    required Device device,
    String? action,
    bool? success,
    int? durationMs,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _AuditLog.fromJson(json);
}
