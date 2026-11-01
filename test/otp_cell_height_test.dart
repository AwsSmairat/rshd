import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rshd/features/auth/presentation/widgets/otp_input_row.dart';

/// Roughly the width the row gets inside the auth card on a phone.
const _cardInnerWidth = 352.0;

Widget _harness(OtpStatus status) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: _cardInnerWidth,
        child: OtpInputRow(length: 6, status: status, onCompleted: (_) {}),
      ),
    ),
  ),
);

void main() {
  testWidgets('otp cells are tall enough to read and to tap', (tester) async {
    await tester.pumpWidget(_harness(OtpStatus.idle));
    await tester.pumpAndSettle();

    final cells = find.byType(TextField);
    expect(cells, findsNWidgets(6));

    // A dense decoration with zero padding used to collapse the bordered box
    // to roughly 20pt and leave dead space under the row.
    final cell = tester.getRect(cells.first);
    expect(cell.height, greaterThanOrEqualTo(56));
    expect(
      cell.height,
      greaterThan(cell.width),
      reason: 'at phone width a cell should be taller than it is wide',
    );

    // The row must be exactly as tall as a cell — no slack underneath.
    final rowHeight = tester.getRect(find.byType(OtpInputRow)).height;
    expect(rowHeight, closeTo(cell.height, 1));
  });

  testWidgets('verified status turns every cell into a green check', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(OtpStatus.verified));
    await tester.pumpAndSettle();

    // No editable cells remain, and every slot carries a check.
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(6));

    // The row keeps its footprint, so nothing jumps on verification.
    expect(tester.getRect(find.byType(OtpInputRow)).height, greaterThan(50));
  });
}
