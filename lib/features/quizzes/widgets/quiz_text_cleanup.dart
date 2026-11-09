/// Quiz text as written by instructors often repeats what the screen already
/// shows: "1. The question…" and "a) Anoxia". The screen numbers questions and
/// letters answers itself, so those leading labels are dropped for display.
abstract final class QuizTextCleanup {
  static final _questionNumber = RegExp(r'^\s*\(?\d{1,3}\s*[\.\)\-:]\s*');
  static final _optionLabel = RegExp(
    r'^\s*\(?([a-hA-H]|[أبجدهوزح])\s*[\)\.\-:]\s*',
  );

  static String question(String text) {
    final stripped = text.replaceFirst(_questionNumber, '').trim();
    return stripped.isEmpty ? text.trim() : stripped;
  }

  /// Drops "a)", "(b)", "c." … only when every option has such a label, so
  /// an answer that merely starts with a letter is left alone.
  static List<String> options(List<String> options) {
    if (options.length < 2 || !options.every(_optionLabel.hasMatch)) {
      return [for (final option in options) option.trim()];
    }
    return [
      for (final option in options)
        () {
          final stripped = option.replaceFirst(_optionLabel, '').trim();
          return stripped.isEmpty ? option.trim() : stripped;
        }(),
    ];
  }

  static const _latinLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  static const _arabicLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];

  static String letter(int index, {required bool latin}) {
    final letters = latin ? _latinLetters : _arabicLetters;
    return index < letters.length ? letters[index] : '${index + 1}';
  }
}
