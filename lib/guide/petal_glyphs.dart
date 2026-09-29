import 'dart:math' as math;

import 'package:abherbs_flutter/guide/guide_path.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:flutter/material.dart';

class GuidePetalGlyph extends StatelessWidget {
  final String id;

  const GuidePetalGlyph({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(painter: _PetalPainter(id)),
    );
  }
}

class _PetalPainter extends CustomPainter {
  final String id;

  _PetalPainter(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 72, size.height / 72);
    if (id == '4') {
      _zygomorphic(canvas);
    } else {
      _radial(canvas, id);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) => oldDelegate.id != id;
}

const _petalFill = Color(0xFFFFFDF8);
const _centerFill = Color(0xFFE0B340);

void _radial(Canvas canvas, String id) {
  final count = id == '1' ? 4 : (id == '2' ? 5 : 16);
  final rx = id == '1' ? 10.0 : (id == '2' ? 9.0 : 3.6);
  final offset = id == '3' ? 17.0 : 15.0;
  final paint = Paint()
    ..color = GuidePalette.moss
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final fill = Paint()
    ..color = _petalFill
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
      ..color = GuidePalette.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
}

void _zygomorphic(Canvas canvas) {
  final fill = Paint()
    ..color = _petalFill
    ..style = PaintingStyle.fill;
  final stroke = Paint()
    ..color = GuidePalette.moss
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
      ..color = GuidePalette.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round,
  );
}
