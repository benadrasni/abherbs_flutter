import 'dart:io';
import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';

class PhoneLoginSignUpPage extends StatefulWidget {
  final Locale myLocale;

  PhoneLoginSignUpPage(this.myLocale);

  @override
  State<StatefulWidget> createState() => new _PhoneLoginSignUpPageState();
}

enum FormMode { PHONE, SMS }

const String errorInvalidCredential = 'invalidCredential';
const String errorInvalidVerificationCode = 'ERROR_INVALID_VERIFICATION_CODE';

class _PhoneLoginSignUpPageState extends State<PhoneLoginSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  Future<String> _errorMessage;
  firebase_auth.PhoneVerificationCompleted _verificationCompleted;
  firebase_auth.PhoneVerificationFailed _verificationFailed;
  firebase_auth.PhoneCodeSent _codeSent;
  firebase_auth.PhoneCodeAutoRetrievalTimeout _codeAutoRetrievalTimeout;

  Country _country;
  String _phone;
  bool _isWrongNumber;
  bool _showResendButton;
  String _verificationId;
  String _code;
  int _token;

  // Initial form is login form
  FormMode _formMode = FormMode.PHONE;
  bool _isLoading;

  // Check if form is valid before perform login or sign up
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or sign up
  void _validateAndSubmit() async {
    if (_validateAndSave()) {
      setState(() {
        _errorMessage = Future<String>.value('');
        _isLoading = true;
      });
      String userId = "";
      try {
        if (_formMode == FormMode.SMS) {
          userId = await Auth.signInWithCredential(firebase_auth.PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: _code));
          Navigator.pop(context);
          Navigator.pop(context);
          print('Signed in: $userId');
        } else {
          Auth.signUpWithPhone(_verificationCompleted, _verificationFailed, _codeSent, _codeAutoRetrievalTimeout, _phone);
        }
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        if (e.code == errorInvalidVerificationCode) {
          _isWrongNumber = true;
          _validateAndSave();
          _isWrongNumber = false;
          _showResendButton = true;
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            if (Platform.isIOS) {
              _errorMessage = Future<String>.value(e.details);
            } else {
              _errorMessage = Future<String>.value(e.message);
            }
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _errorMessage = Future<String>.value('');
    _isLoading = false;
    _isWrongNumber = false;
    _showResendButton = false;
    _country = Country.parse(widget.myLocale.countryCode);

    _verificationCompleted = (firebase_auth.AuthCredential credential) {
      Auth.signInWithCredential(credential);
      Navigator.pop(context);
      Navigator.pop(context);
    };

    _verificationFailed = (firebase_auth.FirebaseAuthException authException) {
      if (authException.code == errorInvalidCredential) {
        _isWrongNumber = true;
        _validateAndSave();
        _isWrongNumber = false;
      } else {
        setState(() {
          _errorMessage = Future<String>.value('Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}');
        });
      }
    };

    _codeSent = (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
      _token = forceResendingToken;
      _changeFormToSMS();
    };

    _codeAutoRetrievalTimeout = (String verificationId) {
      _verificationId = verificationId;
      _changeFormToSMS();
    };
  }

  void _changeFormToSMS() {
    if (_formKey.currentState != null && _formKey.currentState.mounted) {
      _formKey.currentState.reset();
      _errorMessage = Future<String>.value('');
      setState(() {
        _formMode = FormMode.SMS;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_formMode == FormMode.PHONE ? S.of(context).auth_verify_phone_number_title : S.of(context).auth_verify_phone_number),
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
              _showButton(),
              _showSecondaryButton(),
              _showMessage(),
              _showErrorMessage(),
            ],
          ),
        ));
  }

  Widget _showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: Stack(alignment: Alignment.center,
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

  Widget _showInput() {
    if (_formMode == FormMode.PHONE) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (Country country) {
                      setState(() {
                        _country = country;
                      });
                    },
                  );
                },
                child: Text('+' + _country.phoneCode),
              ),
            ),
            Expanded(
              flex: 4,
              child: TextFormField(
                maxLines: 1,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: S.of(context).auth_phone_hint,
                ),
                validator: (value) => value.isEmpty || _isWrongNumber ? S.of(context).auth_invalid_phone_number : null,
                onSaved: (value) => _phone = '+' + _country.phoneCode + value,
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: Column(
          children: [
            Text(
              S.of(context).auth_enter_confirmation_code + (_phone ?? ''),
              style: TextStyle(fontSize: 16.0),
            ),
            TextFormField(
              maxLength: 6,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              maxLines: 1,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: S.of(context).auth_code_hint,
              ),
              validator: (value) => value.length != 6 ? S.of(context).auth_invalid_code : _isWrongNumber ? S.of(context).auth_invalid_code : null,
              onSaved: (value) => _code = value,
            ),
          ],
        ),
      );
    }
  }

  Widget _showButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.blue, // background
              onPrimary: Colors.white, // foreground
              elevation: 5.0,
              shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            ),
            child: Text(
              _formMode == FormMode.SMS ? S.of(context).auth_sign_in: S.of(context).auth_verify_phone_number,
              style: TextStyle(fontSize: 20.0),
            ),
            onPressed: _validateAndSubmit,
          ),
        ));
  }

  Widget _showSecondaryButton() {
    if (_formMode == FormMode.SMS && _showResendButton) {
      return Padding(
          padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
          child: TextButton(
              child: Text(S.of(context).auth_resend_code,
                style: TextStyle(fontSize: 20.0, color: Colors.blue),
              ),
              onPressed: () {
                Auth.signUpWithPhone(_verificationCompleted, _verificationFailed, _codeSent, _codeAutoRetrievalTimeout, _phone, _token);
              },
            ),);
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showMessage() {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: Text(
        _formMode == FormMode.PHONE ? S.of(context).auth_sms_terms_of_service : '',
        style: const TextStyle(fontSize: 16.0, color: Colors.black, height: 1.0),
      ),
    );
  }

  Widget _showErrorMessage() {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: FutureBuilder<String>(
          future: _errorMessage,
          builder: (_, AsyncSnapshot<String> snapshot) {
            return Text(
              snapshot.data ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.0, color: Colors.red, height: 1.0),
            );
          }),
    );
  }
}
