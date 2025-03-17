import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:hsk_learner/sql/sql_helper.dart';

import '../../widgets/delayed_progress_indecator.dart';

const ids = ['⿰', '⿱', '⿲', '⿳', '⿴', '⿵', '⿶', '⿷', '󰃿', '󰃰', '⿻'];

class SvgCharacter extends StatefulWidget {
  final String character;
  final void Function(String character) onClick;
  final double size;
  const SvgCharacter({
    super.key,
    required this.character,
    required this.onClick,
    required this.size,
  });

  @override
  State<SvgCharacter> createState() => _SvgCharacterState();
}

class _SvgCharacterState extends State<SvgCharacter> {
  Future<Map<String, dynamic>> getCharacterData(String character) async {
    final db = await SQLHelper.db();
    final result = await db.rawQuery(
      'select * from stroke_info where character = ?',
      [character],
    );
    if (result.isEmpty) {
      throw Exception('Character not found');
    }

    final characterData = Map<String, dynamic>.from(
      result.first,
    ); // Make a copy of the result
    characterData['matches'] = _parseMatches(characterData['matches']);
    characterData['strokes'] =
        (jsonDecode(characterData['strokes'] as String) as List).cast<String>();
    characterData['medians'] =
        (jsonDecode(characterData['medians'] as String) as List)
            .cast<List<dynamic>>();

    return characterData;
  }

  List<List<int>?> _parseMatches(dynamic matches) {
    assert(matches != null);

    List<dynamic> decodedMatches =
        jsonDecode(matches as String) as List<dynamic>;

    return decodedMatches.map<List<int>?>((e) {
      if (e == null) {
        return null;
      }
      return (e as List<dynamic>).cast<int>();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getCharacterData(widget.character),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const DelayedProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const Text('No data found');
        } else {
          return _DisplaySvgCharacter(
            characterData: snapshot.data!,
            size: widget.size,
            onClick: widget.onClick,
          );
        }
      },
    );
  }
}

class _DisplaySvgCharacter extends StatefulWidget {
  final Map<String, dynamic> characterData;
  final double size;
  final void Function(String character) onClick;

  const _DisplaySvgCharacter({
    Key? key,
    required this.characterData,
    required this.size,
    required this.onClick,
  }) : super(key: key);

  @override
  _DisplaySvgCharacterState createState() => _DisplaySvgCharacterState();
}

class _DisplaySvgCharacterState extends State<_DisplaySvgCharacter> {
  late Map<String, dynamic> _dictData;
  late List<String> _decomposedChars;

  @override
  void initState() {
    super.initState();
    _dictData = widget.characterData;
    _decomposedChars = _decomposeCharacter();
  }

  List<String> _decomposeCharacter() {
    final decomposition = _dictData['decomposition'] as String;
    List<String> decomposedChars = [];
    if (decomposition.startsWith("？")) {
      return decomposedChars;
    }
    List<int> idsStack = [];
    String current = "";
    bool isFirstChar = true;
    for (int i = 0; i < decomposition.length; i++) {
      String char = decomposition[i];
      if (ids.contains(char)) {
        idsStack.add(0);
        if (current.isNotEmpty) {
          decomposedChars.add(current);
          current = "";
        }
        decomposedChars.add(char);
        isFirstChar = false;
      } else {
        if (isFirstChar) {
          decomposedChars.add('r');
          isFirstChar = false;
        }
        current += char;
      }
      if (i == decomposition.length - 1) {
        decomposedChars.add(current);
      }
    }
    return decomposedChars;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset localPosition = renderBox.globalToLocal(
          details.globalPosition,
        );
        final strokeInfo = _findClickedStroke(localPosition);
        if (strokeInfo != null) {
          print(
            'Clicked Stroke Index: ${strokeInfo.index}, Component: ${strokeInfo._component}',
          );
          if (strokeInfo._component != null) {
            widget.onClick(strokeInfo._component);
          }
        }
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: CharacterPainter(
            strokes: widget.characterData["strokes"],
            matches: widget.characterData['matches'],
          ),
        ),
      ),
    );
  }

  _StrokeInfo? _findClickedStroke(Offset position) {
    final painter = CharacterPainter(
      strokes: widget.characterData['strokes'],
      matches: widget.characterData['matches'],
    );

    double scaleFactor = widget.size / 1024;
    Matrix4 matrix = Matrix4.identity();
    matrix.scale(scaleFactor);
    matrix.translate(Vector3(0.0, 900.0, 0.0));
    matrix.scale(1.0, -1.0, 1.0);
    matrix.invert();
    Vector3 localPoint = matrix.transform3(
      Vector3(position.dx, position.dy, 0),
    );
    Offset localOffset = Offset(localPoint.x, localPoint.y);

    for (int i = 0; i < painter.strokes.length; i++) {
      final path = painter.parseSvgPathData(painter.strokes[i]);
      if (path.contains(localOffset)) {
        final componentIndex = _getComponentIndex(i);
        if (componentIndex == null) {
          return _StrokeInfo(i, null);
        }
        return _StrokeInfo(
          i,
          _decomposedChars[componentIndex[0]][componentIndex[1]],
        );
      }
    }
    return null;
  }

  List<int>? _getComponentIndex(int strokeIndex) {
    final matches = _dictData['matches'];
    if (matches == null ||
        strokeIndex >= matches.length ||
        matches[strokeIndex] == null) {
      return null;
    }
    final match = matches[strokeIndex];
    return _getComponentIndexFromMatch(match);
  }

  List<int>? _getComponentIndexFromMatch(List<int>? match) {
    if (match == null || match.isEmpty) {
      return null;
    }
    int componentIndex = 1;
    int step = match[0];
    int count = 0;
    for (int j = 1; j < _decomposedChars.length; j++) {
      if (ids.contains(_decomposedChars[j])) {
        count++;
        if (count == step + 1) {
          componentIndex = j + 1;
        }
      } else if (count == step) {
        componentIndex = j;
        break;
      }
    }
    return [componentIndex, match[0]];
  }
}

