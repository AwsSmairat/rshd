import 'package:flutter/material.dart';

/// Keeps forms and short lists at a comfortable reading width: full width on
/// phones, centred at [maxWidth] on tablets.
class FormWidth extends StatelessWidget {
  const FormWidth({super.key, required this.child, this.maxWidth = 600});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
