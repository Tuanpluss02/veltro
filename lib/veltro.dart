/// Controls how field names are converted to JSON keys.
enum FieldRename {
  /// No conversion — field name used as-is. (default)
  none,

  /// camelCase → snake_case. e.g. firstName → first_name
  snake,

  /// camelCase → kebab-case. e.g. firstName → first-name
  kebab,

  /// camelCase → SCREAMING_SNAKE_CASE. e.g. firstName → FIRST_NAME
  screamingSnake,

  /// camelCase → PascalCase. e.g. firstName → FirstName
  pascal,
}

/// Marks a class for Veltro code generation.
///
/// Covers both serializable DTOs and Bloc state/event classes.
///
/// ## DTO example
/// ```dart
/// @Veltro(fieldRename: FieldRename.snake)
/// abstract class UserDto with _$UserDto {
///   const factory UserDto({required String userId}) = _UserDto;
/// }
/// ```
///
/// ## Bloc State example
/// ```dart
/// @Veltro(json: false)
/// abstract class CounterState with _$CounterState {
///   const factory CounterState({
///     @Default(0) int count,
///   }) = _CounterState;
/// }
/// ```
class Veltro {
  /// Whether to generate fromJson and toJson.
  /// Set to false for Bloc state/event classes.
  /// Default: true.
  final bool json;

  /// How field names are converted to JSON keys.
  /// Only applies when [json] is true.
  /// Default: FieldRename.none.
  final FieldRename fieldRename;

  /// Whether nullable fields with null value are included in toJson output.
  /// Only applies when [json] is true.
  /// Default: true.
  final bool includeIfNull;

  /// Whether to generate copyWith.
  /// Set to false for Bloc event classes that are never mutated.
  /// Default: true.
  final bool copyWith;

  const Veltro({
    this.json = true,
    this.fieldRename = FieldRename.none,
    this.includeIfNull = true,
    this.copyWith = true,
  });
}

/// Provides a default value for a field in a @Veltro() class.
///
/// The value is copied verbatim into the generated constructor.
/// Type checking is performed by the Dart compiler on the generated file.
///
/// ```dart
/// @Veltro(json: false)
/// abstract class AppState with _$AppState {
///   const factory AppState({
///     @Default(false) bool isLoading,
///     @Default(ThemeMode.dark) ThemeMode themeMode,
///   }) = _AppState;
/// }
/// ```
class Default<T> {
  final T value;
  const Default(this.value);
}

/// Marks an external enum for Veltro type resolution.
///
/// Use when an enum is imported from another package and
/// Veltro cannot detect it via the `enum` keyword in your source.
class IsEnum {
  const IsEnum();
}
