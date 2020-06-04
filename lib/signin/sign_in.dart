import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/signin/email.dart';
import 'package:abherbs_flutter/signin/phone.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen();

  @override
  _SignInScreenState createState() => new _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  Future<bool> supportsAppleSignIn;
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
      if (key.currentState != null && key.currentState.mounted) {
        key.currentState.showSnackBar(new SnackBar(
          content: new Text(S.of(context).auth_sign_in_failed),
        ));
      }
    }
  }

  Future<void> _handleAppleSignIn(GlobalKey<ScaffoldState> key) async {
    try {

      final AuthorizationResult result = await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          try {
            final AppleIdCredential appleIdCredential = result.credential;

            OAuthProvider oAuthProvider = OAuthProvider(providerId: "apple.com");
            final AuthCredential credential = oAuthProvider.getCredential(
              idToken: String.fromCharCodes(appleIdCredential.identityToken),
              accessToken: String.fromCharCodes(appleIdCredential.authorizationCode),
            );

            String userId = await Auth.signInWithCredential(credential);
            Navigator.pop(context);
            print('Signed in: $userId');
          } catch (e) {
            if (key.currentState != null && key.currentState.mounted) {
              key.currentState.showSnackBar(new SnackBar(
                content: new Text(S.of(context).auth_sign_in_failed),
              ));
            }
          }
          break;
        case AuthorizationStatus.error:
          if (key.currentState != null && key.currentState.mounted) {
            key.currentState.showSnackBar(new SnackBar(
              content: new Text(S.of(context).auth_sign_in_failed),
            ));
          }
          break;

        case AuthorizationStatus.cancelled:
          if (key.currentState != null && key.currentState.mounted) {
            key.currentState.showSnackBar(new SnackBar(
              content: new Text(S.of(context).auth_sign_in_failed),
            ));
          }
          break;
      }
    } catch (error) {
      if (key.currentState != null && key.currentState.mounted) {
        key.currentState.showSnackBar(new SnackBar(
          content: new Text(S.of(context).auth_sign_in_failed),
        ));
      }
    }
  }

  _handleEmailSignIn() async {
    Navigator.of(context).push(MaterialPageRoute<String>(
        builder: (BuildContext context) { return EmailLoginSignUpPage(); },
        settings: RouteSettings(name: 'EmailLoginSignUp')));
  }

  _handlePhoneSignIn() async {
    Navigator.of(context).push(MaterialPageRoute<String>(
        builder: (BuildContext context) { return PhoneLoginSignUpPage(Localizations.localeOf(context)); },
        settings: RouteSettings(name: 'PhoneLoginSignUp')));
  }

  @override
  void initState() {
    if (Platform.isIOS) {
      supportsAppleSignIn = DeviceInfoPlugin().iosInfo.then((value) {
        return value.systemVersion.contains('13');
      });
    } else {
      supportsAppleSignIn = Future(() => false);
    }
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
              FutureBuilder<bool>(
                future: supportsAppleSignIn,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.done:
                      if (snapshot.data) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                          child: RaisedButton(
                              color: Colors.white,
                              child: Row(
                                children: [
                                  Container(padding: const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0), child: Image.asset('res/images/apple-logo.png')),
                                  Expanded(
                                    child: Text(
                                      S.of(context).auth_apple,
                                      style: new TextStyle(fontSize: 18.0),
                                    ),
                                  )
                                ],
                              ),
                              onPressed: () {
                                _handleAppleSignIn(key);
                              }),
                        );
                      } else {
                        return Container();
                      }
                      break;
                    default:
                      return Container();
                  }
                }
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                child: Column(children: [
                  FlatButton(
                    onPressed: () {
                      launchURL(termsOfUseUrl);
                    },
                    child: Text(
                      S.of(context).terms_of_use,
                      style: TextStyle(color: Theme.of(context).accentColor, fontSize: 14.0),
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      launchURL(privacyPolicyUrl);
                    },
                    child: Text(
                      S.of(context).privacy_policy,
                      style: TextStyle(color: Theme.of(context).accentColor, fontSize: 14.0),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ));
  }
}
