import 'package:flutter/material.dart';
import '../../../core/widgets/app_empty_state.dart';

class GradesEmptyState extends StatelessWidget {
  const GradesEmptyState({super.key});

  @override
  Widget build(BuildContext context) => const AppEmptyState(
    icon: Icons.emoji_events_outlined,
    message: 'لا توجد درجات حالياً',
    subtitle: 'ستظهر درجاتك هنا بعد تقييم الواجبات والاختبارات',
  );
}
