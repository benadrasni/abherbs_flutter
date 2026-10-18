import 'dart:io';

import 'package:abherbs_flutter/shell/guide_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The band where iPhone Duo creases when it is partly folded.
///
/// Flat and closed poses have no band. A vertical band splits the inner
/// display into a left page and a right page. The rect comes from UIKit and
/// already includes the margins around the hinge.
class GuideFold {
  final Rect bounds;

  const GuideFold(this.bounds);

  bool get vertical => bounds.height >= bounds.width;

  double get leading => bounds.left;

  double get span => bounds.width;

  /// The active crease that crosses this window. A short cutout is ignored.
  static GuideFold? choose(List<Rect> regions, Size size) {
    for (final bounds in regions) {
      final crosses = bounds.height >= size.height * 0.5 ||
          bounds.width >= size.width * 0.5;
      if (!crosses || bounds.shortestSide < 8) continue;
      return GuideFold(bounds);
    }
    return null;
  }

  /// Platform lists arrive as `List<Object?>`, which is not a `List<dynamic>`.
  static List<Rect> rects(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          Rect.fromLTWH(
            (item['x'] as num?)?.toDouble() ?? 0,
            (item['y'] as num?)?.toDouble() ?? 0,
            (item['w'] as num?)?.toDouble() ?? 0,
            (item['h'] as num?)?.toDouble() ?? 0,
          ),
    ];
  }

  static GuideFold? of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GuideFoldScope>();
    return scope?.fold;
  }

  /// A vertical crease with room for a page on each side.
  ///
  /// Side status chrome already owns one edge, and the hinge is not active
  /// on that pose, so this stays null there.
  static GuideFold? verticalCrease(
    BuildContext context, {
    double minPage = 180,
  }) {
    final fold = of(context);
    if (fold == null || !fold.vertical) return null;
    if (GuideChrome.of(context).vertical) return null;
    final width = MediaQuery.sizeOf(context).width;
    if (fold.pagesIn(originX: 0, width: width, minPage: minPage) == null) {
      return null;
    }
    return fold;
  }

  /// Three tab centers. The middle one is the center of the bar.
  ///
  /// Find and Seen take the centers of the other two thirds, so the gaps
  /// match and Book sits in the middle, on the hinge.
  static List<double>? tabCenters({required double width}) {
    if (width <= 0) return null;
    return [width / 6, width / 2, width * 5 / 6];
  }

  /// Column count that keeps a cell off a vertical crease.
  ///
  /// An odd count would sit one cell on the hinge. The next even count
  /// splits evenly, so three becomes two on each page.
  static int across(BuildContext context, int columns) {
    if (columns < 2) return columns;
    if (verticalCrease(context) == null) return columns;
    return columns.isEven ? columns : columns + 1;
  }

  /// Page widths for a box that starts at [originX] in window coordinates.
  ({double leading, double span, double trailing})? pagesIn({
    required double originX,
    required double width,
    double minPage = 120,
  }) {
    final leading = bounds.left - originX;
    final trailing = width - leading - span;
    if (leading < minPage || trailing < minPage) return null;
    return (leading: leading, span: span, trailing: trailing);
  }
}

/// Puts [leading] and [trailing] on either side of a vertical crease.
///
/// [unsplit] is used when the device is flat, closed, or this box is too
/// narrow to clear the hinge.
class GuideFoldSplit extends StatelessWidget {
  final double originX;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget unsplit;
  final Widget leading;
  final Widget trailing;

  const GuideFoldSplit({
    super.key,
    this.originX = 0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    required this.unsplit,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final fold = GuideFold.verticalCrease(context, minPage: 1);
    if (fold == null) return unsplit;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite) return unsplit;
        final pages = fold.pagesIn(
          originX: originX,
          width: width,
          minPage: 80,
        );
        if (pages == null) return unsplit;
        // The hinge stays on the physical center in both writing directions.
        // Reading order still starts on the right when the locale is RTL.
        final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
        final rtl = direction == TextDirection.rtl;
        Widget side(Widget child) {
          return Directionality(textDirection: direction, child: child);
        }

        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            SizedBox(
                width: pages.leading, child: side(rtl ? trailing : leading)),
            SizedBox(width: pages.span),
            SizedBox(
              width: pages.trailing,
              child: side(rtl ? leading : trailing),
            ),
          ],
        );
      },
    );
  }
}

