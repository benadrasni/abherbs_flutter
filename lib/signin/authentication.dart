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

  static Future<void> _logOldVersionEvent() async {
    await FirebaseAnalytics.instance.logEvent(name: 'offline_download');
  }

  static Future<void> signInWithCredential(AuthCredential credential) async {
    await firebaseAuth.signInWithCredential(credential);
    setUser();
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    setUser();
    return result.user;
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    UserCredential result = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    setUser();
    return result.user;
  }

  static Future<void> resetPassword(String email) async {
    return firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signUpWithPhone(PhoneVerificationCompleted verificationCompleted,
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

  static void setUser() {
    appUser = firebaseAuth.currentUser;
    if (appUser != null) {
      usersReference.child(appUser!.uid).keepSynced(true);

      usersReference.child(appUser!.uid).once().then((event) {
        Purchases.hasOldVersion = event.snapshot.value != null && (event.snapshot.value as Map)[firebaseAttributeOldVersion] != null && (event.snapshot.value as Map)[firebaseAttributeOldVersion];
        if (Purchases.hasOldVersion) {
          _logOldVersionEvent();
        }
        Prefs.setBool(keyOldVersion, Purchases.hasOldVersion);

        credits = event.snapshot.value != null && (event.snapshot.value as Map)[firebaseAttributeCredits] != null ? (event.snapshot.value as Map)[firebaseAttributeCredits] : 0;

        Prefs.getStringF(keyToken).then((token) {
          if (token.isNotEmpty) {
            usersReference.child(appUser!.uid).child(firebaseAttributeToken).set(token);
          }
        });

        Prefs.getStringListF(keyPurchases, []).then((purchases) {
          if (purchases.length > 0) {
            usersReference.child(appUser!.uid).child(firebaseAttributePurchases).set(purchases);
          }
        });
      }).catchError((error) {
        Purchases.hasOldVersion = false;
        credits = 0;
      });

      if (Purchases.isPhotoSearch()) {
        rootReference.child(firebaseSearchPhoto).child(firebaseAttributeEntity).keepSynced(true);
      }

      usersReference.child(appUser!.uid).child(firebaseAttributeLifetimeSubscription).once().then((event) {
        Purchases.hasLifetimeSubscription = event.snapshot.value != null && (event.snapshot.value as bool);
        Prefs.setBool(keyLifetimeSubscription, Purchases.hasLifetimeSubscription);
      }).catchError((error) {
        Purchases.hasLifetimeSubscription = false;
      });
    } else {
      Purchases.hasOldVersion = false;
      Purchases.hasLifetimeSubscription = false;
    }
  }

  static Future<void> changeCredits(int credit, String feature) async {
    if (appUser != null) {
      usersReference.child(appUser!.uid).keepSynced(true);
      await usersReference.child(appUser!.uid).child(firebaseAttributeCredits).once().then((event) {
        credits = event.snapshot.value != null ? (event.snapshot.value as int) + credit : credit;
        logsCreditsReference.child(appUser!.uid).child(DateTime.now().millisecondsSinceEpoch.toString()).set(feature);
      }).catchError((error) {
        credits = credit;
      });
      usersReference.child(appUser!.uid).child(firebaseAttributeCredits).set(credits);
    }
  }

  static Future<void> signOut() async {
    appUser = null;
    return firebaseAuth.signOut();
  }

  static StreamSubscription<User?> subscribe(Function(User?) listener) {
    return firebaseAuth.authStateChanges().listen(listener);
  }
}