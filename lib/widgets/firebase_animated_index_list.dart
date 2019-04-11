// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:abherbs_flutter/widgets/firebase_index_list.dart';

typedef Widget FirebaseAnimatedListItemBuilder(
    BuildContext context,
    DataSnapshot snapshot,
    Animation<double> animation,
    int index,
    );

/// An AnimatedList widget that is bound to a query
class FirebaseAnimatedIndexList extends StatefulWidget {
  /// Creates a scrolling container that animates items when they are inserted or removed.
  FirebaseAnimatedIndexList({
    Key key,
    @required this.query,
    @required this.keyQuery,
    @required this.itemBuilder,
    this.sort,
    this.defaultChild,
    this.emptyChild,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key) {
    assert(itemBuilder != null);
  }

  /// A Firebase query to use to populate the animated list
  final Query query;
  final Query keyQuery;

  /// Optional function used to compare snapshots when sorting the list
  ///
  /// The default is to sort the snapshots by key.
  final Comparator<DataSnapshot> sort;

  /// A widget to display while the query is loading. Defaults to an empty
  /// Container().
  final Widget defaultChild;

  /// A widget to display when the query result is empty. Defaults to an empty
  /// Container().
  final Widget emptyChild;

  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [DataSnapshot] parameter indicates the snapshot that should be used
  /// to build the item.
  ///
  /// Implementations of this callback should assume that [AnimatedList.removeItem]
  /// removes an item immediately.
  final FirebaseAnimatedListItemBuilder itemBuilder;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  final ScrollController controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// On iOS, this identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the [scrollDirection]. If the scroll view
  /// has unbounded constraints in the [scrollDirection], then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// The amount of space by which to inset the children.
  final EdgeInsets padding;

  /// The duration of the insert and remove animation.
  ///
  /// Defaults to const Duration(milliseconds: 300).
  final Duration duration;

  @override
  FirebaseAnimatedIndexListState createState() => FirebaseAnimatedIndexListState();
}

class FirebaseAnimatedIndexListState extends State<FirebaseAnimatedIndexList> {
  final GlobalKey<AnimatedListState> _animatedListKey =
  GlobalKey<AnimatedListState>();
  List<DataSnapshot> _model;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    _model = FirebaseIndexList(
      query: widget.query,
      keyQuery: widget.keyQuery,
      onChildAdded: _onChildAdded,
      onValue: _onValue,
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Cancel the Firebase stream subscriptions
    _model.clear();

    super.dispose();
  }

  void _onChildAdded(int index, DataSnapshot snapshot) {
    if (!_loaded) {
      return; // AnimatedList is not created yet
    }
    if (mounted) {
      _animatedListKey.currentState.insertItem(index, duration: widget.duration);
    }
  }

  void _onValue(DataSnapshot snapshot) {
    if (mounted) {
      setState(() {
        _loaded = true;
      });
    }
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return widget.itemBuilder(context, _model[index], animation, index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return widget.defaultChild ?? Container();
    }
    if (_model.isEmpty) {
      return widget.emptyChild ?? Container();
    }
    return AnimatedList(
      key: _animatedListKey,
      itemBuilder: _buildItem,
      initialItemCount: _model.length,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
    );
  }
}
