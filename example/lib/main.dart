import 'models/address.dart';
import 'models/api_response.dart';
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

  print('\nAll assertions passed. Veltro output is correct.');
}
