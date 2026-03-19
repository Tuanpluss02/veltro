/// Veltro CLI launcher.
///
/// Downloads the platform-specific Rust binary from GitHub Releases,
/// caches it locally at ~/.veltro/bin/, and forwards all arguments.
library;

import 'dart:io';

import 'package:http/http.dart' as http;

/// GitHub repository for release downloads.
const _repo = 'tuanpluss02/veltro';

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
  final os = Platform.operatingSystem; // macos, linux
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
  // Dart doesn't expose arch directly, so we use `uname -m`
  try {
    final result = Process.runSync('uname', ['-m']);
    final arch = (result.stdout as String).trim();
    // Normalize: aarch64 → arm64
    if (arch == 'aarch64') return 'arm64';
    return arch;
  } catch (_) {
    return 'unknown';
  }
}

/// Downloads and caches the binary if needed. Returns the path to the binary.
Future<String> _ensureBinary() async {
  final platform = _platform();
  final binaryName = 'veltro-$_version-$platform';
  final binaryPath = '$_cacheDir/$binaryName';

  // Check cache
  if (File(binaryPath).existsSync()) {
    return binaryPath;
  }

  // Create cache directory
  Directory(_cacheDir).createSync(recursive: true);

  // Download
  final assetName = 'veltro-$platform';
  final url =
      'https://github.com/$_repo/releases/download/v$_version/$assetName';

  stderr.writeln('  Downloading Veltro v$_version for $platform...');

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      stderr.writeln('  Error: Failed to download binary (${response.statusCode})');
      stderr.writeln('  URL: $url');
      stderr.writeln('');
      stderr.writeln('  Make sure release v$_version exists with asset "$assetName".');
      exit(1);
    }

    // Write binary
    File(binaryPath).writeAsBytesSync(response.bodyBytes);

    // Make executable
    Process.runSync('chmod', ['+x', binaryPath]);

    stderr.writeln('  ✓ Cached at $binaryPath');
  } catch (e) {
    stderr.writeln('  Error: Could not download binary.');
    stderr.writeln('  $e');
    stderr.writeln('');
    stderr.writeln('  If you built Veltro locally, copy the binary to:');
    stderr.writeln('    $binaryPath');
    exit(1);
  }

  return binaryPath;
}

Future<void> main(List<String> args) async {
  final binaryPath = await _ensureBinary();

  // Forward all arguments to the Rust binary
  final process = await Process.start(
    binaryPath,
    args,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  exit(exitCode);
}
