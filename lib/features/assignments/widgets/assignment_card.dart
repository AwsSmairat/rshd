import 'package:flutter/material.dart';

import '../data/models/assignment_model.dart';
import 'liquid_glass_assignment_card.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  final AssignmentModel assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassAssignmentCard(
      assignment: assignment,
      onTap: onTap,
    );
  }
}
