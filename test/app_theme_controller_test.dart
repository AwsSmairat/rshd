import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/theme/app_theme_controller.dart';

void main() {
  test('maps stored preference to ThemeMode', () {
    expect(themeModeFromPreference('light'), ThemeMode.light);
    expect(themeModeFromPreference('dark'), ThemeMode.dark);
    expect(themeModeFromPreference('system'), ThemeMode.system);
    expect(themeModeFromPreference('unknown'), ThemeMode.light);
  });
}
