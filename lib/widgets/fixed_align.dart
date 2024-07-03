import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

abstract class RenderFixedAligningShiftedBox extends RenderShiftedBox {
  RenderFixedAligningShiftedBox({
    AlignmentGeometry alignment = Alignment.center,
    required TextDirection? textDirection,
    RenderBox? child,
  })  : _alignment = alignment,
        _textDirection = textDirection,
        super(child);
  Alignment? _resolvedAlignment;
  void _resolve() {
    if (_resolvedAlignment != null) {
      return;
    }
    _resolvedAlignment = alignment.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    _markNeedResolution();
  }

  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  @protected
  void alignChild() {
    _resolve();
    assert(child != null);
    assert(!child!.debugNeedsLayout);
    assert(child!.hasSize);
    assert(hasSize);
    assert(_resolvedAlignment != null);
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    Size blankSize = Size(0, child!.size.height);
    childParentData.offset = _resolvedAlignment!.alongOffset(
        Size(size.width, size.height) - blankSize
            as Offset); //- child!.size as Offset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}

class RenderFixedPositionedBox extends RenderFixedAligningShiftedBox {
  /// Creates a render object that positions its child.
  RenderFixedPositionedBox({
    super.child,
    double? widthFactor,
    double? heightFactor,
    super.alignment,
    super.textDirection,
  })  : assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        _widthFactor = widthFactor,
        _heightFactor = heightFactor;

  /// If non-null, sets its width to the child's width multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double? get widthFactor => _widthFactor;
  double? _widthFactor;
  set widthFactor(double? value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value) {
      return;
    }
    _widthFactor = value;
    markNeedsLayout();
  }

  /// If non-null, sets its height to the child's height multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double? get heightFactor => _heightFactor;
  double? _heightFactor;
  set heightFactor(double? value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value) {
      return;
    }
    _heightFactor = value;
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final bool shrinkWrapWidth =
        _widthFactor != null || constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight =
        _heightFactor != null || constraints.maxHeight == double.infinity;
    if (child != null) {
      final Size childSize = child!.getDryLayout(constraints.loosen());
      return constraints.constrain(Size(
        shrinkWrapWidth
            ? childSize.width * (_widthFactor ?? 1.0)
            : double.infinity,
        shrinkWrapHeight
            ? childSize.height * (_heightFactor ?? 1.0)
            : double.infinity,
      ));
    }
    return constraints.constrain(Size(
      shrinkWrapWidth ? 0.0 : double.infinity,
      shrinkWrapHeight ? 0.0 : double.infinity,
    ));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final bool shrinkWrapWidth =
        _widthFactor != null || constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight =
        _heightFactor != null || constraints.maxHeight == double.infinity;

    if (child != null) {
      child!.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(Size(
        shrinkWrapWidth
            ? child!.size.width * (_widthFactor ?? 1.0)
            : double.infinity,
        shrinkWrapHeight
            ? child!.size.height * (_heightFactor ?? 1.0)
            : double.infinity,
      ));
      alignChild();
    } else {
      size = constraints.constrain(Size(
        shrinkWrapWidth ? 0.0 : double.infinity,
        shrinkWrapHeight ? 0.0 : double.infinity,
      ));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final Paint paint;
      if (child != null && !child!.size.isEmpty) {
        final Path path;
        paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFFFF00);
        path = Path();
        final BoxParentData childParentData =
            child!.parentData! as BoxParentData;
        if (childParentData.offset.dy > 0.0) {
          // vertical alignment arrows
          final double headSize =
              math.min(childParentData.offset.dy * 0.2, 10.0);
          path
            ..moveTo(offset.dx + size.width / 2.0, offset.dy)
            ..relativeLineTo(0.0, childParentData.offset.dy - headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, 0.0)
            ..moveTo(offset.dx + size.width / 2.0, offset.dy + size.height)
            ..relativeLineTo(0.0, -childParentData.offset.dy + headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(headSize, 0.0);
          context.canvas.drawPath(path, paint);
        }
        if (childParentData.offset.dx > 0.0) {
          // horizontal alignment arrows
          final double headSize =
              math.min(childParentData.offset.dx * 0.2, 10.0);
          path
            ..moveTo(offset.dx, offset.dy + size.height / 2.0)
            ..relativeLineTo(childParentData.offset.dx - headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(0.0, headSize)
            ..moveTo(offset.dx + size.width, offset.dy + size.height / 2.0)
            ..relativeLineTo(-childParentData.offset.dx + headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(0.0, headSize);
          context.canvas.drawPath(path, paint);
        }
      } else {
        paint = Paint()..color = const Color(0x90909090);
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DoubleProperty('widthFactor', _widthFactor, ifNull: 'expand'));
    properties
        .add(DoubleProperty('heightFactor', _heightFactor, ifNull: 'expand'));
  }
}

class FixedAlign extends SingleChildRenderObjectWidget {
  /// Creates an alignment widget.
  ///
  /// The alignment defaults to [Alignment.center].
  const FixedAlign({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    super.child,
  })  : assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0);

  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;

  @override
  RenderFixedPositionedBox createRenderObject(BuildContext context) {
    return RenderFixedPositionedBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderFixedPositionedBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties
        .add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties
        .add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

class FixedAnimatedAlign extends ImplicitlyAnimatedWidget {
  const FixedAnimatedAlign({
    super.key,
    required this.alignment,
    this.child,
    this.heightFactor,
    this.widthFactor,
    super.curve,
    required super.duration,
    super.onEnd,
  })  : assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0);

  final AlignmentGeometry alignment;

  final Widget? child;
  final double? heightFactor;

  final double? widthFactor;

  @override
  AnimatedWidgetBaseState<FixedAnimatedAlign> createState() =>
      _FixedAnimatedAlignState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }
}

class _FixedAnimatedAlignState
    extends AnimatedWidgetBaseState<FixedAnimatedAlign> {
  AlignmentGeometryTween? _alignment;
  Tween<double>? _heightFactorTween;
  Tween<double>? _widthFactorTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(
            _alignment,
            widget.alignment,
            (dynamic value) =>
                AlignmentGeometryTween(begin: value as AlignmentGeometry))
        as AlignmentGeometryTween?;
    if (widget.heightFactor != null) {
      _heightFactorTween = visitor(_heightFactorTween, widget.heightFactor,
              (dynamic value) => Tween<double>(begin: value as double))
          as Tween<double>?;
    }
    if (widget.widthFactor != null) {
      _widthFactorTween = visitor(_widthFactorTween, widget.widthFactor,
              (dynamic value) => Tween<double>(begin: value as double))
          as Tween<double>?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FixedAlign(
      alignment: _alignment!.evaluate(animation)!,
      heightFactor: _heightFactorTween?.evaluate(animation),
      widthFactor: _widthFactorTween?.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<AlignmentGeometryTween>(
        'alignment', _alignment,
        defaultValue: null));
    description.add(DiagnosticsProperty<Tween<double>>(
        'widthFactor', _widthFactorTween,
        defaultValue: null));
    description.add(DiagnosticsProperty<Tween<double>>(
        'heightFactor', _heightFactorTween,
        defaultValue: null));
  }
}
