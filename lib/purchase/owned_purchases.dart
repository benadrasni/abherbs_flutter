import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Product ids stored for an account. A list and the Realtime Database map
/// form of that list are both accepted. Values that are not product ids are
/// dropped.
List<String> purchaseIdsOf(Object? raw) {
  final ids = <String>{};
  void add(Object? value) {
    if (value is String && value.isNotEmpty) ids.add(value);
  }

  if (raw is List) {
    for (final value in raw) {
      add(value);
    }
  } else if (raw is Map) {
    for (final value in raw.values) {
      add(value);
    }
  }
  final list = ids.toList()..sort();
  return list;
}

/// [current] plus [add], with empty ids removed and the result sorted.
List<String> mergePurchaseIds(Object? current, Iterable<String> add) {
  return purchaseIdsOf(<Object?>[
    ...purchaseIdsOf(current),
    ...add,
  ]);
}

bool samePurchaseIds(Iterable<String> a, Iterable<String> b) {
  if (a.length != b.length) return false;
  final other = b.toSet();
  return a.every(other.contains);
}

Future<void>? _pending;

/// Remembers store product ids on this phone and, for the signed-in account,
/// merges them into `users/{uid}/purchases`. That list is this phone's own
/// store record. Unlimited names come from checked entitlements. Existing ids
/// stay. The account is read when the write runs, so a purchase that arrives
/// during sign-in still attaches.
Future<void> rememberStorePurchases(Iterable<String> productIds) {
  final ids = <String>[
    for (final id in productIds)
      if (id.isNotEmpty) id,
  ];
  if (ids.isEmpty) return Future<void>.value();
  final run = (_pending ?? Future<void>.value()).then((_) => _remember(ids));
  _pending = run.catchError((Object error) {
    debugPrint('purchases: $error');
  });
  return run;
}

Future<void> _remember(List<String> add) async {
  final local = await Prefs.getStringListF(keyPurchases, const <String>[]);
  final next = mergePurchaseIds(local, add);
  if (!samePurchaseIds(next, local)) {
    await Prefs.setStringList(keyPurchases, next);
  }
  final uid = Auth.appUser?.uid;
  if (uid == null || uid.isEmpty || next.isEmpty) return;
  final ref = usersReference.child(uid).child(firebaseAttributePurchases);
  await ref.runTransaction((Object? current) {
    final merged = mergePurchaseIds(current, next);
    if (samePurchaseIds(merged, purchaseIdsOf(current))) {
      return Transaction.abort();
    }
    return Transaction.success(merged);
  });
}
