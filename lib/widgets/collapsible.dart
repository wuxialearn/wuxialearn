import 'package:flutter/material.dart';

class Collapsible extends StatefulWidget {
  final Widget child;
  final bool isCollapsed;
  final int duration;
  const Collapsible(
      {Key? key,
      required this.child,
      required this.isCollapsed,
      required this.duration})
      : super(key: key);
  @override
  State<Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<Collapsible>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static final Animatable<double> _sizeTween = Tween<double>(
    begin: 0.0,
    end: 1.0,
  );
  late Animation<double> _sizeAnimation;
  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    final CurvedAnimation curve =
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
    _sizeAnimation = _sizeTween.animate(curve);

    /// Sanity check.
    if (!widget.isCollapsed) {
      _controller.forward(from: 1.0);
    }
  }

  @override
  void didUpdateWidget(covariant Collapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      if (widget.isCollapsed) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
        axisAlignment: 0.0,
        axis: Axis.vertical,
        sizeFactor: _sizeAnimation,
        child: widget.child);
  }
}
