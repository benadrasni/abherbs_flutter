import 'dart:async';

import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static Future<void> _logOldVersionEvent() async {
    await FirebaseAnalytics().logEvent(name: 'offline_download');
  }

  static Future<String> signInWithCredential(AuthCredential credential) async {
    FirebaseUser user = await firebaseAuth.signInWithCredential(credential);
    return user.uid;
  }

  static Future<FirebaseUser> signInWithEmail(String email, String password) async {
    FirebaseUser user = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return user;
  }

  static Future<FirebaseUser> signUpWithEmail(String email, String password) async {
    FirebaseUser user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return user;
  }

  static Future<void> resetPassword(String email) async {
    return firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signUpWithPhone(Function(AuthCredential) verificationCompleted,
      Function(AuthException) verificationFailed,
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

  static Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await firebaseAuth.currentUser().then((user) {
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
    });
    return user;
  }

  static Future<void> signOut() async {
    return firebaseAuth.signOut();
  }

  static Future<void> sendEmailVerification() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    user.sendEmailVerification();
  }

  static Future<bool> isEmailVerified() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    return user.isEmailVerified;
  }

  static StreamSubscription<FirebaseUser> subscribe(Function(FirebaseUser) listener) {
    return firebaseAuth.onAuthStateChanged.listen(listener);
  }
}