/// Asks iOS for the crease and rebuilds when the fold or the window changes.
class GuideFoldHost extends StatefulWidget {
  final Widget child;

  const GuideFoldHost({super.key, required this.child});

  @override
  State<GuideFoldHost> createState() => _GuideFoldHostState();
}

class _GuideFoldHostState extends State<GuideFoldHost>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('sk.ab.herbs/fold');

  GuideFold? _fold;
  var _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'update') _apply(call.arguments);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _load();
  }

  Future<void> _load() async {
    if (!Platform.isIOS) return;
    Object? raw;
    try {
      raw = await _channel.invokeMethod<Object>('regions');
    } catch (error) {
      if (kDebugMode) debugPrint('guide fold $error');
      raw = null;
    }
    if (!mounted) return;
    _apply(raw);
  }

  void _apply(Object? raw) {
    if (!mounted) return;
    final rects = GuideFold.rects(raw);
    final next = GuideFold.choose(rects, MediaQuery.sizeOf(context));
    final changed = next?.bounds != _fold?.bounds;
    if (kDebugMode && (changed || !_reported)) {
      _reported = true;
      debugPrint('guide fold $rects -> ${next?.bounds}');
    }
    if (!changed) return;
    setState(() => _fold = next);
  }

  @override
  Widget build(BuildContext context) {
    return GuideFoldScope(fold: _fold, child: widget.child);
  }
}

/// A row of cells. A vertical crease puts the first half on the left page.
///
/// [originX] is the window position of this row's left edge. [gutter] is
/// the padding between a cell and the hinge. An empty slot keeps the columns
/// aligned when the last row is short.
class GuideFoldRow extends StatelessWidget {
  final int columns;
  final List<Widget> children;
  final double gap;
  final double gutter;
  final double originX;
  final bool stretch;
  final EdgeInsetsGeometry padding;

  const GuideFoldRow({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 12,
    this.gutter = 6,
    this.originX = 0,
    this.stretch = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final fold = GuideFold.verticalCrease(context);
    if (fold == null || columns < 2) {
      return Padding(
        padding: padding,
        child: _foldSlots(children, columns, gap, stretch),
      );
    }
    final half = columns ~/ 2;
    return Padding(
      padding: padding,
      child: GuideFoldSplit(
        originX: originX,
        crossAxisAlignment:
            stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
        unsplit: _foldSlots(children, columns, gap, stretch),
        leading: Padding(
          padding: EdgeInsetsDirectional.only(end: gutter),
          child: _foldSlots(children.take(half).toList(), half, gap, stretch),
        ),
        trailing: Padding(
          padding: EdgeInsetsDirectional.only(start: gutter),
          child: _foldSlots(children.skip(half).toList(), half, gap, stretch),
        ),
      ),
    );
  }
}

Widget _foldSlots(List<Widget> children, int columns, double gap, bool stretch) {
  if (columns < 1) return const SizedBox.shrink();
  final row = Row(
    crossAxisAlignment:
        stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < columns; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(
          child: i < children.length ? children[i] : const SizedBox.shrink(),
        ),
      ],
    ],
  );
  if (!stretch) return row;
  return IntrinsicHeight(child: row);
}

/// Puts [child] on the left page when a vertical crease is present.
///
/// [originX] is the window position of this box's left edge. The flat and
/// closed poses keep [child] at the full width.
class GuideFoldLeading extends StatelessWidget {
  final double originX;
  final WidgetBuilder child;

  const GuideFoldLeading({super.key, this.originX = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    if (GuideFold.verticalCrease(context) == null) return child(context);
    return GuideFoldSplit(
      originX: originX,
      crossAxisAlignment: CrossAxisAlignment.start,
      unsplit: child(context),
      leading: child(context),
      trailing: const SizedBox.shrink(),
    );
  }
}

class GuideFoldScope extends InheritedWidget {
  final GuideFold? fold;

  const GuideFoldScope({super.key, required this.fold, required super.child});

  @override
  bool updateShouldNotify(GuideFoldScope oldWidget) {
    return oldWidget.fold?.bounds != fold?.bounds;
  }
}
