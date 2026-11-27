import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import 'app_theme.dart';

/// Holds the user's chosen theme and saves it to Hive.
///
/// `value` is null until the user has picked a theme (first launch).
class ThemeController extends ValueNotifier<AppThemeChoice?> {
  ThemeController._() : super(null);

  static final ThemeController instance = ThemeController._();

  Box get _box => Hive.box(AppConstants.settingsBox);

  /// Call once at startup, after the settings box is open.
  void load() {
    final saved = _box.get(AppConstants.themeKey) as String?;
    value = AppThemeChoice.values.where((c) => c.name == saved).firstOrNull;
  }

  Future<void> select(AppThemeChoice choice) async {
    value = choice;
    await _box.put(AppConstants.themeKey, choice.name);
  }
}
