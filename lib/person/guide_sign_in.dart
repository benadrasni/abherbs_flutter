/// What the email form does after Firebase answers.
enum GuideEmailFollowUp {
  signedIn,
  needsVerification,
  tryCreate,
  wrongPassword,
  shortPassword,
  failed,
}

/// A phone-auth failure the form can explain.
enum GuidePhoneFailure { invalidNumber, wrongCode, failed }

const guideSignInRouteName = 'GuideSignIn';

/// Large Strelitzia reginae plate used as the sign-in hero.
const guideSignInPlatePath =
    'photos/Zingiberales/Strelitziaceae/Strelitzia_reginae/Strelitzia_reginae@1600.webp';

/// A blank or broken address stays on the form. `+` and a long ending such
/// as `.online` are allowed; Firebase still rejects an address it cannot use.
final RegExp _emailPattern = RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
  r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
  r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
);

bool guideEmailLooksValid(String value) {
  return _emailPattern.hasMatch(value.trim());
}

/// E.164 number from a calling code and whatever the person typed.
///
/// A national trunk `0`, a typed `00`, and the calling code typed again are
/// not part of the number Firebase dials.
String guidePhoneNumber(String callingCode, String local) {
  final code = callingCode.replaceAll(RegExp(r'\D'), '');
  var digits = local.replaceAll(RegExp(r'\D'), '');
  if (code.isEmpty || digits.isEmpty) return '';
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  if (digits.startsWith(code) && digits.length > code.length) {
    digits = digits.substring(code.length);
  }
  while (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.isEmpty) return '';
  return '+$code$digits';
}

/// [code] is null when Firebase signed in.
///
/// A missing account and a wrong password can both come back as
/// `invalid-credential`. The form tries to create the account, and create
/// then reports `email-already-in-use` when the password was wrong.
GuideEmailFollowUp guideEmailFollowUp({
  required bool creating,
  String? code,
  bool verified = true,
}) {
  if (code == null) {
    return verified
        ? GuideEmailFollowUp.signedIn
        : GuideEmailFollowUp.needsVerification;
  }
  switch (code) {
    case 'user-not-found':
      return creating
          ? GuideEmailFollowUp.failed
          : GuideEmailFollowUp.tryCreate;
    case 'invalid-credential':
      return creating
          ? GuideEmailFollowUp.wrongPassword
          : GuideEmailFollowUp.tryCreate;
    case 'wrong-password':
    case 'ERROR_WRONG_PASSWORD':
    case 'email-already-in-use':
      return GuideEmailFollowUp.wrongPassword;
    case 'weak-password':
      return GuideEmailFollowUp.shortPassword;
    default:
      return GuideEmailFollowUp.failed;
  }
}

GuidePhoneFailure guidePhoneFailure(String code) {
  switch (code) {
    case 'invalid-phone-number':
    case 'invalidCredential':
      return GuidePhoneFailure.invalidNumber;
    case 'invalid-verification-code':
    case 'ERROR_INVALID_VERIFICATION_CODE':
      return GuidePhoneFailure.wrongCode;
    default:
      return GuidePhoneFailure.failed;
  }
}
