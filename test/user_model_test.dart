import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/auth/data/models/user_model.dart';

void main() {
  test('UserModel parses an integer id', () {
    final user = UserModel.fromJson({
      'id': 42,
      'name': 'أحمد',
      'email': 'student@test.com',
      'role': 'student',
      'status': 'active',
    });

    expect(user.id, 42);
    expect(user.isStudent, isTrue);
  });

  test('UserModel parses a string id without throwing', () {
    final user = UserModel.fromJson({
      'id': '42',
      'name': 'أحمد',
      'email': 'student@test.com',
      'role': 'student',
      'status': 'active',
    });

    expect(user.id, 42);
  });

  test('UserModel falls back to 0 for an unusable id', () {
    final user = UserModel.fromJson({
      'name': 'أحمد',
      'email': 'student@test.com',
      'role': 'student',
      'status': 'active',
    });

    expect(user.id, 0);
  });
}
