enum PdfEditorTool {
  view,
  pen,
  highlighter,
  eraser,
  lasso,
  text,
  note,
  shapes,
}

enum EraserMode {
  partial,
  whole,
}

enum ShapeKind {
  freehand,
  line,
  arrow,
  rectangle,
  square,
  circle,
}

enum PenKind {
  ink,
  pencil,
}

enum AnnotationType {
  ink,
  highlighter,
  text,
  note,
  shape,
  image,
}

enum PdfSaveStatus {
  saved,
  saving,
  unsaved,
  failed,
  offlinePending,
}

enum PdfEditorShapeTool {
  line,
  arrow,
  rectangle,
  circle,
  square,
}
