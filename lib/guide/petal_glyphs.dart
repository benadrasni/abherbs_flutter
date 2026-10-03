import 'dart:math' as math;

import 'package:abherbs_flutter/guide/guide_path.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:flutter/material.dart';

class GuidePetalGlyph extends StatelessWidget {
  final String id;

  const GuidePetalGlyph({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _PetalPainter(id, colors.moss, colors.cream),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  final String id;
  final Color moss;
  final Color cream;

  _PetalPainter(this.id, this.moss, this.cream);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 72, size.height / 72);
    if (id == '4') {
      _zygomorphic(canvas, moss, cream);
    } else {
      _radial(canvas, id, moss, cream);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) =>
      oldDelegate.id != id ||
      oldDelegate.moss != moss ||
      oldDelegate.cream != cream;
}

const _centerFill = Color(0xFFE0B340);
const _centerStroke = Color(0xFF85603C);

void _radial(Canvas canvas, String id, Color moss, Color cream) {
  final count = id == '1' ? 4 : (id == '2' ? 5 : 16);
  final rx = id == '1' ? 10.0 : (id == '2' ? 9.0 : 3.6);
  final offset = id == '3' ? 17.0 : 15.0;
  final paint = Paint()
    ..color = moss
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final fill = Paint()
    ..color = cream
    ..style = PaintingStyle.fill;
  for (var i = 0; i < count; i++) {
    canvas.save();
    canvas.translate(36, 36);
    canvas.rotate(i * 2 * math.pi / count);
    canvas.translate(-36, -36);
    final oval = Rect.fromCenter(
      center: Offset(36, 36 - offset),
      width: rx * 2,
      height: 28,
    );
    canvas.drawOval(oval, fill);
    canvas.drawOval(oval, paint);
    canvas.restore();
  }
  canvas.drawCircle(
    const Offset(36, 36),
    6,
    Paint()
      ..color = _centerFill
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    const Offset(36, 36),
    6,
    Paint()
      ..color = _centerStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
}

void _zygomorphic(Canvas canvas, Color moss, Color cream) {
  final fill = Paint()
    ..color = cream
    ..style = PaintingStyle.fill;
  final stroke = Paint()
    ..color = moss
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final data in [
    'M36 38c-12-2-22-10-18-22 6-4 14 2 18 12 4-10 12-16 18-12 4 12-6 20-18 22z',
    'M36 40c-8 2-16 8-16 20 8 4 16-2 16-10 0 8 8 14 16 10 0-12-8-18-16-20z',
  ]) {
    final path = parseGuidePath(data);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }
  canvas.drawPath(
    parseGuidePath('M36 30v12'),
    Paint()
      ..color = _centerStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round,
  );
}
