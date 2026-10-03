// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:abherbs_flutter/widgets/firebase_index_list.dart';

typedef Widget FirebaseAnimatedListItemBuilder(
    BuildContext context,
    DataSnapshot snapshot,
    Animation<double> animation,
    int index,
    );

class FirebaseAnimatedIndexList extends StatefulWidget {
  FirebaseAnimatedIndexList({
    Key? key,
    required this.query,
    required this.keyQuery,
    required this.itemBuilder,
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
  }) : super(key: key);

  final Query query;
  final Query keyQuery;

  final Comparator<DataSnapshot>? sort;

  final Widget? defaultChild;

  final Widget? emptyChild;

  final FirebaseAnimatedListItemBuilder itemBuilder;

  final Axis scrollDirection;

  final bool reverse;

  final ScrollController? controller;

  final bool? primary;

  final ScrollPhysics? physics;

  final bool shrinkWrap;

  final EdgeInsets? padding;

  final Duration duration;

  @override
  FirebaseAnimatedIndexListState createState() => FirebaseAnimatedIndexListState();
}

class FirebaseAnimatedIndexListState extends State<FirebaseAnimatedIndexList> {
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  late List<DataSnapshot> _model;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(FirebaseAnimatedIndexList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.path != widget.query.path ||
        oldWidget.keyQuery.path != widget.keyQuery.path) {
      _model.clear();
      _loaded = false;
      _connect();
    }
  }

  void _connect() {
    _model = FirebaseIndexList(
      query: widget.query,
      keyQuery: widget.keyQuery,
      onValue: _onValue,
    );
  }

  @override
  void dispose() {
    _model.clear();
    super.dispose();
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
    if (index < 0 || index >= _model.length) {
      return const SizedBox.shrink();
    }
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
