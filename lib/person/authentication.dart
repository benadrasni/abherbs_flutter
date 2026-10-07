import 'dart:async';

import 'package:abherbs_flutter/purchase/account_entitlements.dart';
import 'package:abherbs_flutter/purchase/owned_purchases.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/purchase/store_proof.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class Auth {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  /// The signed-in account. The anonymous guest account is not one.
  static User? appUser = _signedIn(firebaseAuth.currentUser);
  static int credits = 0;
  static int _accountGen = 0;
  static Future<void>? _loadingAccount;
  static StreamSubscription<DatabaseEvent>? _entitlementsSub;

  static User? _signedIn(User? user) =>
      user == null || user.isAnonymous ? null : user;

  /// The anonymous account created at first launch, while no one is signed in.
  static User? get guestUser {
    final user = firebaseAuth.currentUser;
    return user != null && user.isAnonymous ? user : null;
  }

  static Future<void> _logOldVersionEvent() async {
    await FirebaseAnalytics.instance.logEvent(name: 'offline_download');
  }

  /// Creates the guest account once per install. Signing out does not create
  /// another, so its one free identification is not handed out again.
  static Future<void> startGuest() async {
    if (firebaseAuth.currentUser != null) return;
    if (Prefs.getBool(keyGuestCreated, false)) return;
    try {
      await firebaseAuth.signInAnonymously();
      await Prefs.setBool(keyGuestCreated, true);
    } catch (error) {
      debugPrint('guest account: $error');
    }
  }

  /// Links the guest account so its uid, and the identification it used,
  /// carry over. A credential that already has an account signs in to it.
  static Future<UserCredential> _linkOrSignIn(AuthCredential credential) async {
    final guest = guestUser;
    if (guest != null) {
      try {
        return await guest.linkWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (error.code != 'credential-already-in-use' &&
            error.code != 'email-already-in-use') {
          rethrow;
        }
        return firebaseAuth
            .signInWithCredential(error.credential ?? credential);
      }
    }
    return firebaseAuth.signInWithCredential(credential);
  }

  static Future<void> signInWithCredential(AuthCredential credential) async {
    await _linkOrSignIn(credential);
    setUser();
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    setUser();
    return result.user;
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    final guest = guestUser;
    UserCredential result = guest != null
        ? await guest.linkWithCredential(
            EmailAuthProvider.credential(email: email, password: password))
        : await firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password);
    setUser();
    return result.user;
  }

  static Future<void> resetPassword(String email) async {
    return firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signUpWithPhone(
      PhoneVerificationCompleted verificationCompleted,
      PhoneVerificationFailed verificationFailed,
      PhoneCodeSent codeSent,
      PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
      String phoneNumber,
      [int? token]) async {
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 5),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: token,
    );
  }

  /// Reads the signed-in account. Callers share one read until it finishes,
  /// so Find can wait for credits and purchased features before it redraws.
  static Future<void> setUser() {
    final pending = _loadingAccount;
    if (pending != null) return pending;
    late final Future<void> run;
    run = _readAccount().whenComplete(() {
      if (identical(_loadingAccount, run)) _loadingAccount = null;
    });
    _loadingAccount = run;
    return run;
  }

  static Future<void> _readAccount() async {
    final gen = _accountGen;
    final user = _signedIn(firebaseAuth.currentUser);
    if (gen != _accountGen) return;
    appUser = user;
    if (user == null) {
      _stopEntitlements();
      credits = 0;
      Purchases.hasOldVersion = false;
      Purchases.clearAccountProducts();
      if (gen == _accountGen) Purchases.finishNames();
      return;
    }
    final uid = user.uid;
    usersReference.child(uid).keepSynced(true);
    try {
      final event = await usersReference.child(uid).once();
      if (gen != _accountGen) return;
      var value = event.snapshot.value;
      try {
        // once() can return the on-disk user from before this phone's plan
        // was written. The entitlements child is read from the server.
        final fresh =
            await usersReference.child(uid).child('entitlements').get();
        if (gen != _accountGen) return;
        value = userWithFreshEntitlements(value, fresh.value);
      } catch (error) {
        debugPrint('entitlements: $error');
      }
      if (value is Map) {
        final old = value[firebaseAttributeOldVersion];
        Purchases.hasOldVersion = old == true;
        final rawCredits = value[firebaseAttributeCredits];
        credits = rawCredits is int ? rawCredits : 0;
        final entitlements = accountEntitlementsOf(value);
        applyAccountEntitlements(entitlements);
        final revoked = revokedEntitlementIds(entitlements).toSet();
        unawaited(() async {
          await forgetRevokedPurchases(revoked);
          if (gen != _accountGen || appUser?.uid != uid) return;
          final purchases = await Prefs.getStringListF(keyPurchases, []);
          if (purchases.isEmpty) return;
          await rememberStorePurchases(purchases);
        }());
      } else {
        Purchases.hasOldVersion = false;
        credits = 0;
        Purchases.clearAccountProducts();
        unawaited(Prefs.getStringListF(keyPurchases, []).then((purchases) {
          if (gen != _accountGen || purchases.isEmpty || appUser?.uid != uid) {
            return Future<void>.value();
          }
          return rememberStorePurchases(purchases);
        }));
      }
      if (Purchases.hasOldVersion) {
        unawaited(_logOldVersionEvent());
      }
      unawaited(Prefs.setBool(keyOldVersion, Purchases.hasOldVersion));
      unawaited(Prefs.getStringF(keyToken).then((token) {
        if (gen != _accountGen || token.isEmpty || appUser?.uid != uid) return;
        usersReference.child(uid).child(firebaseAttributeToken).set(token);
      }));
    } catch (error) {
      if (gen != _accountGen) return;
      Purchases.hasOldVersion = false;
      credits = 0;
    }

    if (Purchases.isPhotoSearch()) {
      rootReference
          .child(firebaseSearchPhoto)
          .child(firebaseAttributeEntity)
          .keepSynced(true);
    }

    if (gen == _accountGen) {
      Purchases.finishNames();
      _watchEntitlements(uid, gen);
      unawaited(registerStoreAccount());
      unawaited(flushPendingStoreProofs());
    }
  }

  /// Later checks, expiries, and the other phone's purchase. The account
  /// read above already applied the current row, so this does not upload
  /// the local store list again.
  static void _watchEntitlements(String uid, int gen) {
    _stopEntitlements();
    final watch = EntitlementWatch();
    _entitlementsSub = usersReference
        .child(uid)
        .child('entitlements')
        .onValue
        .listen((event) {
      if (gen != _accountGen || appUser?.uid != uid) return;
      final raw = event.snapshot.value;
      final snapshot = accountEntitlementsOf(
        raw == null ? <String, Object?>{} : <String, Object?>{'entitlements': raw},
      );
      if (!watch.shouldApply(snapshot)) return;
      applyAccountEntitlements(snapshot);
      unawaited(forgetRevokedPurchases(revokedEntitlementIds(snapshot)));
    }, onError: (Object error) {
      debugPrint('entitlements: $error');
    });
  }

  static void _stopEntitlements() {
    final sub = _entitlementsSub;
    _entitlementsSub = null;
    if (sub != null) unawaited(sub.cancel());
  }

  static Future<void> signOut() async {
    _accountGen++;
    _loadingAccount = null;
    _stopEntitlements();
    appUser = null;
    credits = 0;
    Purchases.clearAccountProducts();
    return firebaseAuth.signOut();
  }

  /// Linking the guest account keeps the same user, so `authStateChanges`
  /// stays quiet; `userChanges` reports it. Listeners see the guest as null.
  static StreamSubscription<User?> subscribe(void Function(User?) listener) {
    return firebaseAuth.userChanges().listen((user) {
      final signedIn = _signedIn(user);
      appUser = signedIn;
      if (signedIn == null) credits = 0;
      Purchases.holdNamesFor(signedIn?.uid);
      listener(signedIn);
    });
  }
}
