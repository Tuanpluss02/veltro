/// Veltro CLI launcher.
///
/// Downloads the platform-specific Rust binary from GitHub Releases,
/// caches it locally, and forwards all arguments. Also handles version
/// checking and updating via pub_updater.
library;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pub_updater/pub_updater.dart';

/// The package name on pub.dev.
const _packageName = 'veltro';

/// GitHub repository for release downloads.
const _repo = 'Tuanpluss02/veltro_core';

/// Must match the version in pubspec.yaml.
const _version = '0.0.1';

/// Cache directory for downloaded binaries.
String get _cacheDir {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  return '$home/.veltro/bin';
}

/// Resolves the platform identifier for the current OS and architecture.
String _platform() {
  final os = Platform.operatingSystem;
  final arch = _architecture();

  if (os == 'macos' && arch == 'arm64') return 'macos-arm64';
  if (os == 'macos' && arch == 'x86_64') return 'macos-x86_64';
  if (os == 'linux' && arch == 'x86_64') return 'linux-x86_64';

  stderr.writeln('  Error: Unsupported platform: $os-$arch');
  stderr.writeln('  Veltro supports: macOS (arm64, x86_64), Linux (x86_64)');
  exit(1);
}

/// Detects CPU architecture.
String _architecture() {
  try {
    final result = Process.runSync('uname', ['-m']);
    final arch = (result.stdout as String).trim();
    if (arch == 'aarch64') return 'arm64';
    return arch;
  } catch (_) {
    return 'unknown';
  }
}

/// Downloads and caches the binary if needed.
Future<String> _ensureBinary() async {
  final platform = _platform();
  final binaryName = 'veltro_core-$_version-$platform';
  final binaryPath = '$_cacheDir/$binaryName';

  if (File(binaryPath).existsSync()) {
    return binaryPath;
  }

  Directory(_cacheDir).createSync(recursive: true);

  final assetName = 'veltro_core-$platform';
  final url =
      'https://github.com/$_repo/releases/download/v$_version/$assetName';

  stdout.writeln('  Downloading Veltro v$_version for $platform...');

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      stderr.writeln(
        '  Error: Failed to download binary (${response.statusCode})',
      );
      stderr.writeln('  URL: $url');
      exit(1);
    }

    File(binaryPath).writeAsBytesSync(response.bodyBytes);
    Process.runSync('chmod', ['+x', binaryPath]);

    stdout.writeln('  ✓ Cached at $binaryPath\n');
  } catch (e) {
    stderr.writeln('  Error: Could not download binary.');
    stderr.writeln('  $e');
    exit(1);
  }

  return binaryPath;
}

Future<void> main(List<String> args) async {
  // Handle built-in Dart commands
  if (args.isNotEmpty) {
    final command = args.first;

    if (command == '--version' || command == '-v') {
      stdout.writeln('Veltro v$_version');
      return;
    }

    if (command == 'update') {
      await _handleUpdate();
      return;
    }
  }

  // Ensure Rust binary is ready
  final binaryPath = await _ensureBinary();

  // Forward all arguments to the Rust binary
  final process = await Process.start(
    binaryPath,
    args,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;

  // Check for updates in the background after the command completes
  await _checkVersion();

  exit(exitCode);
}

/// Checks pub.dev for a newer version of Veltro.
Future<void> _checkVersion() async {
  try {
    final pubUpdater = PubUpdater();
    final isUpToDate = await pubUpdater.isUpToDate(
      packageName: _packageName,
      currentVersion: _version,
    );

    if (!isUpToDate) {
      final latestVersion = await pubUpdater.getLatestVersion(_packageName);
      stdout.writeln('');
      stdout.writeln('  A new version of Veltro is available!');
      stdout.writeln('  $_version -> $latestVersion');
      stdout.writeln('  Run "veltro update" to update.');
    }
  } catch (_) {
    // Silently fail version check to avoid annoying the user
  }
}

/// Updates the Veltro CLI via pub global activate.
Future<void> _handleUpdate() async {
  stdout.writeln('Updating Veltro...');
  try {
    final pubUpdater = PubUpdater();
    await pubUpdater.update(packageName: _packageName);
    stdout.writeln('✓ Successfully updated Veltro.');
  } catch (e) {
    stderr.writeln('Failed to update Veltro: $e');
    exit(1);
  }
}
