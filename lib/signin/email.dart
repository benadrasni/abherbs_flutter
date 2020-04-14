import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/signin/authetication.dart';

class EmailLoginSignUpPage extends StatefulWidget {
  EmailLoginSignUpPage();

  @override
  State<StatefulWidget> createState() => new _EmailLoginSignUpPageState();
}

enum FormMode { LOGIN, SIGNUP }

const String errorWrongPassword = 'ERROR_WRONG_PASSWORD';

class _EmailLoginSignUpPageState extends State<EmailLoginSignUpPage> {
  final _formKey = new GlobalKey<FormState>();

  String _email;
  String _password;
  String _errorMessage;
  bool _isWrongPassword;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool _isLoading;

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or sign up
  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      setState(() {
        _errorMessage = "";
        _isLoading = true;
      });
      FirebaseUser user;
      try {
        if (_formMode == FormMode.LOGIN) {
          user = await Auth.signInWithEmail(_email, _password);
          if (!user.isEmailVerified) {
            _showVerifyEmailSentDialog(user).then((value) {
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
              Auth.signOut();
            });
          } else {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context);
            }
          }
        } else {
          user = await Auth.signUpWithEmail(_email, _password);
          user.sendEmailVerification();
          _showVerifyEmailSentDialog(user).then((value) {
            if (mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
            Auth.signOut();
          });
        }
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _isWrongPassword = e.code == errorWrongPassword;
            _isLoading = false;
            if (Platform.isIOS) {
              _errorMessage = e.details;
            } else
              _errorMessage = e.message;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _errorMessage = "";
    _isLoading = false;
    _isWrongPassword = false;
  }

  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).auth_email),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
          ],
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Future<dynamic> _showVerifyEmailSentDialog(FirebaseUser user) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).auth_verify_email_title),
          content: Text(S.of(context).auth_verify_email_message),
          actions: <Widget>[
            FlatButton(
              child: Text(S.of(context).auth_resend_email),
              onPressed: () {
                if (user != null) {
                  user.sendEmailVerification();
                }
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(S.of(context).close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> _showResetPasswordEmailSentDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).auth_reset_password_email_title),
          content: Text(S.of(context).auth_reset_password_email_message(_email)),
          actions: <Widget>[
            FlatButton(
              child: Text(S.of(context).close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _showBody() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _showSecondaryButton(),
              _showErrorMessage(),
              _showTertiaryButton(),
            ],
          ),
        ));
  }

  Widget _showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 48.0,
              child: Image.asset('res/images/home.png'),
            ),
            _showCircularProgress(),
          ],
        ),
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        initialValue: _email,
        decoration: InputDecoration(
            hintText: S.of(context).auth_email_hint,
            icon: Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) =>
            value.isEmpty || !RegExp(r"^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$").hasMatch(value) ? S.of(context).auth_invalid_email_address : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: InputDecoration(
            hintText: S.of(context).auth_password_hint,
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? S.of(context).auth_empty_password : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  Widget _showPrimaryButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: RaisedButton(
            elevation: 5.0,
            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: Text(
              _formMode == FormMode.LOGIN ? S.of(context).auth_sign_in : S.of(context).auth_create_account,
              style: TextStyle(fontSize: 20.0, color: Colors.white),
            ),
            onPressed: _validateAndSubmit,
          ),
        ));
  }

  Widget _showSecondaryButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
      child: FlatButton(
        child: Text(
          _formMode == FormMode.LOGIN ? S.of(context).auth_create_account : S.of(context).auth_sign_in_text,
          style: TextStyle(fontSize: 20.0, color: Colors.blue),
        ),
        onPressed: _formMode == FormMode.LOGIN ? _changeFormToSignUp : _changeFormToLogin,
      ),
    );
  }

  Widget _showTertiaryButton() {
    if (_formMode == FormMode.LOGIN && _isWrongPassword) {
      return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
        child: FlatButton(
          child: Text(S.of(context).auth_reset_password,
            style: TextStyle(fontSize: 20.0, color: Colors.blue),
          ),
          onPressed: () {
            Auth.resetPassword(_email);
            _showResetPasswordEmailSentDialog();
          },
        ),);
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showErrorMessage() {
    if (_errorMessage != null && _errorMessage.length > 0) {
      return Container(
        padding: EdgeInsets.all(5.0),
        child: Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.0, color: Colors.red, height: 1.0),
        ),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }
}
