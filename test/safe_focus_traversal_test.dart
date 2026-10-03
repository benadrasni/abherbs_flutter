import 'package:abherbs_flutter/shell/safe_focus_traversal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arrow key still moves focus between laid-out buttons',
      (WidgetTester tester) async {
    final FocusNode top = FocusNode(debugLabel: 'top');
    final FocusNode bottom = FocusNode(debugLabel: 'bottom');
    addTearDown(top.dispose);
    addTearDown(bottom.dispose);

    await tester.pumpWidget(MaterialApp(
      home: FocusTraversalGroup(
        policy: safeReadingOrderTraversalPolicy,
        child: Column(
          children: <Widget>[
            TextButton(
                focusNode: top, onPressed: () {}, child: const Text('Top')),
            TextButton(
                focusNode: bottom,
                onPressed: () {},
                child: const Text('Bottom')),
          ],
        ),
      ),
    ));
    top.requestFocus();
    await tester.pump();

    expect(top.nextFocus(), isTrue);
    await tester.pump();
    expect(bottom.hasPrimaryFocus, isTrue);

    top.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(bottom.hasPrimaryFocus, isTrue);
  });

  testWidgets('arrow key throws when a traversable node has no render object',
      (WidgetTester tester) async {
    final GlobalKey<_PageState> key = GlobalKey<_PageState>();
    await tester
        .pumpWidget(_Page(key: key, policy: ReadingOrderTraversalPolicy()));
    final _PageState state = key.currentState!;
    state.button.requestFocus();
    await tester.pump();

    state.removeGhost();
    await tester.pump();

    expect(state.ghost.node.context?.mounted, isFalse);
    expect(state.ghost.node.parent, isNotNull);
    expect(
      () => state.button.focusInDirection(TraversalDirection.down),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('arrow key ignores a traversable node that has no render object',
      (WidgetTester tester) async {
    final GlobalKey<_PageState> key = GlobalKey<_PageState>();
    await tester
        .pumpWidget(_Page(key: key, policy: safeReadingOrderTraversalPolicy));
    final _PageState state = key.currentState!;
    state.button.requestFocus();
    await tester.pump();

    state.removeGhost();
    await tester.pump();

    expect(state.ghost.node.context?.mounted, isFalse);
    final int writes = state.ghost.node.skipWrites;
    expect(state.button.focusInDirection(TraversalDirection.down), isFalse);
    expect(state.button.hasPrimaryFocus, isTrue);
    expect(state.button.skipTraversal, isFalse);
    expect(state.ghost.node.skipTraversal, isFalse);
    expect(state.ghost.node.skipWrites, writes);
  });

  testWidgets(
      'arrow key moves from the top button past a geometry-less node to the bottom button',
      (WidgetTester tester) async {
    final GlobalKey<_PageState> key = GlobalKey<_PageState>();
    await tester.pumpWidget(_Page(
      key: key,
      policy: safeReadingOrderTraversalPolicy,
      withBottom: true,
    ));
    final _PageState state = key.currentState!;
    state.button.requestFocus();
    await tester.pump();

    state.removeGhost();
    await tester.pump();

    expect(state.ghost.node.context?.mounted, isFalse);
    expect(state.button.hasPrimaryFocus, isTrue);
    final int writes = state.ghost.node.skipWrites;
    expect(state.button.skipTraversal, isFalse);
    expect(state.bottom.skipTraversal, isFalse);
    expect(state.ghost.node.skipTraversal, isFalse);

    expect(state.button.focusInDirection(TraversalDirection.down), isTrue);
    await tester.pump();

    expect(state.bottom.hasPrimaryFocus, isTrue);
    expect(state.button.skipTraversal, isFalse);
    expect(state.bottom.skipTraversal, isFalse);
    expect(state.ghost.node.skipTraversal, isFalse);
    expect(state.ghost.node.skipWrites, writes);
  });

  testWidgets('arrow key moves primary focus off a geometry-less node',
      (WidgetTester tester) async {
    final GlobalKey<_PageState> key = GlobalKey<_PageState>();
    await tester.pumpWidget(_Page(
      key: key,
      policy: safeReadingOrderTraversalPolicy,
      withBottom: true,
    ));
    final _PageState state = key.currentState!;
    state.ghost.node.requestFocus();
    await tester.pump();

    state.removeGhost();
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isTrue);
    expect(state.ghost.node.context?.mounted, isFalse);
    expect(state.ghost.node.parent, isNotNull);
    final int writes = state.ghost.node.skipWrites;

    expect(state.button.focusInDirection(TraversalDirection.down), isTrue);
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isFalse);
    expect(state.button.hasPrimaryFocus, isTrue);
    expect(state.button.skipTraversal, isFalse);
    expect(state.bottom.skipTraversal, isFalse);
    expect(state.ghost.node.skipTraversal, isFalse);
    expect(state.ghost.node.skipWrites, writes);
    await _releaseFocus(tester);
  });

  testWidgets(
      'arrow key unfocuses when the focused node is the only one and has no rectangle',
      (WidgetTester tester) async {
    final GlobalKey<_PageState> key = GlobalKey<_PageState>();
    await tester.pumpWidget(_Page(
      key: key,
      policy: safeReadingOrderTraversalPolicy,
      showButton: false,
    ));
    final _PageState state = key.currentState!;
    state.ghost.node.requestFocus();
    await tester.pump();

    state.removeGhost();
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isTrue);
    final int writes = state.ghost.node.skipWrites;

    expect(
      safeReadingOrderTraversalPolicy.inDirection(
        state.ghost.node,
        TraversalDirection.down,
      ),
      isFalse,
    );
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isFalse);
    expect(state.ghost.node.skipTraversal, isFalse);
    expect(state.ghost.node.skipWrites, writes);
  });

  testWidgets('tab moves primary focus off a geometry-less node',
      (WidgetTester tester) async {
    final GlobalKey<_PageState> key = GlobalKey<_PageState>();
    await tester.pumpWidget(_Page(
      key: key,
      policy: safeReadingOrderTraversalPolicy,
      withBottom: true,
    ));
    final _PageState state = key.currentState!;
    state.ghost.node.requestFocus();
    await tester.pump();

    state.removeGhost();
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isTrue);
    final int writes = state.ghost.node.skipWrites;

    expect(state.button.nextFocus(), isTrue);
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isFalse);
    expect(state.button.hasPrimaryFocus, isTrue);
    expect(state.button.skipTraversal, isFalse);
    expect(state.bottom.skipTraversal, isFalse);
    expect(state.ghost.node.skipTraversal, isFalse);
    expect(state.ghost.node.skipWrites, writes);

    state.ghost.node.requestFocus();
    await tester.pump();
    expect(state.bottom.previousFocus(), isTrue);
    await tester.pump();

    expect(state.ghost.node.hasPrimaryFocus, isFalse);
    expect(state.bottom.hasPrimaryFocus, isTrue);
    expect(state.ghost.node.skipWrites, writes);
    await _releaseFocus(tester);
  });

  testWidgets('arrow key skips a node whose render object is not laid out',
      (WidgetTester tester) async {
    final FocusNode top = FocusNode(debugLabel: 'top');
    final FocusNode middle = FocusNode(debugLabel: 'middle');
    final FocusNode bottom = FocusNode(debugLabel: 'bottom');
    addTearDown(top.dispose);
    addTearDown(middle.dispose);
    addTearDown(bottom.dispose);

    await _pumpSandwich(
      tester,
      top: top,
      bottom: bottom,
      middle: _UnlaidOutParent(
        child: Focus(
          focusNode: middle,
          includeSemantics: false,
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );
    top.requestFocus();
    await tester.pump();

    expect(top.focusInDirection(TraversalDirection.down), isTrue);
    await tester.pump();

    expect(bottom.hasPrimaryFocus, isTrue);
    expect(middle.hasPrimaryFocus, isFalse);
    expect(top.skipTraversal, isFalse);
    expect(middle.skipTraversal, isFalse);
    expect(bottom.skipTraversal, isFalse);
  });

  testWidgets(
      'stock policy throws when a traversable render object is not laid out',
      (WidgetTester tester) async {
    final FocusNode top = FocusNode(debugLabel: 'top');
    final FocusNode middle = FocusNode(debugLabel: 'middle');
    final FocusNode bottom = FocusNode(debugLabel: 'bottom');
    addTearDown(top.dispose);
    addTearDown(middle.dispose);
    addTearDown(bottom.dispose);

    await _pumpSandwich(
      tester,
      policy: ReadingOrderTraversalPolicy(),
      top: top,
      bottom: bottom,
      middle: _UnlaidOutParent(
        child: Focus(
          focusNode: middle,
          includeSemantics: false,
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );
    top.requestFocus();
    await tester.pump();

    expect(
      () => top.focusInDirection(TraversalDirection.down),
      throwsA(isA<AssertionError>()),
    );
  });

  testWidgets('arrow key skips a node whose semantic bounds throw StateError',
      (WidgetTester tester) async {
    await _expectBoomSkipped(tester, _BoomKind.stateError);
  });

  testWidgets(
      'arrow key skips a node whose semantic bounds throw AssertionError',
      (WidgetTester tester) async {
    await _expectBoomSkipped(tester, _BoomKind.assertionError);
  });

  testWidgets('unrelated traversal errors are not swallowed',
      (WidgetTester tester) async {
    final FocusNode top = FocusNode(debugLabel: 'top');
    final FocusNode boom = _RectBoom();
    addTearDown(top.dispose);
    addTearDown(boom.dispose);

    await tester.pumpWidget(MaterialApp(
      home: FocusTraversalGroup(
        policy: safeReadingOrderTraversalPolicy,
        child: Column(
          children: <Widget>[
            TextButton(
                focusNode: top, onPressed: () {}, child: const Text('Top')),
            TextButton(
                focusNode: boom, onPressed: () {}, child: const Text('Boom')),
          ],
        ),
      ),
    ));
    top.requestFocus();
    await tester.pump();

    expect(
      () => top.focusInDirection(TraversalDirection.down),
      throwsA(isA<FlutterError>()),
    );
    expect(top.hasPrimaryFocus, isTrue);
  });
}

/// Leaves the route scope focused so detaching a button does not restore the
/// geometry-less node and then detach that node while the restore is pending.
Future<void> _releaseFocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus
      ?.unfocus(disposition: UnfocusDisposition.scope);
  await tester.pump();
}

Future<void> _expectBoomSkipped(WidgetTester tester, _BoomKind kind) async {
  final FocusNode top = FocusNode(debugLabel: 'top');
  final FocusNode middle = FocusNode(debugLabel: 'middle');
  final FocusNode bottom = FocusNode(debugLabel: 'bottom');
  final _Armed armed = _Armed();
  addTearDown(top.dispose);
  addTearDown(middle.dispose);
  addTearDown(bottom.dispose);
  addTearDown(() {
    armed.value = false;
  });

  await _pumpSandwich(
    tester,
    top: top,
    bottom: bottom,
    middle: Focus(
      focusNode: middle,
      includeSemantics: false,
      child: _BoomBox(armed: armed, kind: kind),
    ),
  );
  top.requestFocus();
  await tester.pump();

  final bool topSkipped = top.skipTraversal;
  final bool middleSkipped = middle.skipTraversal;
  final bool bottomSkipped = bottom.skipTraversal;
  armed.value = true;
  bool moved = false;
  try {
    moved = top.focusInDirection(TraversalDirection.down);
  } finally {
    armed.value = false;
  }
  expect(moved, isTrue);
  await tester.pump();

  expect(bottom.hasPrimaryFocus, isTrue);
  expect(middle.hasPrimaryFocus, isFalse);
  expect(top.skipTraversal, topSkipped);
  expect(middle.skipTraversal, middleSkipped);
  expect(bottom.skipTraversal, bottomSkipped);
}

Future<void> _pumpSandwich(
  WidgetTester tester, {
  FocusTraversalPolicy? policy,
  required FocusNode top,
  required FocusNode bottom,
  required Widget middle,
}) {
  return tester.pumpWidget(MaterialApp(
    home: FocusTraversalGroup(
      policy: policy ?? safeReadingOrderTraversalPolicy,
      child: Column(
        children: <Widget>[
          TextButton(
              focusNode: top, onPressed: () {}, child: const Text('Top')),
          middle,
          TextButton(
              focusNode: bottom, onPressed: () {}, child: const Text('Bottom')),
        ],
      ),
    ),
  ));
}

class _CountingFocusNode extends FocusNode {
  _CountingFocusNode({super.debugLabel});

  int skipWrites = 0;

  @override
  set skipTraversal(bool value) {
    skipWrites += 1;
    super.skipTraversal = value;
  }
}

class _RectBoom extends FocusNode {
  @override
  Rect get rect => throw FlutterError('unrelated traversal failure');
}

class _Ghost {
  _Ghost();

  final _CountingFocusNode node = _CountingFocusNode(debugLabel: 'ghost');
  late final FocusAttachment attachment;
  bool _ready = false;

  void attachOnce(BuildContext context) {
    if (_ready) {
      return;
    }
    attachment = node.attach(context);
    attachment.reparent();
    _ready = true;
  }

  void dispose() {
    if (_ready) {
      attachment.detach();
    }
    node.dispose();
  }
}

class _Page extends StatefulWidget {
  const _Page({
    super.key,
    required this.policy,
    this.withBottom = false,
    this.showButton = true,
  });

  final FocusTraversalPolicy policy;
  final bool withBottom;
  final bool showButton;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final FocusNode button = FocusNode(debugLabel: 'button');
  final FocusNode bottom = FocusNode(debugLabel: 'bottom');
  final _Ghost ghost = _Ghost();
  bool _showGhost = true;

  void removeGhost() {
    setState(() {
      _showGhost = false;
    });
  }

  @override
  void dispose() {
    ghost.dispose();
    button.dispose();
    bottom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FocusTraversalGroup(
        policy: widget.policy,
        child: Column(
          children: <Widget>[
            if (widget.showButton)
              TextButton(
                  focusNode: button,
                  onPressed: () {},
                  child: const Text('Top')),
            if (_showGhost)
              Builder(
                builder: (BuildContext context) {
                  ghost.attachOnce(context);
                  return const SizedBox(width: 1, height: 1);
                },
              ),
            if (widget.withBottom)
              TextButton(
                  focusNode: bottom,
                  onPressed: () {},
                  child: const Text('Bottom')),
          ],
        ),
      ),
    );
  }
}

class _Armed {
  bool value = false;
}

enum _BoomKind { stateError, assertionError }

class _BoomBox extends LeafRenderObjectWidget {
  const _BoomBox({required this.armed, required this.kind});

  final _Armed armed;
  final _BoomKind kind;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _BoomBoxRender(armed: armed, kind: kind);
  }
}

class _BoomBoxRender extends RenderBox {
  _BoomBoxRender({required this.armed, required this.kind});

  final _Armed armed;
  final _BoomKind kind;

  @override
  void performLayout() {
    size = constraints.constrain(const Size(8, 8));
  }

  @override
  Rect get semanticBounds {
    if (!armed.value) {
      return super.semanticBounds;
    }
    switch (kind) {
      case _BoomKind.stateError:
        throw StateError('RenderBox was not laid out');
      case _BoomKind.assertionError:
        throw AssertionError('RenderBox was not laid out');
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {}
}

class _UnlaidOutParent extends SingleChildRenderObjectWidget {
  const _UnlaidOutParent({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _UnlaidOutBox();
}

class _UnlaidOutBox extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  @override
  void performLayout() {
    size = constraints.constrain(const Size(8, 8));
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}
}