class CharacterPainter extends CustomPainter {
  final List<String> strokes;
  final List<List<int>?> matches;

  CharacterPainter({required this.strokes, required this.matches});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    double scaleFactor = size.height / 1024;
    canvas.scale(scaleFactor);
    canvas.translate(0, 900);
    canvas.scale(1, -1);

    Map<String, Color> componentColors = {};

    final fixedColors = [Colors.red, Colors.blue, Colors.green];
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match != null) {
        final keyHash = match.toString();
        if (!componentColors.containsKey(keyHash)) {
          componentColors[keyHash] =
              fixedColors[componentColors.length % fixedColors.length];
        }
      }
    }

    for (int i = 0; i < strokes.length; i++) {
      final pathData = strokes[i];
      final path = parseSvgPathData(pathData);

      Color strokeColor = Colors.black;

      final match = matches[i];
      if (match != null) {
        final keyHash = match.toString();
        strokeColor = componentColors[keyHash] ?? Colors.black;
      }

      final pathPaint =
          Paint()
            ..color = strokeColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, pathPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.matches != matches;
  }

  Path parseSvgPathData(String pathData) {
    final path = Path();
    final commands = RegExp(r'([MLQZC])|(-?\d+\.?\d*)').allMatches(pathData);
    double currentX = 0;
    double currentY = 0;
    String? currentCommand;

    for (int i = 0; i < commands.length; i++) {
      final command = commands.elementAt(i).group(0);
      if (command == 'M' ||
          command == 'L' ||
          command == 'Q' ||
          command == 'C' ||
          command == 'Z') {
        currentCommand = command;
      } else if (currentCommand != null) {
        switch (currentCommand) {
          case 'M':
            currentX = double.parse(command!);
            currentY = double.parse(commands.elementAt(++i).group(0)!);
            path.moveTo(currentX, currentY);
            break;
          case 'L':
            currentX = double.parse(command!);
            currentY = double.parse(commands.elementAt(++i).group(0)!);
            path.lineTo(currentX, currentY);
            break;
          case 'Q':
            final x1 = double.parse(command!);
            final y1 = double.parse(commands.elementAt(++i).group(0)!);
            currentX = double.parse(commands.elementAt(++i).group(0)!);
            currentY = double.parse(commands.elementAt(++i).group(0)!);
            path.quadraticBezierTo(x1, y1, currentX, currentY);
            break;
          case 'C':
            final x1 = double.parse(command!);
            final y1 = double.parse(commands.elementAt(++i).group(0)!);
            final x2 = double.parse(commands.elementAt(++i).group(0)!);
            final y2 = double.parse(commands.elementAt(++i).group(0)!);
            currentX = double.parse(commands.elementAt(++i).group(0)!);
            currentY = double.parse(commands.elementAt(++i).group(0)!);
            path.cubicTo(x1, y1, x2, y2, currentX, currentY);
            break;
          case 'Z':
            path.close();
            break;
        }
        currentCommand = null;
      }
    }
    return path;
  }
}

class _StrokeInfo {
  final int index;
  final String? _component;

  _StrokeInfo(this.index, this._component);
}
