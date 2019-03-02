import 'dart:async';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/signin/email.dart';
import 'package:abherbs_flutter/signin/phone.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen();

  @override
  _SignInScreenState createState() => new _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleGoogleSignIn(GlobalKey<ScaffoldState> key) async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken != null) {
          final AuthCredential credential = GoogleAuthProvider.getCredential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          String userId = await Auth.signInWithCredential(credential);
          Navigator.pop(context);
          print('Signed in: $userId');
        }
      }
    } catch (e) {
      key.currentState.showSnackBar(new SnackBar(
        content: new Text(S.of(context).auth_sign_in_failed),
      ));
    }
  }

  _handleTwitterSignIn(GlobalKey<ScaffoldState> key) async {
    try {
      var twitterCredential = TwitterAuthProvider.getCredential(authToken: twitterAccessKey, authTokenSecret: twitterAccessSecret);
      String userId = await Auth.signInWithCredential(twitterCredential);
      Navigator.pop(context);
      print('Signed in: $userId');
    } catch (e) {
      key.currentState.showSnackBar(new SnackBar(
        content: new Text(S.of(context).auth_sign_in_failed),
      ));
    }
  }

  _handleEmailSignIn() async {
    Navigator.of(context).push(MaterialPageRoute<String>(builder: (BuildContext context) {
      return EmailLoginSignUpPage();
    }));
  }

  _handlePhoneSignIn() async {
    Navigator.of(context).push(MaterialPageRoute<String>(builder: (BuildContext context) {
      return PhoneLoginSignUpPage(Localizations.localeOf(context));
    }));
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<ScaffoldState>();

    return Scaffold(
        key: key,
        appBar: AppBar(
          title: Text(S.of(context).auth_sign_in),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                child: RaisedButton(
                    color: Color.fromRGBO(219, 68, 55, 1.0),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0), child: Image.asset('res/images/email-logo.png')),
                        Expanded(
                          child: Text(
                            S.of(context).auth_email,
                            style: new TextStyle(color: Colors.white, fontSize: 18.0),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      _handleEmailSignIn();
                    }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                child: RaisedButton(
                    color: Colors.green,
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0), child: Image.asset('res/images/phone-logo.png')),
                        Expanded(
                          child: Text(
                            S.of(context).auth_phone,
                            style: new TextStyle(color: Colors.white, fontSize: 18.0),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      _handlePhoneSignIn();
                    }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                child: RaisedButton(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0), child: Image.asset('res/images/go-logo.png')),
                        Expanded(
                          child: Text(
                            S.of(context).auth_google,
                            style: new TextStyle(fontSize: 18.0),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      _handleGoogleSignIn(key);
                    }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                child: RaisedButton(
                    color: Color.fromRGBO(29, 161, 242, 1.0),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0), child: Image.asset('res/images/twitter-logo.png')),
                        Expanded(
                          child: Text(
                            S.of(context).auth_twitter,
                            style: new TextStyle(color: Colors.white, fontSize: 18.0),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      _handleTwitterSignIn(key);
                    }),
              )
            ],
          ),
        ));
  }
}
