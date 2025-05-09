import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/signin/email.dart';
import 'package:abherbs_flutter/signin/phone.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInScreen extends StatefulWidget {
  SignInScreen();

  @override
  _SignInScreenState createState() => new _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late Future<bool> supportsAppleSignIn;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String _createNonce(int length) {
    final random = Random();
    final charCodes = List<int>.generate(length, (_) {
      int codeUnit = 0;

      switch (random.nextInt(3)) {
        case 0:
          codeUnit = random.nextInt(10) + 48;
          break;
        case 1:
          codeUnit = random.nextInt(26) + 65;
          break;
        case 2:
          codeUnit = random.nextInt(26) + 97;
          break;
      }

      return codeUnit;
    });

    return String.fromCharCodes(charCodes);
  }

  Future<void> _handleGoogleSignIn(GlobalKey<ScaffoldState> key) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken != null) {
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await Auth.signInWithCredential(credential);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (key.currentState != null && key.currentState!.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: new Text(S.of(context).auth_sign_in_failed),
        ));
      }
    }
  }

  Future<void> _handleAppleSignIn(GlobalKey<ScaffoldState> key, AuthorizationCredentialAppleID appleCredential) async {
    try {
      final nonce = _createNonce(32);

      OAuthCredential credential = OAuthCredential(
        providerId: "apple.com",
        signInMethod: "oauth",
        accessToken: appleCredential.authorizationCode,
        idToken: appleCredential.identityToken,
        rawNonce: nonce,
      );

      await Auth.signInWithCredential(credential);
      Navigator.pop(context);
    } catch (error) {
      if (key.currentState != null && key.currentState!.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    super.initState();
    if (Platform.isIOS) {
      supportsAppleSignIn = DeviceInfoPlugin().iosInfo.then((value) {
        int version = 0;
        try {
          version = int.parse(value.systemVersion.split('.')[0]);
        } catch(e) {
          print(e);
        }
        return version >= 13;
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
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(219, 68, 55, 1.0), // background
                    ),
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
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // background
                    ),
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
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // background
                      foregroundColor: Colors.black, // foreground
                    ),
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
                      if (snapshot.data != null) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                          child: SignInWithAppleButton(
                              onPressed: () async {
                                final credential = await SignInWithApple.getAppleIDCredential(
                                  scopes: [
                                    AppleIDAuthorizationScopes.email,
                                    AppleIDAuthorizationScopes.fullName,
                                  ],
                                );
                                _handleAppleSignIn(key, credential);
                              }
                        ));
                      } else {
                        return Container();
                      }
                    default:
                      return Container();
                  }
                }
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(50.0, 5.0, 50.0, 5.0),
                child: Column(children: [
                  ElevatedButton(
                    onPressed: () {
                      launchURL(termsOfUseUrl);
                    },
                    child: Text(
                      S.of(context).terms_of_use,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      launchURL(privacyPolicyUrl);
                    },
                    child: Text(
                      S.of(context).privacy_policy,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ));
  }
}
