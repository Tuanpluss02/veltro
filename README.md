# Veltro

Veltro is a blazingly fast Dart code generator powered by Rust. It automatically generates `fromJson`, `toJson`, `copyWith`, `==`, `hashCode`, and `toString` methods for your Dart data classes using the Freezed/built_value mixin pattern.


## Features

- **Rust-powered**: Full builds take milliseconds, not seconds.
- **Mixin Pattern**: Safe, clean, and extensible generated code (`with _$ClassName`).
- **Smart Caching**: Content hashing ensures files are only written when changed.
- **Zero Config**: Scans `lib/` recursively. No `build.yaml` needed.
- **Cross Platform**: Pre-compiled binaries for macOS (Apple Silicon + Intel) and Linux.

## Installation

Add to your project's `pubspec.yaml`:

```yaml
dev_dependencies:
  veltro: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

```bash
# Generate all .g.dart files
dart run veltro build

# Watch for changes
dart run veltro watch

# Delete all generated files
dart run veltro clean
```

If you use FVM:

```bash
fvm dart run veltro build
```

### 1. Annotate your classes

Use the `@Data()` annotation and the `with _$ClassName` mixin on your classes. 

```dart
import 'package:veltro/veltro.dart';

part 'user.g.dart';

@Data()
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required int age,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 2. Run Veltro

```bash
veltro build
```

This will instantly generate all `.g.dart` files across your `lib/` directory.

### CLI Commands

- `veltro build`: Scan `lib/`, generate all `.g.dart` files, and exit.
- `veltro watch`: Run build, then watch `lib/` for changes continuously.
- `veltro clean`: Delete all generated `.g.dart` files under `lib/`.

## For Maintainers: Releasing a New Version

Veltro uses a synchronized versioning system across its Rust binary (`Cargo.toml`), Dart package (`pubspec.yaml`), and CLI launcher (`bin/veltro.dart`).

To publish a new version, run the included `bump.dart` script:

```bash
cd dart_package
dart run tool/bump.dart <new_version>
# Example: dart run tool/bump.dart 0.0.2
```

This ensures the Dart CLI downloads the correct Rust binary from GitHub Releases. After bumping:
1. Commit the changes
2. Push a new tag (e.g., `git tag v0.0.2 && git push --tags`)
3. GitHub Actions will automatically build and publish the Rust binaries.
