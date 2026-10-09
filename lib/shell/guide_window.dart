import 'package:flutter/widgets.dart';

/// Field-guide window. A phone stays under a 700-point shortest side, which
/// is every iPhone and the default widget-test surface. An iPad in portrait
/// is [tablet]. Landscape, and a portrait iPad wide enough for a sidebar, is
/// [wide].
class GuideWindow {
  static const double tabletShortestSide = 700;
  static const double wideWidth = 1000;

  final bool tablet;
  final bool wide;

  const GuideWindow({required this.tablet, required this.wide});

  static GuideWindow fromSize(Size size) {
    final tablet = size.shortestSide >= tabletShortestSide;
    return GuideWindow(
      tablet: tablet,
      wide: tablet && size.width >= wideWidth,
    );
  }

  static GuideWindow of(BuildContext context) {
    return fromSize(MediaQuery.sizeOf(context));
  }

  /// Column count for a grid that grows from the phone to portrait, then
  /// landscape.
  int columns({required int phone, required int tablet, required int wide}) {
    if (this.wide) return wide;
    if (this.tablet) return tablet;
    return phone;
  }
}

/// Centers a settings column on a tablet. The child gets a tight height, so
/// a [Column] with an [Expanded] still works.
class GuideReadable extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const GuideReadable({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    if (!GuideWindow.of(context).tablet) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
