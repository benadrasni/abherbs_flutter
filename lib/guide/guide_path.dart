import 'dart:ui';

/// The habitat and petal drawings use a small slice of SVG path data.
Path parseGuidePath(String source) {
  final cursor = _Cursor(source);
  final path = Path();
  String? command;
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;
  var controlX = 0.0;
  var controlY = 0.0;
  var cubic = false;

  while (true) {
    cursor.skipSeparators();
    if (cursor.done) break;
    if (cursor.isCommand) {
      command = cursor.readCommand();
    } else if (command == null) {
      throw FormatException('path must start with a command: $source');
    } else if (command == 'Z' || command == 'z') {
      throw FormatException('unexpected number in $source');
    }
    switch (command) {
      case 'M':
        x = cursor.readNumber();
        y = cursor.readNumber();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        command = 'L';
        cubic = false;
      case 'm':
        x += cursor.readNumber();
        y += cursor.readNumber();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        command = 'l';
        cubic = false;
      case 'L':
        x = cursor.readNumber();
        y = cursor.readNumber();
        path.lineTo(x, y);
        cubic = false;
      case 'l':
        x += cursor.readNumber();
        y += cursor.readNumber();
        path.lineTo(x, y);
        cubic = false;
      case 'H':
        x = cursor.readNumber();
        path.lineTo(x, y);
        cubic = false;
      case 'h':
        x += cursor.readNumber();
        path.lineTo(x, y);
        cubic = false;
      case 'V':
        y = cursor.readNumber();
        path.lineTo(x, y);
        cubic = false;
      case 'v':
        y += cursor.readNumber();
        path.lineTo(x, y);
        cubic = false;
      case 'C':
        final x1 = cursor.readNumber();
        final y1 = cursor.readNumber();
        final x2 = cursor.readNumber();
        final y2 = cursor.readNumber();
        x = cursor.readNumber();
        y = cursor.readNumber();
        path.cubicTo(x1, y1, x2, y2, x, y);
        controlX = x2;
        controlY = y2;
        cubic = true;
      case 'c':
        final originX = x;
        final originY = y;
        final x1 = originX + cursor.readNumber();
        final y1 = originY + cursor.readNumber();
        final x2 = originX + cursor.readNumber();
        final y2 = originY + cursor.readNumber();
        x = originX + cursor.readNumber();
        y = originY + cursor.readNumber();
        path.cubicTo(x1, y1, x2, y2, x, y);
        controlX = x2;
        controlY = y2;
        cubic = true;
      case 'S':
        final x1 = cubic ? 2 * x - controlX : x;
        final y1 = cubic ? 2 * y - controlY : y;
        final x2 = cursor.readNumber();
        final y2 = cursor.readNumber();
        x = cursor.readNumber();
        y = cursor.readNumber();
        path.cubicTo(x1, y1, x2, y2, x, y);
        controlX = x2;
        controlY = y2;
        cubic = true;
      case 's':
        final originX = x;
        final originY = y;
        final x1 = cubic ? 2 * originX - controlX : originX;
        final y1 = cubic ? 2 * originY - controlY : originY;
        final x2 = originX + cursor.readNumber();
        final y2 = originY + cursor.readNumber();
        x = originX + cursor.readNumber();
        y = originY + cursor.readNumber();
        path.cubicTo(x1, y1, x2, y2, x, y);
        controlX = x2;
        controlY = y2;
        cubic = true;
      case 'Z':
      case 'z':
        path.close();
        x = startX;
        y = startY;
        command = null;
        cubic = false;
      default:
        throw FormatException('unsupported "$command" in $source');
    }
  }
  return path;
}

class _Cursor {
  _Cursor(this.source);

  final String source;
  int index = 0;

  bool get done => index >= source.length;

  void skipSeparators() {
    while (!done) {
      final code = source.codeUnitAt(index);
      if (code == 32 || code == 44 || code == 9 || code == 10 || code == 13) {
        index++;
      } else {
        break;
      }
    }
  }

  bool get isCommand {
    if (done) return false;
    final code = source.codeUnitAt(index);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  String readCommand() {
    final command = source[index];
    index++;
    return command;
  }

  double readNumber() {
    skipSeparators();
    final start = index;
    if (!done && (source[index] == '+' || source[index] == '-')) index++;
    var digits = false;
    while (!done && _isDigit(source.codeUnitAt(index))) {
      digits = true;
      index++;
    }
    if (!done && source[index] == '.') {
      index++;
      while (!done && _isDigit(source.codeUnitAt(index))) {
        digits = true;
        index++;
      }
    }
    if (!digits) {
      throw FormatException('expected a number at $start in $source');
    }
    return double.parse(source.substring(start, index));
  }
}

bool _isDigit(int code) => code >= 48 && code <= 57;
