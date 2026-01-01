import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // GitHub releases API URL - Update this with your actual repo
  static const String _githubApiUrl =
      'https://api.github.com/repos/kreoecosystem/kreonotes/releases/latest';

  static const String _downloadBaseUrl =
      'https://github.com/kreoecosystem/kreonotes/releases/latest/download/kreonotes.apk';

  String? _currentVersion;
  String? _latestVersion;
  String? _downloadUrl;
  String? _releaseNotes;

  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
  }

  String get currentVersion => _currentVersion ?? '1.0.0';
  String? get latestVersion => _latestVersion;
  String? get downloadUrl => _downloadUrl;
  String? get releaseNotes => _releaseNotes;

  /// Checks for updates from GitHub releases
  /// Returns true if an update is available
  Future<UpdateResult> checkForUpdates() async {
    try {
      await init();

      final response = await http
          .get(
            Uri.parse(_githubApiUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _latestVersion =
            (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '1.0.0';
        _releaseNotes = data['body'] as String?;

        // Find APK asset
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final name = asset['name'] as String?;
            if (name != null && name.endsWith('.apk')) {
              _downloadUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        // Fallback download URL
        _downloadUrl ??= _downloadBaseUrl;

        if (_isNewerVersion(_latestVersion!, _currentVersion!)) {
          return UpdateResult(
            available: true,
            currentVersion: _currentVersion!,
            latestVersion: _latestVersion!,
            downloadUrl: _downloadUrl,
            releaseNotes: _releaseNotes,
          );
        } else {
          return UpdateResult(
            available: false,
            currentVersion: _currentVersion!,
            latestVersion: _latestVersion!,
          );
        }
      } else if (response.statusCode == 404) {
        // No releases yet
        return UpdateResult(
          available: false,
          currentVersion: _currentVersion!,
          latestVersion: _currentVersion!,
          error: 'No releases available yet',
        );
      } else {
        return UpdateResult(
          available: false,
          currentVersion: _currentVersion!,
          latestVersion: _currentVersion!,
          error: 'Failed to check updates (${response.statusCode})',
        );
      }
    } catch (e) {
      return UpdateResult(
        available: false,
        currentVersion: _currentVersion ?? '1.0.0',
        latestVersion: _currentVersion ?? '1.0.0',
        error: 'Network error: Unable to check for updates',
      );
    }
  }

  /// Compares version strings (e.g., "1.0.1" > "1.0.0")
  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}

class UpdateResult {
  final bool available;
  final String currentVersion;
  final String latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? error;

  UpdateResult({
    required this.available,
    required this.currentVersion,
    required this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.error,
  });
}
