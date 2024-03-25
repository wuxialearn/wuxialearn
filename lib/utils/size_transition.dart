import 'package:flutter/material.dart';

class ShrinkWidget extends StatefulWidget {
  final bool isCollapsed;
  final Widget child;
  const ShrinkWidget({super.key, required this.isCollapsed, required this.child});

  @override
  State<ShrinkWidget> createState() => _ShrinkWidgetState();
}

class _ShrinkWidgetState extends State<ShrinkWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      alignment: Alignment.topRight,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(seconds: 1),
      child: widget.isCollapsed?
        widget.child
        :const SizedBox(height: 1,),
    );
  }
}
