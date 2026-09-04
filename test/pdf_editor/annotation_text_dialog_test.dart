import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/widgets/annotation_text_dialog.dart';

Future<String?> _open(
  WidgetTester tester, {
  String initialText = '',
  VoidCallback? onDelete,
}) async {
  String? result;
  late BuildContext pageContext;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          pageContext = context;
          return const Scaffold(body: SizedBox());
        },
      ),
    ),
  );

  showDialog<String>(
    context: pageContext,
    builder: (context) => AnnotationTextDialog(
      title: 'إضافة نص',
      hintText: 'اكتب النص',
      initialText: initialText,
      cancelLabel: 'إلغاء',
      confirmLabel: 'إضافة',
      deleteLabel: onDelete == null ? null : 'حذف',
      onDelete: onDelete,
    ),
  ).then((value) => result = value);

  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('returns typed text and survives the exit transition', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'ملاحظة جديدة');
    await tester.tap(find.text('إضافة'));
    // Settling drives the dialog's exit animation, which used to rebuild the
    // TextField after the controller had already been disposed.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('cancel closes without an exception', (tester) async {
    await _open(tester, initialText: 'نص سابق');

    expect(find.text('نص سابق'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('delete runs the callback then closes', (tester) async {
    var deleted = false;
    await _open(tester, initialText: 'نص', onDelete: () => deleted = true);

    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
  });
}
