import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/bump.dart <new_version>');
    stderr.writeln('Example: dart run tool/bump.dart 0.2.0');
    exit(1);
  }

  final newVersion = args.first.trim();
  
  // Basic validation for semver
  if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(newVersion)) {
    stderr.writeln('Error: Invalid version format. Must be x.y.z (e.g. 0.2.0)');
    exit(1);
  }

  // Paths
  final cargoToml = File('../Cargo.toml');
  final pubspecYaml = File('pubspec.yaml');
  final veltroDart = File('bin/veltro.dart');

  if (!cargoToml.existsSync() || !pubspecYaml.existsSync() || !veltroDart.existsSync()) {
    stderr.writeln('Error: Run this script from the dart_package directory:\n  cd dart_package && dart run tool/bump.dart $newVersion');
    exit(1);
  }

  // 1. Update Cargo.toml
  final cargoContent = cargoToml.readAsStringSync();
  final newCargoContent = cargoContent.replaceFirst(
    RegExp(r'version\s*=\s*"[^"]+"'),
    'version = "$newVersion"',
  );
  if (cargoContent != newCargoContent) {
    cargoToml.writeAsStringSync(newCargoContent);
    print('✅ Updated Cargo.toml to version $newVersion');
  } else {
    print('⚠ Cargo.toml unchanged (version may already be $newVersion)');
  }

  // 2. Update pubspec.yaml
  final pubspecContent = pubspecYaml.readAsStringSync();
  final newPubspecContent = pubspecContent.replaceFirst(
    RegExp(r'^version:\s*.*$', multiLine: true),
    'version: $newVersion',
  );
  if (pubspecContent != newPubspecContent) {
    pubspecYaml.writeAsStringSync(newPubspecContent);
    print('✅ Updated pubspec.yaml to version $newVersion');
  } else {
    print('⚠ pubspec.yaml unchanged');
  }

  // 3. Update bin/veltro.dart
  final veltroContent = veltroDart.readAsStringSync();
  final newVeltroContent = veltroContent.replaceFirst(
    RegExp(r"const _version\s*=\s*'[^']+';"),
    "const _version = '$newVersion';",
  );
  if (veltroContent != newVeltroContent) {
    veltroDart.writeAsStringSync(newVeltroContent);
    print('✅ Updated bin/veltro.dart to version $newVersion');
  } else {
    print('⚠ bin/veltro.dart unchanged');
  }

  print('\n🎉 All versions bumped to $newVersion successfully!');
  print('Remember to update the changelog before committing.');
}
