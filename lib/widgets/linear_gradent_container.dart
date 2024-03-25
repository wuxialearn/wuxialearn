import 'package:flutter/material.dart';

class LinearGradientContainer extends StatelessWidget {
  const LinearGradientContainer({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFD8EAF8),
            Color(0xFFF7F8F8),
            Color(0xFFF7F8F8),
            Color(0xFFF7F8F8),
          ],
        )
      ),
      child: child,
    );
  }
}
