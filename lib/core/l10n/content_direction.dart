import 'package:flutter/widgets.dart';

/// The reading direction of a piece of user content (a question, an answer),
/// taken from its first strong letter. English content inside the Arabic UI
/// then reads left to right, with its punctuation where the author put it.
TextDirection contentDirectionOf(String text, {TextDirection? fallback}) {
  for (final rune in text.runes) {
    if (_isRtl(rune)) return TextDirection.rtl;
    if (_isLtr(rune)) return TextDirection.ltr;
  }
  return fallback ?? TextDirection.rtl;
}

bool _isRtl(int c) =>
    (c >= 0x0590 && c <= 0x08FF) || // Hebrew, Arabic, Syriac, Thaana, …
    (c >= 0xFB1D && c <= 0xFDFF) || // presentation forms A
    (c >= 0xFE70 && c <= 0xFEFF); // presentation forms B

bool _isLtr(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0xC0 && c <= 0x24F) || // Latin-1 and Latin Extended letters
    (c >= 0x370 && c <= 0x3FF); // Greek (α, β in science questions)
