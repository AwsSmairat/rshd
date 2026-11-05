import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton.dart';

/// Grade cards while they load: the course, the title and the score ring.
class GradesLoadingSkeleton extends StatelessWidget {
  const GradesLoadingSkeleton({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 16),
              child: const SkeletonCard(
                radius: 24,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 96, height: 12),
                          SizedBox(height: 12),
                          SkeletonBox(height: 16),
                          SizedBox(height: 10),
                          SkeletonBox(width: 140, height: 12),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    SkeletonBox.circle(size: 56),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
