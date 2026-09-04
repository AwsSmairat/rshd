import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/settings/data/models/student_settings_model.dart';

void main() {
  test('StudentSettingsModel parses API payload', () {
    final model = StudentSettingsModel.fromJson({
      'profile': {
        'id': 1,
        'name': 'أحمد',
        'email': 'student@test.com',
        'phone': '0790000000',
        'birth_date': '2000-01-01',
        'gender': 'male',
        'country': 'الأردن',
        'student_number': '1001',
        'role': 'student',
        'status': 'active',
        'avatar_url': null,
      },
      'preferences': {'notify_lessons': true, 'language': 'ar'},
      'devices': [],
    });

    expect(model.profile.name, 'أحمد');
    expect(model.profile.genderLabel, 'ذكر');
    expect(model.preferences.notifyLessons, isTrue);
    expect(model.preferences.language, 'ar');
  });

  test('StudentPreferencesModel serializes keys', () {
    const prefs = StudentPreferencesModel();
    expect(prefs.toJson()['notify_assignments'], isTrue);
    expect(prefs.toJson()['theme'], 'light');
  });

  test('StudentPreferencesModel reads Laravel 1/0 booleans', () {
    final prefs = StudentPreferencesModel.fromJson({
      'notify_lessons': 1,
      'notify_assignments': 0,
      'auto_play_video': '1',
      'save_watch_position': 'false',
      'two_factor_enabled': 1,
    });

    expect(prefs.notifyLessons, isTrue);
    expect(prefs.notifyAssignments, isFalse);
    expect(prefs.autoPlayVideo, isTrue);
    expect(prefs.saveWatchPosition, isFalse);
    expect(prefs.twoFactorEnabled, isTrue);
    // Absent keys keep their documented defaults.
    expect(prefs.notifyGrades, isTrue);
  });

  test('StudentSettingsModel tolerates a missing profile object', () {
    final model = StudentSettingsModel.fromJson({'preferences': {}});

    expect(model.profile.name, isEmpty);
    expect(model.devices, isEmpty);
  });
}
