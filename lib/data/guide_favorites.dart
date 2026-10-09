import 'dart:async';

import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Plant ids marked on the signed-in account. Empty while signed out.
/// The stored value is `1`, with no time, so lists stay in numeric id order.
final ValueNotifier<Set<String>> guideFavoriteIds = ValueNotifier({});

StreamSubscription<DatabaseEvent>? _favoritesSub;
String? _favoritesUid;

/// Ids in a `users/{uid}/favorites` snapshot. Null values are skipped.
Set<String> guideFavoriteIdsFrom(dynamic value) {
  return guideResultIds(value).toSet();
}

/// Follows `users/{uid}/favorites` for a signed-in account. A guest, or
/// signing out, clears the ids here. The rows stay on the account.
void watchGuideFavorites(User? user) {
  final uid = user?.uid;
  if (uid != null && uid == _favoritesUid && _favoritesSub != null) return;
  final previous = _favoritesSub;
  _favoritesSub = null;
  _favoritesUid = uid;
  if (previous != null) unawaited(previous.cancel());
  if (guideFavoriteIds.value.isNotEmpty) guideFavoriteIds.value = {};
  if (uid == null) return;
  _favoritesSub =
      usersReference.child(uid).child(firebaseAttributeFavorite).onValue.listen(
    (event) {
      if (_favoritesUid != uid) return;
      final next = guideFavoriteIdsFrom(event.snapshot.value);
      if (setEquals(guideFavoriteIds.value, next)) return;
      guideFavoriteIds.value = next;
    },
    onError: (Object error) => debugPrint('guide favorites: $error'),
  );
}

/// Writes `users/{uid}/favorites/{id} = 1`, or removes the id.
/// Does nothing when nobody is signed in. Updates [guideFavoriteIds] first.
Future<void> setGuideFavorite(String id, bool on) async {
  final user = Auth.appUser;
  if (user == null || id.isEmpty) return;
  final previous = guideFavoriteIds.value;
  final next = Set<String>.of(previous);
  if (on) {
    next.add(id);
  } else {
    next.remove(id);
  }
  if (!setEquals(previous, next)) guideFavoriteIds.value = next;
  final ref =
      usersReference.child(user.uid).child(firebaseAttributeFavorite).child(id);
  try {
    if (on) {
      await ref.set(1);
    } else {
      await ref.remove();
    }
  } catch (error) {
    if (_favoritesUid == user.uid && setEquals(guideFavoriteIds.value, next)) {
      guideFavoriteIds.value = previous;
    }
    rethrow;
  }
}
