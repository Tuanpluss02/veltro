/// Marks a class for Veltro code generation.
///
/// Veltro will generate: `fromJson`, `toJson`, `copyWith`,
/// `==`, `hashCode`, and `toString` for the annotated class.
///
/// Example:
/// ```dart
/// @Data()
/// class User {
///   const factory User({
///     required String id,
///     required String name,
///   }) = _User;
/// }
/// ```
class Data {
  const Data();
}

/// Marks an external enum for Veltro type resolution.
///
/// Use this when an enum is imported from another package and
/// Veltro cannot detect it via the `enum` keyword in your source.
///
/// Example:
/// ```dart
/// @IsEnum()
/// class Status { ... }
/// ```
class IsEnum {
  const IsEnum();
}
