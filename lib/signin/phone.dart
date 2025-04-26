import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<String>? _errorMessage;
  late PhoneVerificationCompleted _verificationCompleted;
  late PhoneVerificationFailed _verificationFailed;
  late PhoneCodeSent _codeSent;
  late PhoneCodeAutoRetrievalTimeout _codeAutoRetrievalTimeout;

  Country _country = Country.parse('US');
  String? _phone;
  String? _verificationId;
  String? _code;
  int? _token;

  // Initial form is login form
  FormMode _formMode = FormMode.PHONE;
  bool _isLoading = false;
  bool _isWrongNumber = false;
  bool _showResendButton = false;

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
      try {
        if (_formMode == FormMode.SMS) {
          await Auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _code!));
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          Auth.signUpWithPhone(_verificationCompleted, _verificationFailed, _codeSent, _codeAutoRetrievalTimeout, _phone!);
        }
        setState(() {
          _isLoading = false;
        });
      } on FirebaseAuthException catch (e) {
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
            _errorMessage = Future<String>.value(e.message);
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
    if (widget.myLocale.countryCode != null && widget.myLocale.countryCode!.isNotEmpty) {
      _country = Country.parse(widget.myLocale.countryCode!);
    }

    _verificationCompleted = (AuthCredential credential) {
      Auth.signInWithCredential(credential);
      Navigator.pop(context);
      Navigator.pop(context);
    };

    _verificationFailed = (FirebaseAuthException authException) {
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

    _codeSent = (String verificationId, int? forceResendingToken) {
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
    if (_formKey.currentState != null && _formKey.currentState!.mounted) {
      _formKey.currentState!.reset();
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
                validator: (value) => value == null || value.isEmpty || _isWrongNumber ? S.of(context).auth_invalid_phone_number : null,
                onSaved: (value) => _phone = '+' + _country.phoneCode + value!,
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
              validator: (value) => value == null || value.length != 6 ? S.of(context).auth_invalid_code : _isWrongNumber ? S.of(context).auth_invalid_code : null,
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
              backgroundColor: Colors.blue, // background
              foregroundColor: Colors.white, // foreground
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
                Auth.signUpWithPhone(_verificationCompleted, _verificationFailed, _codeSent, _codeAutoRetrievalTimeout, _phone!, _token);
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
