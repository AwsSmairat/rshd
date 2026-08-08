import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/models/annotation_enums.dart';
import 'package:rshd/features/pdf_editor/widgets/pdf_editor_toolbar.dart';

void main() {
  testWidgets('toolbar shows primary tools and expands secondary row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PdfEditorToolbar(
            currentTool: PdfEditorTool.view,
            canUndo: false,
            canRedo: false,
            visible: true,
            expanded: true,
            isTabletLandscape: false,
            onToolSelected: (_) {},
            onUndo: () {},
            onRedo: () {},
            onToggleExpanded: () {},
            onToggleVisibility: () {},
          ),
        ),
      ),
    );

    expect(find.text('عرض'), findsOneWidget);
    expect(find.text('قلم'), findsOneWidget);
    expect(find.text('نص'), findsOneWidget);
    expect(find.text('تراجع'), findsOneWidget);
  });

  testWidgets('collapsed toolbar hides secondary row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PdfEditorToolbar(
            currentTool: PdfEditorTool.view,
            canUndo: false,
            canRedo: false,
            visible: true,
            expanded: false,
            isTabletLandscape: false,
            onToolSelected: (_) {},
            onUndo: () {},
            onRedo: () {},
            onToggleExpanded: () {},
            onToggleVisibility: () {},
          ),
        ),
      ),
    );

    expect(find.text('عرض'), findsOneWidget);
    expect(find.text('نص'), findsNothing);
    expect(find.text('تراجع'), findsNothing);
  });

  testWidgets('undo disabled styling when canUndo is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PdfEditorToolbar(
            currentTool: PdfEditorTool.view,
            canUndo: false,
            canRedo: false,
            visible: true,
            expanded: true,
            isTabletLandscape: false,
            onToolSelected: (_) {},
            onUndo: () {},
            onRedo: () {},
            onToggleExpanded: () {},
            onToggleVisibility: () {},
          ),
        ),
      ),
    );

    final undoButton = find.ancestor(
      of: find.text('تراجع'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(undoButton).onTap, isNull);
  });
}
