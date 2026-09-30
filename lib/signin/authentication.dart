import 'dart:async';

import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  static User? appUser = firebaseAuth.currentUser;
  static int credits = 0;
  static int _accountGen = 0;
  static Future<void>? _loadingAccount;

  static Future<void> _logOldVersionEvent() async {
    await FirebaseAnalytics.instance.logEvent(name: 'offline_download');
  }

  static Future<void> signInWithCredential(AuthCredential credential) async {
    await firebaseAuth.signInWithCredential(credential);
    setUser();
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    setUser();
    return result.user;
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    UserCredential result = await firebaseAuth.createUserWithEmailAndPassword(
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
    final user = firebaseAuth.currentUser;
    if (gen != _accountGen) return;
    appUser = user;
    if (user == null) {
      credits = 0;
      Purchases.hasOldVersion = false;
      Purchases.hasLifetimeSubscription = false;
      return;
    }
    final uid = user.uid;
    usersReference.child(uid).keepSynced(true);
    try {
      final event = await usersReference.child(uid).once();
      if (gen != _accountGen) return;
      final value = event.snapshot.value;
      if (value is Map) {
        final old = value[firebaseAttributeOldVersion];
        Purchases.hasOldVersion = old == true;
        final rawCredits = value[firebaseAttributeCredits];
        credits = rawCredits is int ? rawCredits : 0;
      } else {
        Purchases.hasOldVersion = false;
        credits = 0;
      }
      if (Purchases.hasOldVersion) {
        unawaited(_logOldVersionEvent());
      }
      unawaited(Prefs.setBool(keyOldVersion, Purchases.hasOldVersion));
      unawaited(Prefs.getStringF(keyToken).then((token) {
        if (gen != _accountGen || token.isEmpty || appUser?.uid != uid) return;
        usersReference.child(uid).child(firebaseAttributeToken).set(token);
      }));
      unawaited(Prefs.getStringListF(keyPurchases, []).then((purchases) {
        if (gen != _accountGen || purchases.isEmpty || appUser?.uid != uid) {
          return;
        }
        usersReference
            .child(uid)
            .child(firebaseAttributePurchases)
            .set(purchases);
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

    try {
      final event = await usersReference
          .child(uid)
          .child(firebaseAttributeLifetimeSubscription)
          .once();
      if (gen != _accountGen) return;
      final value = event.snapshot.value;
      Purchases.hasLifetimeSubscription = value == true;
      unawaited(Prefs.setBool(
        keyLifetimeSubscription,
        Purchases.hasLifetimeSubscription,
      ));
    } catch (error) {
      if (gen != _accountGen) return;
      Purchases.hasLifetimeSubscription = false;
    }
  }

  static Future<void> changeCredits(int credit, String feature) async {
    if (appUser != null) {
      usersReference.child(appUser!.uid).keepSynced(true);
      await usersReference
          .child(appUser!.uid)
          .child(firebaseAttributeCredits)
          .once()
          .then((event) {
        credits = event.snapshot.value != null
            ? (event.snapshot.value as int) + credit
            : credit;
        logsCreditsReference
            .child(appUser!.uid)
            .child(DateTime.now().millisecondsSinceEpoch.toString())
            .set(feature);
      }).catchError((error) {
        credits = credit;
      });
      usersReference
          .child(appUser!.uid)
          .child(firebaseAttributeCredits)
          .set(credits);
    }
  }

  static Future<void> signOut() async {
    _accountGen++;
    _loadingAccount = null;
    appUser = null;
    credits = 0;
    return firebaseAuth.signOut();
  }

  static StreamSubscription<User?> subscribe(void Function(User?) listener) {
    return firebaseAuth.authStateChanges().listen((user) {
      appUser = user;
      if (user == null) credits = 0;
      listener(user);
    });
  }
}
