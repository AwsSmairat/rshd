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
}
