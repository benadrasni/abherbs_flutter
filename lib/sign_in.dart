import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen();

  @override
  _SignInScreenState createState() => new _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleGoogleSignIn() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken != null) {
        try {
          final AuthCredential credential = GoogleAuthProvider.getCredential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final FirebaseUser user = await _auth.signInWithCredential(credential);
          print(user);
        } catch (e) {
          print(e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();

    return Scaffold(
        key: key,
        appBar: AppBar(
          title: Text(S.of(context).login),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: new RaisedButton(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0), child: Image.asset('res/images/go-logo.png')),
                        Expanded(
                          child: Text(
                            S.of(context).google,
                            style: new TextStyle(fontSize: 18.0),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      _handleGoogleSignIn();
                    }),
              )
            ],
          ),
        ));
  }
}
