import 'dart:async';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_country_picker/flutter_country_picker.dart';

class PhoneLoginSignUpPage extends StatefulWidget {
  PhoneLoginSignUpPage({this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _PhoneLoginSignUpPageState();
}

enum FormMode { PHONE, SMS }

class _PhoneLoginSignUpPageState extends State<PhoneLoginSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _smsCodeController = TextEditingController();
  Future<String> _message;
  PhoneVerificationCompleted _verificationCompleted;
  PhoneVerificationFailed _verificationFailed;
  PhoneCodeSent _codeSent;
  PhoneCodeAutoRetrievalTimeout _codeAutoRetrievalTimeout;

  Country _selected;
  String _phone;
  String _verificationId;
  String _sms;

  // Initial form is login form
  FormMode _formMode = FormMode.PHONE;
  bool _isIos;
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

  // Perform login or signup
  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      setState(() {
        _message = Future<String>.value('');
        _isLoading = true;
      });
      String userId = "";
      try {
        if (_formMode == FormMode.SMS) {
          //userId = await Auth.signInWithEmail(_email, _password);
          Navigator.pop(context);
          Navigator.pop(context);
          print('Signed in: $userId');
        } else {
          Auth.signUpWithPhone(_verificationCompleted, _verificationFailed, _codeSent, _codeAutoRetrievalTimeout, _phone);
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null && _formMode == FormMode.SMS) {
          widget.onSignedIn();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          if (_isIos) {
            _message = e.details;
          } else
            _message = e.message;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _message = Future<String>.value('');
    _isLoading = false;

    _verificationCompleted = (FirebaseUser user) {
      setState(() {
        _message = Future<String>.value('signInWithPhoneNumber auto succeeded: $user');
      });
    };

    _verificationFailed = (AuthException authException) {
      Navigator.pop(context);
      Navigator.pop(context);
    };

    _codeSent = (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
      //_smsCodeController.text = testSmsCode;
    };

    _codeAutoRetrievalTimeout = (String verificationId) {
      _verificationId = verificationId;
      //_smsCodeController.text = testSmsCode;
    };
  }

  void _changeFormToSMS() {
    _formKey.currentState.reset();
    _message = Future<String>.value('');
    setState(() {
      _formMode = FormMode.SMS;
    });
  }

  void _changeFormToPhone() {
    _formKey.currentState.reset();
    _message = Future<String>.value('');
    setState(() {
      _formMode = FormMode.PHONE;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).phone),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
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

  void _showVerifyPhoneSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).verify_phone_title),
          content: Text(S.of(context).verify_phone_message),
          actions: <Widget>[
            FlatButton(
              child: Text(S.of(context).close),
              onPressed: () {
                _changeFormToSMS();
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
              _showInput(),
              _showPrimaryButton(),
              _showMessage(),
            ],
          ),
        ));
  }

  Widget _showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('res/images/home.png'),
        ),
      ),
    );
  }

  Widget _showInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CountryPicker(
              onChanged: (Country country) {
                setState(() {
                  _selected = country;
                });
              },
              selectedCountry: _selected,
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              maxLines: 1,
              keyboardType: TextInputType.phone,
              autofocus: false,
              decoration: InputDecoration(
                hintText: _formMode == FormMode.PHONE ? S.of(context).phone_hint : S.of(context).sms_hint,
              ),
              validator: (value) =>
                  value.isEmpty ? _formMode == FormMode.PHONE ? S.of(context).phone_validation_message : S.of(context).sms_validation_message : null,
              onSaved: (value) => _phone = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _showPrimaryButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: RaisedButton(
            elevation: 5.0,
            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: _formMode == FormMode.SMS
                ? Text(S.of(context).login, style: TextStyle(fontSize: 20.0, color: Colors.white))
                : Text(S.of(context).verify_phone, style: TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: _validateAndSubmit,
          ),
        ));
  }

  Widget _showMessage() {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: FutureBuilder<String>(
          future: _message,
          builder: (_, AsyncSnapshot<String> snapshot) {
            return Text(
              snapshot.data ?? '',
              style: const TextStyle(fontSize: 14.0, color: Colors.red, height: 1.0, fontWeight: FontWeight.w300),
            );
          }),
    );
  }
}
