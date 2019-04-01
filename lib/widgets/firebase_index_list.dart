// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/utils/stream_subscriber_mixin.dart';
import 'package:flutter/foundation.dart';

typedef void ChildCallback(int index, DataSnapshot snapshot);
typedef void ChildMovedCallback(
    int fromIndex, int toIndex, DataSnapshot snapshot);
typedef void ValueCallback(DataSnapshot snapshot);
typedef void ErrorCallback(DatabaseError error);

/// Sorts the results of `query` on the client side using `DataSnapshot.key`.
class FirebaseIndexList extends ListBase<DataSnapshot>
    with StreamSubscriberMixin<Event> {
  FirebaseIndexList({
    @required this.query,
    @required this.keyQuery,
    this.onChildAdded,
    this.onValue,
    this.onError,
  }) {
    assert(query != null);
    assert(keyQuery != null);

    keyQuery.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        if (snapshot.value is List) {
          int i = 0;
          snapshot.value.forEach((value) {
            if (value != null) {
              _keys[i.toString()] = value;
            }
            i++;
          });
        } else {
          snapshot.value.forEach((key, value) {
            _keys[key] = value;
          });
        }
      }

      listen(query.onChildAdded, _onChildAdded, onError: _onError);
      listen(query.onValue, _onValue, onError: _onError);
    });
  }

  /// Database query used to populate the list
  final Query query;


  final Query keyQuery;

  /// Called when the child has been added
  final ChildCallback onChildAdded;

  /// Called when the data of the list has finished loading
  final ValueCallback onValue;

  /// Called when an error is reported (e.g. permission denied)
  final ErrorCallback onError;

  // ListBase implementation
  final List<DataSnapshot> _snapshots = <DataSnapshot>[];

  final Map<String, int> _keys = <String, int>{};

  @override
  int get length => _snapshots.length;

  @override
  set length(int value) {
    throw UnsupportedError("List cannot be modified.");
  }

  @override
  DataSnapshot operator [](int index) => _snapshots[index];

  @override
  void operator []=(int index, DataSnapshot value) {
    throw UnsupportedError("List cannot be modified.");
  }

  @override
  void clear() {
    cancelSubscriptions();

    // Do not call super.clear(), it will set the length, it's unsupported.
  }

  void _onChildAdded(Event event) {
    if (_keys[event.snapshot.key] != null) {
      _snapshots.add(event.snapshot);
      onChildAdded(_snapshots.length - 1, event.snapshot);
    }
  }

  void _onValue(Event event) {
    onValue(event.snapshot);
  }

  void _onError(Object o) {
    final DatabaseError error = o;
    onError?.call(error);
  }
}
