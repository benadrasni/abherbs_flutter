import 'package:flutter/widgets.dart';

/// Field-guide window. A phone stays under a 650-point shortest side. That
/// is every iPhone, the outer display of iPhone Duo (about 466 points), and
/// the default widget-test surface. The inner display is about 669 points
/// on its short side, so it uses the [tablet] layout, as does an iPad in
/// portrait, including the 13-inch Pro at 1032 points. A landscape window
/// at least [wideWidth] points across is [wide].
class GuideWindow {
  static const double tabletShortestSide = 650;
  static const double wideWidth = 1000;

  final bool tablet;
  final bool wide;

  const GuideWindow({required this.tablet, required this.wide});

  static GuideWindow fromSize(Size size) {
    final tablet = size.shortestSide >= tabletShortestSide;
    final landscape = size.width > size.height;
    return GuideWindow(
      tablet: tablet,
      wide: tablet && landscape && size.width >= wideWidth,
    );
  }

  static GuideWindow of(BuildContext context) {
    return fromSize(MediaQuery.sizeOf(context));
  }

  /// Column count for a grid that grows from the phone to the inner display
  /// and iPad portrait, then to a wide landscape window.
  int columns({required int phone, required int tablet, required int wide}) {
    if (this.wide) return wide;
    if (this.tablet) return tablet;
    return phone;
  }
}

/// Where the system status column sits.
///
/// On iPhone Duo the clock and the Dynamic Island stand on one side, and
/// the tab bar belongs under them. A normal phone keeps the larger inset
/// on top, so [vertical] stays false. The side is read from the safe area,
/// so a Split View column on the left is handled the same way as the usual
/// trailing column.
class GuideChrome {
  /// Wider than a hairline inset, and at least a status-bar height.
  static const double sideColumn = 44;

  final bool vertical;
  final bool onRight;
  final double side;

  const GuideChrome({
    required this.vertical,
    required this.onRight,
    required this.side,
  });

  static const GuideChrome horizontal = GuideChrome(
    vertical: false,
    onRight: true,
    side: 0,
  );

  static GuideChrome fromPadding(EdgeInsets padding) {
    final onRight = padding.right >= padding.left;
    final side = onRight ? padding.right : padding.left;
    if (side < sideColumn || side <= padding.top) return horizontal;
    return GuideChrome(vertical: true, onRight: onRight, side: side);
  }

  static GuideChrome of(BuildContext context) {
    return fromPadding(MediaQuery.paddingOf(context));
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
        final width =
            constraints.maxWidth < maxWidth ? constraints.maxWidth : maxWidth;
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
