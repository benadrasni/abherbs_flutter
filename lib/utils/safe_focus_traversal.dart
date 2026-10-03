import 'package:flutter/material.dart';

/// Reading-order traversal that skips focus nodes whose geometry cannot be read.
///
/// [FocusNode.rect] throws when the node has no context, no render object, or a
/// render object that has not been laid out. Arrow keys and tab both read that
/// rectangle. A node parked on the root during deactivate, or one whose element
/// has already been unmounted, turns the key into a fatal crash.
///
/// Nodes without a rectangle are left out of the walk. [FocusNode.skipTraversal]
/// is not changed. If the focused node itself has no rectangle, focus moves to
/// a node that has one, or leaves that node when none does.
final FocusTraversalPolicy safeReadingOrderTraversalPolicy =
    SafeReadingOrderTraversalPolicy();

class SafeReadingOrderTraversalPolicy extends ReadingOrderTraversalPolicy {
  SafeReadingOrderTraversalPolicy({super.requestFocusCallback});

  @override
  Iterable<FocusNode> sortDescendants(
      Iterable<FocusNode> descendants, FocusNode currentNode) {
    final List<FocusNode> grounded = <FocusNode>[
      for (final FocusNode node in descendants)
        if (_safeRect(node) != null) node,
    ];
    if (grounded.isEmpty) {
      return const Iterable<FocusNode>.empty();
    }
    return super.sortDescendants(grounded, currentNode);
  }

  @override
  bool next(FocusNode currentNode) {
    return _leaveGeometryLessFocus(currentNode, forward: true) ??
        super.next(currentNode);
  }

  @override
  bool previous(FocusNode currentNode) {
    return _leaveGeometryLessFocus(currentNode, forward: false) ??
        super.previous(currentNode);
  }

