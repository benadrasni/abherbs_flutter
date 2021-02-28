import 'dart:async';

import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AppUser {
  firebase_auth.User firebaseUser;
  int credits = 0;
}

class Auth {
  static firebase_auth.FirebaseAuth firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static AppUser appUser;

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

  static AppUser getAppUser() {
    if (appUser == null) {
      firebase_auth.User firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser != null) {
        appUser = AppUser();
        appUser.firebaseUser = firebaseUser;
        usersReference.child(appUser.firebaseUser.uid).keepSynced(true);
        if (Purchases.hasOldVersion == null) {

          usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributeOldVersion).once().then((snapshot) {
            Purchases.hasOldVersion = snapshot.value != null && snapshot.value;
            if (Purchases.hasOldVersion) {
              _logOldVersionEvent();
            }
          }).catchError((error) {
            Purchases.hasOldVersion = false;
          });

          usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributeCredits).once().then((snapshot) {
            appUser.credits = snapshot.value != null ? snapshot.value : 0;
          }).catchError((error) {
            if(appUser != null) {
              appUser.credits = 0;
            }
          });

          Prefs.getStringF(keyToken).then((token) {
            if (token.isNotEmpty) {
              usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributeToken).set(token);
            }
          });

          Prefs.getStringListF(keyPurchases, []).then((purchases) {
            if (purchases.length > 0) {
              usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributePurchases).set(purchases);
            }
          });
        }
        if (Purchases.isPhotoSearch()) {
          rootReference.child(firebaseSearchPhoto).child(firebaseAttributeEntity).keepSynced(true);
        }

        if (Purchases.hasLifetimeSubscription == null) {
          usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributeLifetimeSubscription).once().then((snapshot) {
            Purchases.hasLifetimeSubscription = snapshot.value != null && snapshot.value;
          }).catchError((error) {
            Purchases.hasLifetimeSubscription = false;
          });
        }
      } else {
        Purchases.hasOldVersion = null;
        Purchases.hasLifetimeSubscription = null;
      }
    }

    return appUser;
  }

  static Future<void> changeCredits(int credit, String feature) async {
    if (appUser != null) {
      usersReference.child(appUser.firebaseUser.uid).keepSynced(true);
      await usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributeCredits).once().then((snapshot) {
        appUser.credits = snapshot.value != null ? snapshot.value + credit : credit;
        logsCreditsReference.child(appUser.firebaseUser.uid).child(DateTime.now().millisecondsSinceEpoch.toString()).set(feature);
      }).catchError((error) {
        appUser.credits = credit;
      });
      usersReference.child(appUser.firebaseUser.uid).child(firebaseAttributeCredits).set(appUser.credits);
    }
  }

  static Future<void> signOut() async {
    appUser = null;
    return firebaseAuth.signOut();
  }

  static StreamSubscription<firebase_auth.User> subscribe(Function(firebase_auth.User) listener) {
    return firebaseAuth.authStateChanges().listen(listener);
  }
}