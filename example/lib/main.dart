import 'bloc/events/user_requested.dart';
import 'bloc/events/user_updated.dart';
import 'bloc/states/user_state_error.dart';
import 'bloc/states/user_state_loaded.dart';
import 'bloc/states/user_state_loading.dart';
import 'dto/audit_log.dart';
import 'dto/device.dart';
import 'models/address.dart';
import 'models/api_response.dart';
import 'models/large_record.dart';
import 'models/nullable_profile.dart';
import 'models/role.dart';
import 'models/status.dart';
import 'models/user.dart';

void main() {
  // ── 1. Simple fromJson / toJson ──────────────────────────────
  final addressJson = {
    'street': '123 Main St',
    'city': 'Hanoi',
    'country': 'Vietnam',
  };
  final address = Address.fromJson(addressJson);
  assert(address.city == 'Hanoi');
  assert(address.toJson()['city'] == 'Hanoi');
  print('✓ Address fromJson/toJson');

  // ── 2. Nested object + Enum field ────────────────────────────
  final userJson = {
    'id': 'u-001',
    'name': 'Tuan',
    'age': 28,
    'isVerified': true,
    'address': addressJson,
    'status': 'active',
  };
  final user = User.fromJson(userJson);
  assert(user.name == 'Tuan');
  assert(user.address.city == 'Hanoi');
  assert(user.status == Status.active);
  assert(user.toJson()['status'] == 'active');
  print('✓ User fromJson/toJson with nested Address and enum Status');

  // ── 3. copyWith ──────────────────────────────────────────────
  final updatedUser = user.copyWith(name: 'Tuan Updated', age: 29);
  assert(updatedUser.name == 'Tuan Updated');
  assert(updatedUser.age == 29);
  assert(updatedUser.address.city == 'Hanoi'); // unchanged
  print('✓ copyWith');

  // ── 4. == and hashCode ───────────────────────────────────────
  final user2 = User.fromJson(userJson);
  assert(user == user2);
  assert(user.hashCode == user2.hashCode);
  print('✓ == and hashCode');

  // ── 5. toString ──────────────────────────────────────────────
  assert(user.toString().contains('Tuan'));
  print('✓ toString');

  // ── 6. Generic class (ApiResponse<User>) ────────────────────
  final responseJson = {
    'success': true,
    'data': userJson,
    'message': 'ok',
  };
  final response = ApiResponse.fromJson(
    responseJson,
    (json) => User.fromJson(json as Map<String, dynamic>),
  );
  assert(response.success == true);
  assert(response.data.name == 'Tuan');
  print('✓ Generic ApiResponse<User> fromJson');

  // ── 7. Nullable fields + missing keys ─────────────────────────
  final profileJson = {
    'user': userJson,
    'status': 'active',
    'role': 'admin',
    'location': addressJson,
    // intentionally omit: website, followers, marketingOptIn
  };
  final profile = NullableProfile.fromJson(profileJson);
  assert(profile.user.id == 'u-001');
  assert(profile.status == Status.active);
  assert(profile.role == Role.admin);
  assert(profile.location.city == 'Hanoi');
  assert(profile.website == null);
  assert(profile.followers == null);
  assert(profile.marketingOptIn == null);
  print('✓ NullableProfile fromJson with missing keys');

  // ── 8. Enum invalid value edge case ──────────────────────────
  final badEnumJson = {...profileJson, 'role': 'unknown'};
  var threw = false;
  try {
    NullableProfile.fromJson(badEnumJson);
  } catch (_) {
    threw = true;
  }
  assert(threw);
  print('✓ Enum invalid value throws (expected)');

  // ── 9. copyWith updates nullable fields (non-null) ─────────
  final profile2 = profile.copyWith(
    website: 'https://example.com',
    followers: 123,
    marketingOptIn: true,
  );
  assert(profile2.website == 'https://example.com');
  assert(profile2.followers == 123);
  assert(profile2.marketingOptIn == true);
  print('✓ NullableProfile copyWith updates nullable fields');

  // ── 11. DTO in separate folder (Device + AuditLog) ─────────
  final deviceJson = {
    'deviceId': 'd-001',
    'type': 'mobile',
    'address': addressJson,
    'osVersion': '17.3',
    'isActive': true,
  };
  final device = Device.fromJson(deviceJson);
  assert(device.deviceId == 'd-001');
  assert(device.type == DeviceType.mobile);
  assert(device.address.city == 'Hanoi');
  assert(device.toJson()['type'] == 'mobile');

  final auditJson = {
    'id': 'audit-1',
    'timestamp': 1710000000,
    'device': deviceJson,
    'action': 'login',
    'success': true,
    'durationMs': 12,
  };
  final audit = AuditLog.fromJson(auditJson);
  assert(audit.device.deviceId == 'd-001');
  assert(audit.action == 'login');
  assert(audit.toJson()['durationMs'] == 12);
  final audit2 = audit.copyWith(action: 'logout');
  assert(audit2.action == 'logout');
  assert(audit2.device.deviceId == 'd-001');
  print('✓ DTO (Device + AuditLog) fromJson/toJson/copyWith');

  // ── 12. Bloc event/state classes (fromJson/toJson) ───────
  final requestedEventJson = {
    'userId': 'u-001',
    'forceReload': true,
    'correlationId': 'corr-1',
  };
  final requested = UserRequested.fromJson(requestedEventJson);
  assert(requested.forceReload == true);
  assert(requested.correlationId == 'corr-1');
  assert(requested.toJson()['correlationId'] == 'corr-1');

  final updatedEventJson = {
    'user': userJson,
    'status': 'active',
    'role': 'admin',
  };
  final updated = UserUpdated.fromJson(updatedEventJson);
  assert(updated.user.name == 'Tuan');
  assert(updated.status == Status.active);
  assert(updated.role == Role.admin);
  print('✓ Bloc events fromJson/toJson');

  final loadingStateJson = {
    'isLoading': true,
    'message': 'Fetching',
  };
  final loadingState = UserStateLoading.fromJson(loadingStateJson);
  assert(loadingState.isLoading == true);
  assert(loadingState.message == 'Fetching');
  assert(loadingState.toJson()['message'] == 'Fetching');

  final loadedStateJson = {
    'user': userJson,
    'lastKnownAddress': addressJson,
    'role': 'admin',
    'status': 'active',
  };
  final loadedState = UserStateLoaded.fromJson(loadedStateJson);
  assert(loadedState.user.id == 'u-001');
  assert(loadedState.lastKnownAddress.city == 'Hanoi');
  assert(loadedState.role == Role.admin);
  assert(loadedState.status == Status.active);

  final errorStateJson = {
    'errorCode': 'E_NETWORK',
    'errorMessage': null,
  };
  final errorState = UserStateError.fromJson(errorStateJson);
  assert(errorState.errorCode == 'E_NETWORK');
  assert(errorState.errorMessage == null);
  print('✓ Bloc states fromJson/toJson');

  // ── 10. Performance workload ────────────────────────────────
  final iterations = int.tryParse(
        const String.fromEnvironment(
          'VELTRO_PERF_ITERS',
          defaultValue: '2000',
        ),
      ) ??
      2000;

  final largeJson = <String, dynamic>{
    'id': 'lr-001',
    'age': 42,
    'isActive': true,
    'score': 98.6,
    'home': addressJson,
    'status': 'active',
    'role': 'admin',
    'owner': userJson,
    'nickname': 'Large Nick',
    'optionalAge': 43,
    'optionalFlag': false,
    'optionalScore': 0.5,
  };

  for (var i = 0; i < 20; i++) {
    largeJson['s$i'] = 's-$i';
  }
  for (var i = 0; i < 10; i++) {
    largeJson['i$i'] = i * 10;
  }
  for (var i = 0; i < 5; i++) {
    largeJson['b$i'] = i % 2 == 0;
  }
  for (var i = 0; i < 5; i++) {
    largeJson['d$i'] = i.toDouble() + 0.25;
  }

  final sw1 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    final rec = LargeRecord.fromJson(largeJson);
    rec.toJson();
  }
  sw1.stop();
  print(
    'Perf: LargeRecord fromJson+toJson x$iterations in ${sw1.elapsedMilliseconds}ms',
  );

  final sw2 = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    final rec = LargeRecord.fromJson(largeJson);
    rec.copyWith(
      nickname: 'nick$i',
      optionalAge: i,
      optionalFlag: i % 2 == 0,
      optionalScore: i.toDouble() * 1.5,
    );
  }
  sw2.stop();
  print(
    'Perf: LargeRecord fromJson+copyWith x$iterations in ${sw2.elapsedMilliseconds}ms',
  );
  print('\nAll assertions passed. Veltro output is correct.');
}
