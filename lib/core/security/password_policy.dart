import '../l10n/app_strings.dart';

/// One requirement a new password must meet.
class PasswordRequirement {
  const PasswordRequirement({
    required this.arabic,
    required this.english,
    required this.isMetBy,
  });

  final String arabic;
  final String english;
  final bool Function(String password) isMetBy;

  String label(AppStrings strings) => strings.isEnglish ? english : arabic;
}

/// Keeps a Latin run (a range, symbols) in its own order inside Arabic text,
/// which would otherwise show "(0-9)" as "(9-0)".
String _ltr(String text) => '\u2066$text\u2069';

/// The password rules, the same as the server's: at least [minLength]
/// characters, an uppercase English letter, a digit and a special character.
abstract final class PasswordPolicy {
  static const minLength = 9;

  static final requirements = <PasswordRequirement>[
    PasswordRequirement(
      arabic: '$minLength أحرف على الأقل',
      english: 'At least $minLength characters',
      isMetBy: (p) => p.runes.length >= minLength,
    ),
    PasswordRequirement(
      arabic: 'حرف إنجليزي كبير ${_ltr('(A-Z)')}',
      english: 'An uppercase letter (A-Z)',
      isMetBy: (p) => RegExp(r'[A-Z]').hasMatch(p),
    ),
    PasswordRequirement(
      arabic: 'رقم ${_ltr('(0-9)')}',
      english: 'A number (0-9)',
      isMetBy: (p) => RegExp(r'[0-9]').hasMatch(p),
    ),
    PasswordRequirement(
      arabic: 'رمز خاص مثل ${_ltr(r'! @ # $')}',
      english: r'A special character such as ! @ # $',
      isMetBy: (p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p),
    ),
  ];

  static bool isValid(String password) =>
      requirements.every((r) => r.isMetBy(password));

  /// A form-field validator naming everything still missing.
  static String? validate(String? password, AppStrings strings) {
    final missing = requirements
        .where((r) => !r.isMetBy(password ?? ''))
        .map((r) => r.label(strings))
        .toList();
    if (missing.isEmpty) {
      return null;
    }
    return strings.isEnglish
        ? 'Your password needs: ${missing.join(', ')}.'
        : 'كلمة المرور يجب أن تحتوي على: ${missing.join('، ')}.';
  }
}
