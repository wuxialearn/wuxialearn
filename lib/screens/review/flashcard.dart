import 'dart:math';
import 'package:flutter/material.dart';

class FlashCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool showFrontSide;
  const FlashCard(
      {Key? key,
      required this.front,
      required this.back,
      required this.showFrontSide})
      : super(key: key);

  @override
  _FlashCardState createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  //late bool _showFrontSide;
  late bool _flipXAxis;

  @override
  void initState() {
    super.initState();
    //_showFrontSide = true;
    _flipXAxis = true;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _buildFlipAnimation(front: widget.front, back: widget.back),
    );
  }

  Widget _buildFlipAnimation({required Widget front, required Widget back}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: __transitionBuilder,
      layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      child: widget.showFrontSide ? _buildFront(front) : _buildRear(back),
    );
  }

  Widget __transitionBuilder(
      Widget animatedWidget, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: animatedWidget,
      builder: (context, currentWidget) {
        final isUnder = (ValueKey(widget.showFrontSide) != currentWidget?.key);
        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        tilt *= isUnder ? -1.0 : 1.0;
        //tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        final value =
            isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
        return Transform(
          transform: _flipXAxis
              ? (Matrix4.rotationY(value)..setEntry(3, 0, tilt))
              : (Matrix4.rotationX(value)..setEntry(3, 1, tilt)),
          alignment: Alignment.center,
          child: currentWidget,
        );
      },
    );
  }

  Widget _buildFront(Widget front) {
    return __buildLayout(
      key: const ValueKey(true),
      //backgroundColor: Colors.blue,
      child: front,
    );
  }

  Widget _buildRear(Widget back) {
    return __buildLayout(
      key: const ValueKey(false),
      //backgroundColor: Colors.blue.shade700,
      child: back,
    );
  }

  Widget __buildLayout({
    required Key key,
    required Widget child,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20.0),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Center(
        child: child,
      ),
    );
  }
}
