import 'package:abherbs_flutter/key/guide_path.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:flutter/material.dart';

class GuideHabitatGlyph extends StatelessWidget {
  final String id;

  const GuideHabitatGlyph({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _HabitatPainter(id, GuideColors.of(context).moss),
      ),
    );
  }
}

class _HabitatPainter extends CustomPainter {
  final String id;
  final Color color;

  _HabitatPainter(this.id, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final draw = _drawers[id];
    if (draw == null) return;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.scale(size.width / 44, size.height / 44);
    draw(canvas, stroke, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HabitatPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.color != color;
}

void _path(Canvas canvas, Paint paint, String data) {
  canvas.drawPath(parseGuidePath(data), paint);
}

void _circle(Canvas canvas, double cx, double cy, double radius, Paint paint) {
  canvas.drawCircle(Offset(cx, cy), radius, paint);
}

final _drawers = <String, void Function(Canvas, Paint, Paint)>{
  '1': (canvas, stroke, _) {
    _path(
      canvas,
      stroke,
      'M4 36h36'
      'M9 36c0-6 1-10 3-14'
      'M13 36c0-5-1-9-4-12'
      'M20 36c0-8 2-13 5-17'
      'M26 36c0-6-2-10-5-13'
      'M33 36c0-6 1-9 3-12'
      'M36 36c-1-5-3-7-6-9',
    );
    _circle(canvas, 25, 17, 2.5, stroke);
    _circle(canvas, 12, 20, 2, stroke);
  },
  '3': (canvas, stroke, fill) {
    _path(
      canvas,
      stroke,
      'M4 30c4-3 8 3 12 0s8 3 12 0 8 3 12 0'
      'M4 37c4-3 8 3 12 0s8 3 12 0 8 3 12 0'
      'M14 28V12M20 28V8M26 28V13',
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18.5, 8, 3, 7),
        const Radius.circular(1.5),
      ),
      fill,
    );
  },
  '4': (canvas, stroke, _) {
    _path(
      canvas,
      stroke,
      'M14 6 6 20h5l-6 10h18l-6-10h5z'
      'M14 30v8'
      'M30 10l-7 12h4l-5 9h16l-5-9h4z'
      'M30 31v7M4 38h36',
    );
  },
  '5': (canvas, stroke, _) {
    _path(canvas, stroke, 'M3 38 15 14l6 9 5-7 15 22zM12 20l3-6 3 5');
  },
  '7': (canvas, stroke, _) {
    _circle(canvas, 31, 12, 4.5, stroke);
    _path(
      canvas,
      stroke,
      'M31 3.5v2M31 18.5v2M22.5 12h2M37.5 12h2'
      'M25 6l1.4 1.4M35.6 16.6 37 18M25 18l1.4-1.4M35.6 7.4 37 6'
      'M4 36h36'
      'M12 36c-1-5-3-8-6-10'
      'M14 36c0-6 1-10 3-13'
      'M16 36c1-4 3-7 6-8'
      'M28 36c0-3 1-6 3-7'
      'M30 36c-1-3-2-5-4-6',
    );
  },
  '8': (canvas, stroke, _) {
    _path(
      canvas,
      stroke,
      'M4 22h36'
      'M17 38 21 22M29 38 23 22'
      'M23 38l-.5-3M22.3 31.5l-.3-2.5M21.9 26.5l-.1-1.5'
      'M9 38v-9M9 34c-2-1-3-2-3-4'
      'M35 38v-7M38 38v-5',
    );
    _circle(canvas, 9, 27, 2.5, stroke);
    _circle(canvas, 35, 29.5, 1.8, stroke);
  },
  '9': (canvas, stroke, fill) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(29, 35), width: 22, height: 6),
      stroke,
    );
    _path(
      canvas,
      stroke,
      'M4 38h11M10 38V19'
      'M10 23l-4-3M10 28l4-3M10 33l-4-3'
      'M26 32V18M32 32V21',
    );
    _circle(canvas, 6, 20, 1.2, fill);
    _circle(canvas, 14, 25, 1.2, fill);
    _circle(canvas, 6, 30, 1.2, fill);
    _circle(canvas, 10, 17.5, 1.2, fill);
    _circle(canvas, 26, 16, 2.6, stroke);
    _circle(canvas, 32, 19, 2.6, stroke);
  },
  '10': (canvas, stroke, _) {
    _circle(canvas, 33, 10, 4, stroke);
    _path(
      canvas,
      stroke,
      'M4 27c5-9 13-11 20-5 3 2 5 3 8 3'
      'M13 21v-5M13 18l-2-2M13 18l2-3'
      'M4 33c4-3 8 3 12 0s8 3 12 0 8 3 12 0'
      'M4 39c4-3 8 3 12 0s8 3 12 0 8 3 12 0',
    );
  },
};
