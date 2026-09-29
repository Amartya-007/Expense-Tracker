import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static bool _enabledCache = true;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabledCache = prefs.getBool(_keyHapticsEnabled) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    _enabledCache = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHapticsEnabled, enabled);
  }

  static bool get isEnabled => _enabledCache;

  static Future<void> success() async {
    if (!_enabledCache) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> warning() async {
    if (!_enabledCache) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> selection() async {
    if (!_enabledCache) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> light() async {
    if (!_enabledCache) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
