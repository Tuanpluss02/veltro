import 'package:veltro/veltro.dart';

import 'address.dart';
import 'role.dart';
import 'status.dart';
import 'user.dart';

part 'large_record.g.dart';

@Veltro()
abstract class LargeRecord with _$LargeRecord {
  const factory LargeRecord({
    required String id,
    required int age,
    required bool isActive,
    required double score,
    required Address home,
    required Status status,
    required Role role,
    required User owner,
    String? nickname,
    int? optionalAge,
    bool? optionalFlag,
    double? optionalScore,
    required String s0,
    required String s1,
    required String s2,
    required String s3,
    required String s4,
    required String s5,
    required String s6,
    required String s7,
    required String s8,
    required String s9,
    required String s10,
    required String s11,
    required String s12,
    required String s13,
    required String s14,
    required String s15,
    required String s16,
    required String s17,
    required String s18,
    required String s19,
    required int i0,
    required int i1,
    required int i2,
    required int i3,
    required int i4,
    required int i5,
    required int i6,
    required int i7,
    required int i8,
    required int i9,
    required bool b0,
    required bool b1,
    required bool b2,
    required bool b3,
    required bool b4,
    required double d0,
    required double d1,
    required double d2,
    required double d3,
    required double d4,
  }) = _LargeRecord;

  factory LargeRecord.fromJson(Map<String, dynamic> json) =>
      _LargeRecord.fromJson(json);
}
