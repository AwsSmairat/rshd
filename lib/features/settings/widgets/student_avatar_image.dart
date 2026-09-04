import 'dart:io';

import 'package:flutter/material.dart';

/// Renders the on-device avatar copy. Public `/storage` URLs 403 on staging,
/// and [Image.network] logs that failure even when an errorBuilder is set.
class StudentAvatarImage extends StatelessWidget {
  const StudentAvatarImage({
    super.key,
    required this.size,
    this.localPath,
    required this.placeholder,
  });

  final double size;
  final String? localPath;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final path = localPath;
    if (path == null || path.isEmpty) {
      return placeholder;
    }

    final file = File(path);
    if (!file.existsSync()) {
      return placeholder;
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: size,
      height: size,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
