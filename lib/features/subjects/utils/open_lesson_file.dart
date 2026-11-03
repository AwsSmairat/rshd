import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../data/models/lesson_file_model.dart';

/// Opens a lesson file the way a student expects: straight into the in-app
/// viewer when it can be viewed. Only files that can't be shown yet (still
/// being prepared, or an unsupported type) go to the file page, which
/// explains why. Locked files just say so.
void openLessonFile(BuildContext context, LessonFileModel file) {
  if (file.isLocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.of(context).t('الملف مقفل. فعّل المادة لفتحه.'),
        ),
      ),
    );
    return;
  }
  if (file.canViewInApp) {
    context.push(
      AppRoutes.filePdfViewer(file.id),
      extra: {'title': file.title},
    );
    return;
  }
  context.push(AppRoutes.fileDetails(file.id));
}
