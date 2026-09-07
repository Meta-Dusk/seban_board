import 'dart:io';

import 'package:win32_registry/win32_registry.dart';
import 'package:package_info_plus/package_info_plus.dart';

class StartupService {
  // This is the standard Windows registry path for startup apps
  static const String _runKeyPath =
      r'Software\Microsoft\Windows\CurrentVersion\Run';

  static Future<void> toggleStartup(bool enable) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;
    final executablePath = Platform.resolvedExecutable;

    // Use the top-level CURRENT_USER constant
    final key = CURRENT_USER.open(
      _runKeyPath,
      // Allow writing
      config: const RegistryOpenConfig(access: .all),
    );

    if (enable) {
      key.setValue(appName, RegistryValue.string('"$executablePath"'));
    } else {
      try {
        key.removeValue(appName);
      } catch (_) {
        // Silently ignore if the value doesn't exist
      }
    }
    key.close();
  }

  static Future<bool> isEnabled() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;

    try {
      final key = CURRENT_USER.open(
        _runKeyPath,
        config: const RegistryOpenConfig(),
      );

      final value = key.getString(appName);
      key.close();

      return value != null;
    } catch (_) {
      return false; // Returns false if the key cannot be read or doesn't exist
    }
  }
}
