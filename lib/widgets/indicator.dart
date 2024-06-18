import 'package:flutter/cupertino.dart';

class TabIndicator extends Decoration {
  final BoxPainter _painter;
  TabIndicator({required Color color, required double radius}) :_painter = _TabPainter(color, radius) ;
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _painter;
}

class _TabPainter extends BoxPainter {
  final Paint _paint;
  final double radius;

  _TabPainter(Color color, this.radius) : _paint = Paint()
    ..color = color
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final double rectOffset = offset.dx + cfg.size!.width / 2;
    final double heightSpace = cfg.size!.height;
    const double indicatorHeight = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(rectOffset -8, heightSpace - indicatorHeight, rectOffset + 8.0, heightSpace),
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      ),
      _paint,
    );
  }
}