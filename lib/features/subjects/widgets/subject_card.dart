import 'package:flutter/material.dart';

import '../data/models/subject_model.dart';
import 'luxury_subject_card.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  final SubjectModel subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LuxurySubjectCard(
      subject: subject,
      onTap: onTap,
    );
  }
}
