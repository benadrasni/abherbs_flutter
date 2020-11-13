import 'dart:async';

import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class Auth {
  static firebase_auth.FirebaseAuth firebaseAuth = firebase_auth.FirebaseAuth.instance;

  static Future<void> _logOldVersionEvent() async {
    await FirebaseAnalytics().logEvent(name: 'offline_download');
  }

  static Future<String> signInWithCredential(firebase_auth.AuthCredential credential) async {
    firebase_auth.UserCredential result = await firebaseAuth.signInWithCredential(credential);
    return result.user.uid;
  }

  static Future<firebase_auth.User> signInWithEmail(String email, String password) async {
    firebase_auth.UserCredential result = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return result.user;
  }

  static Future<firebase_auth.User> signUpWithEmail(String email, String password) async {
    firebase_auth.UserCredential result = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return result.user;
  }

  static Future<void> resetPassword(String email) async {
    return firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signUpWithPhone(Function(firebase_auth.AuthCredential) verificationCompleted,
      Function(firebase_auth.FirebaseAuthException) verificationFailed,
      Function(String, [int]) codeSent,
      Function(String) codeAutoRetrievalTimeout,
      String phoneNumber, [int token]) async {


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

  static firebase_auth.User getCurrentUser() {
    firebase_auth.User user = firebaseAuth.currentUser;
    if (user != null) {
      usersReference.child(user.uid).keepSynced(true);
      if (Purchases.hasOldVersion == null) {
        usersReference.child(user.uid).child(firebaseAttributeOldVersion).once().then((snapshot) {
          Purchases.hasOldVersion = snapshot.value != null && snapshot.value;
          if (Purchases.hasOldVersion) {
            _logOldVersionEvent();
          }
        }).catchError((error) {
          Purchases.hasOldVersion = false;
        });
        Prefs.getStringF(keyToken).then((token) {
          if (token.isNotEmpty) {
            usersReference.child(user.uid).child(firebaseAttributeToken).set(token);
          }
        });
        Prefs.getStringListF(keyPurchases, []).then((purchases) {
          if (purchases.length > 0) {
            usersReference.child(user.uid).child(firebaseAttributePurchases).set(purchases);
          }
        });
        if (Purchases.isPhotoSearch()) {
          rootReference.child(firebaseSearchPhoto).child(firebaseAttributeEntity).keepSynced(true);
        }
      }
      if (Purchases.hasLifetimeSubscription == null) {
        usersReference.child(user.uid).child(firebaseAttributeLifetimeSubscription).once().then((snapshot) {
          Purchases.hasLifetimeSubscription = snapshot.value != null && snapshot.value;
        }).catchError((error) {
          Purchases.hasLifetimeSubscription = false;
        });
      }
    } else {
      Purchases.hasOldVersion = null;
      Purchases.hasLifetimeSubscription = null;
    }
    return user;
  }

  static Future<void> signOut() async {
    return firebaseAuth.signOut();
  }

  static StreamSubscription<firebase_auth.User> subscribe(Function(firebase_auth.User) listener) {
    return firebaseAuth.authStateChanges().listen(listener);
  }
}