import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/pdf_editor/controllers/pdf_editor_controller.dart';
import 'package:rshd/features/pdf_editor/models/annotation_enums.dart';
import 'package:rshd/features/pdf_editor/models/pdf_editor_models.dart';
import 'package:rshd/features/pdf_editor/utils/annotation_hit_test.dart';
import 'package:rshd/features/subjects/data/subjects_repository.dart';

class _FakeSubjectsRepository implements SubjectsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late PdfEditorController controller;

  setUp(() {
    controller = PdfEditorController(_FakeSubjectsRepository(), 42);
  });

  tearDown(() {
    controller.dispose();
  });

  test('default tool is view', () {
    expect(controller.state.currentTool, PdfEditorTool.view);
  });

  test('clicking pen activates pen', () {
    controller.setTool(PdfEditorTool.pen);
    expect(controller.state.currentTool, PdfEditorTool.pen);
  });

  test('clicking highlight activates highlighter', () {
    controller.setTool(PdfEditorTool.highlighter);
    expect(controller.state.currentTool, PdfEditorTool.highlighter);
  });

  test('only one active tool at a time', () {
    controller.setTool(PdfEditorTool.pen);
    controller.setTool(PdfEditorTool.text);
    expect(controller.state.currentTool, PdfEditorTool.text);
    expect(controller.state.currentTool, isNot(PdfEditorTool.pen));
  });

  test('pen stroke creates ink annotation', () {
    controller.addInkStroke(
      pageNumber: 1,
      points: const [
        NormalizedPoint(0.1, 0.1),
        NormalizedPoint(0.2, 0.2),
      ],
      type: AnnotationType.ink,
      color: Colors.black,
      strokeWidth: 0.004,
      opacity: 1,
    );

    final annotations = controller.state.document.annotationsForPage(1);
    expect(annotations, hasLength(1));
    expect(annotations.first.type, AnnotationType.ink);
  });

  test('highlight creates highlighter annotation', () {
    controller.addInkStroke(
      pageNumber: 1,
      points: const [
        NormalizedPoint(0.1, 0.1),
        NormalizedPoint(0.2, 0.2),
      ],
      type: AnnotationType.highlighter,
      color: Colors.yellow,
      strokeWidth: 0.02,
      opacity: 0.35,
    );

    final annotations = controller.state.document.annotationsForPage(1);
    expect(annotations.first.type, AnnotationType.highlighter);
    expect(annotations.first.data['opacity'], 0.35);
  });

  test('text creates text annotation', () {
    controller.addTextBox(
      pageNumber: 1,
      x: 0.2,
      y: 0.2,
      text: 'Hello',
    );

    final annotations = controller.state.document.annotationsForPage(1);
    expect(annotations.first.type, AnnotationType.text);
    expect(annotations.first.data['text'], 'Hello');
  });

  test('Arabic text stores RTL direction', () {
    controller.addTextBox(
      pageNumber: 1,
      x: 0.2,
      y: 0.2,
      text: 'مرحبا',
    );

    final annotations = controller.state.document.annotationsForPage(1);
    expect(annotations.first.data['text_direction'], 'rtl');
  });

  test('English text stores LTR direction', () {
    controller.addTextBox(
      pageNumber: 1,
      x: 0.2,
      y: 0.2,
      text: 'Hello',
    );

    final annotations = controller.state.document.annotationsForPage(1);
    expect(annotations.first.data['text_direction'], 'ltr');
  });

  test('note creates note annotation', () {
    controller.addNote(
      pageNumber: 1,
      x: 0.3,
      y: 0.3,
      text: 'ملاحظة',
    );

    final annotations = controller.state.document.annotationsForPage(1);
    expect(annotations.first.type, AnnotationType.note);
  });

  test('rectangle creates shape annotation', () {
    controller.addShape(
      pageNumber: 1,
      shape: PdfEditorShapeTool.rectangle,
      x: 0.1,
      y: 0.1,
      width: 0.2,
      height: 0.1,
      strokeColor: Colors.blue,
      strokeWidth: 0.004,
      opacity: 1,
    );

    expect(
      controller.state.document.annotationsForPage(1).first.data['shape'],
      'rectangle',
    );
  });

  test('ellipse creates shape annotation', () {
    controller.addShape(
      pageNumber: 1,
      shape: PdfEditorShapeTool.circle,
      x: 0.1,
      y: 0.1,
      width: 0.2,
      height: 0.2,
      strokeColor: Colors.blue,
      strokeWidth: 0.004,
      opacity: 1,
    );

    expect(
      controller.state.document.annotationsForPage(1).first.data['shape'],
      'circle',
    );
  });

  test('line creates shape annotation', () {
    controller.addShape(
      pageNumber: 1,
      shape: PdfEditorShapeTool.line,
      x: 0.1,
      y: 0.1,
      width: 0.3,
      height: 0.3,
      strokeColor: Colors.blue,
      strokeWidth: 0.004,
      opacity: 1,
    );

    expect(
      controller.state.document.annotationsForPage(1).first.data['shape'],
      'line',
    );
  });

  test('arrow creates shape annotation', () {
    controller.addShape(
      pageNumber: 1,
      shape: PdfEditorShapeTool.arrow,
      x: 0.1,
      y: 0.1,
      width: 0.3,
      height: 0.3,
      strokeColor: Colors.blue,
      strokeWidth: 0.004,
      opacity: 1,
    );

    expect(
      controller.state.document.annotationsForPage(1).first.data['shape'],
      'arrow',
    );
  });

  test('eraser whole mode removes ink annotation', () {
    controller.setEraserMode(EraserMode.whole);
    controller.addInkStroke(
      pageNumber: 1,
      points: const [
        NormalizedPoint(0.1, 0.1),
        NormalizedPoint(0.2, 0.2),
      ],
      type: AnnotationType.ink,
      color: Colors.black,
      strokeWidth: 0.004,
      opacity: 1,
    );

    controller.eraseAtPoint(
      pageNumber: 1,
      point: const NormalizedPoint(0.12, 0.12),
      radius: 0.08,
    );

    expect(controller.state.document.annotationsForPage(1), isEmpty);
  });

  test('selection stores selected annotation id', () {
    controller.addTextBox(pageNumber: 1, x: 0.2, y: 0.2, text: 'test');
    final id = controller.state.document.annotationsForPage(1).first.id;
    controller.selectAnnotation(id);
    expect(controller.state.selectedAnnotationId, id);
  });

  test('undo restores previous state', () {
    controller.addTextBox(pageNumber: 1, x: 0.2, y: 0.2, text: 'first');
    controller.addTextBox(pageNumber: 1, x: 0.3, y: 0.3, text: 'second');
    expect(controller.state.document.annotationsForPage(1), hasLength(2));

    controller.undo();
    expect(controller.state.document.annotationsForPage(1), hasLength(1));
  });

  test('redo restores undone state', () {
    controller.addTextBox(pageNumber: 1, x: 0.2, y: 0.2, text: 'first');
    controller.addTextBox(pageNumber: 1, x: 0.3, y: 0.3, text: 'second');
    controller.undo();
    controller.redo();
    expect(controller.state.document.annotationsForPage(1), hasLength(2));
  });

  test('redo stack clears after new action', () {
    controller.addTextBox(pageNumber: 1, x: 0.2, y: 0.2, text: 'first');
    controller.undo();
    expect(controller.canRedo, isTrue);

    controller.addTextBox(pageNumber: 1, x: 0.4, y: 0.4, text: 'third');
    expect(controller.canRedo, isFalse);
  });

  test('undo button disabled when no history', () {
    expect(controller.canUndo, isFalse);
  });

  test('redo button disabled when no redo stack', () {
    expect(controller.canRedo, isFalse);
  });

  test('toolbar collapse toggles expanded state', () {
    expect(controller.state.toolbarExpanded, isTrue);
    controller.toggleToolbarExpanded();
    expect(controller.state.toolbarExpanded, isFalse);
  });

  test('annotations mark pending sync after add', () {
    controller.addNote(pageNumber: 1, x: 0.1, y: 0.1, text: 'offline');
    expect(controller.state.pendingSync, isTrue);
    expect(controller.state.hasUnsavedChanges, isTrue);
  });

  test('hit test finds ink annotation', () {
    final annotation = PdfEditorAnnotation(
      id: 'ink-1',
      type: AnnotationType.ink,
      pageNumber: 1,
      data: {
        'points': [
          {'nx': 0.1, 'ny': 0.1},
          {'nx': 0.2, 'ny': 0.2},
        ],
      },
    );

    final hit = AnnotationHitTest.findAt(
      [annotation],
      const NormalizedPoint(0.12, 0.12),
      tolerance: 0.05,
    );

    expect(hit?.id, 'ink-1');
  });

  test('pen settings persist in same session', () {
    controller.setPenSettings(
      controller.state.penSettings.copyWith(color: Colors.red),
    );
    controller.setTool(PdfEditorTool.view);
    controller.setTool(PdfEditorTool.pen);
    expect(controller.state.penSettings.color, Colors.red);
  });
}
