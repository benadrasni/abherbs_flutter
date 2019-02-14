import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static Future<String> signInWithCredential(AuthCredential credential) async {
    FirebaseUser user = await firebaseAuth.signInWithCredential(credential);
    return user.uid;
  }

  static Future<String> signIn(String email, String password) async {
    FirebaseUser user = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return user.uid;
  }

  static Future<String> signUp(String email, String password) async {
    FirebaseUser user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return user.uid;
  }

  static Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await firebaseAuth.currentUser();
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