  /// When the focused child has a rectangle, returns null so the framework
  /// walk can run. Otherwise focuses the first or last grounded node, or
  /// unfocuses when there is nowhere to go.
  ///
  /// [FocusTraversalPolicy.next] asserts that [sortDescendants] still contains
  /// the focused child. Dropping a child that has no rectangle fails that
  /// assert and, with asserts stripped, leaves focus where it is.
  bool? _leaveGeometryLessFocus(FocusNode currentNode,
      {required bool forward}) {
    final FocusScopeNode? scope = currentNode.nearestScope;
    if (scope == null) {
      return false;
    }
    final FocusNode? focused = scope.focusedChild;
    if (focused == null || _safeRect(focused) != null) {
      return null;
    }
    final List<FocusNode> grounded = <FocusNode>[
      for (final FocusNode node in scope.traversalDescendants)
        if (_safeRect(node) != null) node,
    ];
    if (grounded.isEmpty) {
      focused.unfocus();
      return false;
    }
    final List<FocusNode> sorted =
        super.sortDescendants(grounded, currentNode).toList();
    if (sorted.isEmpty) {
      focused.unfocus();
      return false;
    }
    final FocusNode target = forward ? sorted.first : sorted.last;
    final bool hadPrimaryFocus = target.hasPrimaryFocus;
    requestFocusCallback(
      target,
      alignmentPolicy: forward
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
    return !hadPrimaryFocus;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final FocusScopeNode? scope = currentNode.nearestScope;
    if (scope == null) {
      return false;
    }
    final FocusNode? focused = scope.focusedChild;
    final Map<FocusNode, Rect> rects = <FocusNode, Rect>{};
    // [inDirection] reads [FocusNode.rect] on every traversable node. Call it
    // only when each of those nodes, and the focused child, can report one.
    if (!_missingGeometry(scope, focused, rects)) {
      return super.inDirection(currentNode, direction);
    }
    if (focused == null || !rects.containsKey(focused)) {
      return _focusFirstInDirection(focused, rects, direction);
    }
    final FocusNode? target = _nearestInDirection(focused, rects, direction);
    if (target == null) {
      return false;
    }
    return _moveTo(target, direction);
  }

  bool _missingGeometry(
    FocusScopeNode scope,
    FocusNode? focused,
    Map<FocusNode, Rect> rects,
  ) {
    var missing = false;
    if (focused != null) {
      final Rect? rect = _safeRect(focused);
      if (rect == null) {
        missing = true;
      } else {
        rects[focused] = rect;
      }
    }
    for (final FocusNode node in scope.traversalDescendants) {
      if (rects.containsKey(node)) {
        continue;
      }
      final Rect? rect = _safeRect(node);
      if (rect == null) {
        missing = true;
      } else {
        rects[node] = rect;
      }
    }
    return missing;
  }

  /// Picks the same edge [findFirstFocusInDirection] would, among nodes that
  /// have a rectangle. Unfocuses [focused] when that set is empty.
  bool _focusFirstInDirection(
    FocusNode? focused,
    Map<FocusNode, Rect> rects,
    TraversalDirection direction,
  ) {
    if (rects.isEmpty) {
      focused?.unfocus();
      return false;
    }
    final List<FocusNode> grounded = rects.keys.toList();
    grounded.sort((FocusNode a, FocusNode b) {
      final Rect ra = rects[a]!;
      final Rect rb = rects[b]!;
      switch (direction) {
        case TraversalDirection.down:
          return ra.top.compareTo(rb.top);
        case TraversalDirection.up:
          return rb.bottom.compareTo(ra.bottom);
        case TraversalDirection.right:
          return ra.left.compareTo(rb.left);
        case TraversalDirection.left:
          return rb.right.compareTo(ra.right);
      }
    });
    return _moveTo(grounded.first, direction);
  }

  FocusNode? _nearestInDirection(
    FocusNode origin,
    Map<FocusNode, Rect> rects,
    TraversalDirection direction,
  ) {
    final Rect originRect = rects[origin]!;
    bool eligible(Rect rect) {
      switch (direction) {
        case TraversalDirection.down:
          return rect.center.dy >= originRect.bottom;
        case TraversalDirection.up:
          return rect.center.dy <= originRect.top;
        case TraversalDirection.right:
          return rect.center.dx >= originRect.right;
        case TraversalDirection.left:
          return rect.center.dx <= originRect.left;
      }
    }

    final List<FocusNode> candidates = <FocusNode>[
      for (final MapEntry<FocusNode, Rect> entry in rects.entries)
        if (entry.key != origin && eligible(entry.value)) entry.key,
    ];
    if (candidates.isEmpty) {
      return null;
    }

    final bool vertical = direction == TraversalDirection.up ||
        direction == TraversalDirection.down;
    final List<FocusNode> pool =
        _sameScrollable(origin, candidates, vertical: vertical);
    final List<FocusNode> inBand = <FocusNode>[
      for (final FocusNode node in pool)
        if (_intersectsBand(rects[node]!, originRect, vertical: vertical)) node,
    ];
    final List<FocusNode> chooseFrom = inBand.isNotEmpty ? inBand : pool;
    final Offset center = originRect.center;
    chooseFrom.sort((FocusNode a, FocusNode b) {
      return _compareDistance(
        center,
        rects[a]!,
        rects[b]!,
        verticalFirst: inBand.isNotEmpty ? vertical : !vertical,
      );
    });
    return chooseFrom.first;
  }

  List<FocusNode> _sameScrollable(
    FocusNode origin,
    List<FocusNode> candidates, {
    required bool vertical,
  }) {
    final Axis axis = vertical ? Axis.vertical : Axis.horizontal;
    final ScrollableState? originScrollable = _scrollable(origin, axis);
    if (originScrollable == null) {
      return candidates;
    }
    final List<FocusNode> same = <FocusNode>[
      for (final FocusNode node in candidates)
        if (_scrollable(node, axis) == originScrollable) node,
    ];
    return same.isEmpty ? candidates : same;
  }

  bool _moveTo(FocusNode target, TraversalDirection direction) {
    final bool hadPrimaryFocus = target.hasPrimaryFocus;
    requestFocusCallback(target, alignmentPolicy: _alignmentFor(direction));
    return !hadPrimaryFocus;
  }
}

ScrollPositionAlignmentPolicy _alignmentFor(TraversalDirection direction) {
  switch (direction) {
    case TraversalDirection.up:
    case TraversalDirection.left:
      return ScrollPositionAlignmentPolicy.keepVisibleAtStart;
    case TraversalDirection.right:
    case TraversalDirection.down:
      return ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
  }
}

ScrollableState? _scrollable(FocusNode node, Axis axis) {
  final BuildContext? context = node.context;
  if (context == null || !context.mounted) {
    return null;
  }
  return Scrollable.maybeOf(context, axis: axis);
}

bool _intersectsBand(Rect rect, Rect origin, {required bool vertical}) {
  final Rect band = vertical
      ? Rect.fromLTRB(
          origin.left, double.negativeInfinity, origin.right, double.infinity)
      : Rect.fromLTRB(
          double.negativeInfinity, origin.top, double.infinity, origin.bottom);
  return !rect.intersect(band).isEmpty;
}

int _compareDistance(
  Offset origin,
  Rect a,
  Rect b, {
  required bool verticalFirst,
}) {
  int alongY() => (a.center.dy - origin.dy)
      .abs()
      .compareTo((b.center.dy - origin.dy).abs());
  int alongX() => (a.center.dx - origin.dx)
      .abs()
      .compareTo((b.center.dx - origin.dx).abs());
  final int primary = verticalFirst ? alongY() : alongX();
  if (primary != 0) {
    return primary;
  }
  return verticalFirst ? alongX() : alongY();
}

/// The same rectangle [FocusNode.rect] would return, or null when reading it
/// would throw.
///
/// The checks match the getter: a mounted context, an attached render object,
/// a laid-out [RenderBox], then the transformed semantic bounds. Failures stay
/// inside this probe. Callers do not catch errors from the framework walk.
Rect? _safeRect(FocusNode node) {
  final BuildContext? context = node.context;
  if (context == null || !context.mounted) {
    return null;
  }
  final RenderObject? object;
  try {
    object = context.findRenderObject();
  } on FlutterError {
    return null;
  }
  if (object == null || !object.attached) {
    return null;
  }
  if (object is RenderBox && !object.hasSize) {
    return null;
  }
  try {
    final Matrix4 transform = object.getTransformTo(null);
    final Offset topLeft = MatrixUtils.transformPoint(
      transform,
      object.semanticBounds.topLeft,
    );
    final Offset bottomRight = MatrixUtils.transformPoint(
      transform,
      object.semanticBounds.bottomRight,
    );
    return Rect.fromLTRB(
        topLeft.dx, topLeft.dy, bottomRight.dx, bottomRight.dy);
  } on TypeError {
    return null;
  } on StateError {
    return null;
  } on FlutterError {
    return null;
  } on AssertionError {
    // [FlutterError] implements [AssertionError], so it is caught above.
    return null;
  }
}
