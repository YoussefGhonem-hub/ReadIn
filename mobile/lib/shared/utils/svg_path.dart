import 'dart:ui';

/// Parses SVG path data (the `d` attribute: `M`, `L`, `H`, `V`, `C`, `S`, `Q`, `T`, `A`, `Z` and their relative
/// forms) into a [Path]. Used for the bundled brand icons of the profile links (SPEC F14), which are single paths on a
/// 24 × 24 grid.
Path parseSvgPath(String data) {
  final path = Path();
  final tokens = _SvgPathTokens(data);
  var current = Offset.zero;
  var start = Offset.zero;
  // The last control point of a C/S (cubic) or Q/T (quadratic), for the smooth commands' reflection.
  Offset? lastCubic;
  Offset? lastQuad;
  String? command;

  while (tokens.hasMore) {
    if (tokens.nextIsCommand) {
      command = tokens.command();
    } else if (command == null) {
      throw FormatException('SVG path data must start with a command', data);
    } else if (command == 'M') {
      command = 'L'; // extra pairs after a moveto are linetos
    } else if (command == 'm') {
      command = 'l';
    }
    final relative = command == command.toLowerCase();
    final base = relative ? current : Offset.zero;
    Offset point() => base + Offset(tokens.number(), tokens.number());

    switch (command.toUpperCase()) {
      case 'M':
        current = start = point();
        path.moveTo(current.dx, current.dy);
        lastCubic = lastQuad = null;
      case 'L':
        current = point();
        path.lineTo(current.dx, current.dy);
        lastCubic = lastQuad = null;
      case 'H':
        current = Offset((relative ? current.dx : 0) + tokens.number(), current.dy);
        path.lineTo(current.dx, current.dy);
        lastCubic = lastQuad = null;
      case 'V':
        current = Offset(current.dx, (relative ? current.dy : 0) + tokens.number());
        path.lineTo(current.dx, current.dy);
        lastCubic = lastQuad = null;
      case 'C':
        final c1 = point();
        final c2 = point();
        final end = point();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCubic = c2;
        lastQuad = null;
        current = end;
      case 'S':
        final c1 = lastCubic == null ? current : current * 2 - lastCubic;
        final c2 = point();
        final end = point();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCubic = c2;
        lastQuad = null;
        current = end;
      case 'Q':
        final c = point();
        final end = point();
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastQuad = c;
        lastCubic = null;
        current = end;
      case 'T':
        final c = lastQuad == null ? current : current * 2 - lastQuad;
        final end = point();
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastQuad = c;
        lastCubic = null;
        current = end;
      case 'A':
        final rx = tokens.number().abs();
        final ry = tokens.number().abs();
        final rotation = tokens.number();
        final largeArc = tokens.flag();
        final clockwise = tokens.flag();
        final end = point();
        if (rx == 0 || ry == 0) {
          path.lineTo(end.dx, end.dy);
        } else {
          path.arcToPoint(end, radius: Radius.elliptical(rx, ry), rotation: rotation, largeArc: largeArc, clockwise: clockwise);
        }
        lastCubic = lastQuad = null;
        current = end;
      case 'Z':
        path.close();
        current = start;
        lastCubic = lastQuad = null;
        // Numbers can't follow a closepath; the next token must be a command.
        command = null;
      default:
        throw FormatException('Unknown SVG path command "$command"', data);
    }
  }
  return path;
}

/// Splits path data into commands, numbers (`1.5.5` is `1.5` and `.5`, `1-2` is `1` and `-2`, `1e-3` is one number)
/// and the single-digit flags of arcs (`a1 1 0 011 1`).
class _SvgPathTokens {
  _SvgPathTokens(this._data);

  final String _data;
  int _i = 0;

  static const _commands = 'MmLlHhVvCcSsQqTtAaZz';

  void _skipSeparators() {
    while (_i < _data.length) {
      final c = _data.codeUnitAt(_i);
      if (c == 0x20 || c == 0x2C || c == 0x09 || c == 0x0A || c == 0x0D) {
        _i++;
      } else {
        break;
      }
    }
  }

  bool get hasMore {
    _skipSeparators();
    return _i < _data.length;
  }

  bool get nextIsCommand {
    _skipSeparators();
    return _i < _data.length && _commands.contains(_data[_i]);
  }

  String command() {
    _skipSeparators();
    return _data[_i++];
  }

  bool flag() {
    _skipSeparators();
    final c = _data[_i++];
    if (c != '0' && c != '1') throw FormatException('Bad arc flag "$c"', _data, _i - 1);
    return c == '1';
  }

  double number() {
    _skipSeparators();
    final begin = _i;
    if (_i < _data.length && (_data[_i] == '-' || _data[_i] == '+')) _i++;
    var dot = false;
    var exponent = false;
    while (_i < _data.length) {
      final c = _data[_i];
      if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        _i++;
      } else if (c == '.' && !dot && !exponent) {
        dot = true;
        _i++;
      } else if ((c == 'e' || c == 'E') && !exponent && _i > begin) {
        exponent = true;
        _i++;
        if (_i < _data.length && (_data[_i] == '-' || _data[_i] == '+')) _i++;
      } else {
        break;
      }
    }
    if (_i == begin) throw FormatException('Expected a number', _data, _i);
    return double.parse(_data.substring(begin, _i));
  }
}
