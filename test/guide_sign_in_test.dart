import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_sign_in.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/sign_in_page.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('email follow-up creates a missing account and keeps a wrong password',
      () {
    expect(guideEmailLooksValid('ada@example.com'), isTrue);
    expect(guideEmailLooksValid('ada'), isFalse);
    expect(
      guideEmailFollowUp(creating: false, code: null),
      GuideEmailFollowUp.signedIn,
    );
    expect(
      guideEmailFollowUp(creating: false, code: null, verified: false),
      GuideEmailFollowUp.needsVerification,
    );
    expect(
      guideEmailFollowUp(creating: false, code: 'user-not-found'),
      GuideEmailFollowUp.tryCreate,
    );
    expect(
      guideEmailFollowUp(creating: false, code: 'invalid-credential'),
      GuideEmailFollowUp.tryCreate,
    );
    expect(
      guideEmailFollowUp(creating: true, code: 'email-already-in-use'),
      GuideEmailFollowUp.wrongPassword,
    );
    expect(
      guideEmailFollowUp(creating: true, code: 'invalid-credential'),
      GuideEmailFollowUp.wrongPassword,
    );
    expect(
      guideEmailFollowUp(creating: false, code: 'wrong-password'),
      GuideEmailFollowUp.wrongPassword,
    );
    expect(
      guideEmailFollowUp(creating: true, code: 'weak-password'),
      GuideEmailFollowUp.shortPassword,
    );
    expect(
      guideEmailFollowUp(creating: true, code: 'user-not-found'),
      GuideEmailFollowUp.failed,
    );

    expect(guidePhoneNumber('421', '905 123 456'), '+421905123456');
    expect(guidePhoneNumber('+1', '(905)'), '+1905');
    expect(guidePhoneNumber('421', '   '), '');
    expect(
      guidePhoneFailure('invalid-phone-number'),
      GuidePhoneFailure.invalidNumber,
    );
    expect(
      guidePhoneFailure('invalid-verification-code'),
      GuidePhoneFailure.wrongCode,
    );
    expect(guidePhoneFailure('too-many-requests'), GuidePhoneFailure.failed);
  });

  testWidgets('shows what an account adds, then the four ways in',
      (tester) async {
    await _open(tester, _page());

    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.text('The key and the book stay free without an account.'),
      findsOneWidget,
    );
    expect(find.text('5 names from photos every month'), findsOneWidget);
    expect(find.text('instead of one'), findsOneWidget);
    expect(find.text('Seen follows you'), findsOneWidget);
    expect(find.text('to a new phone, with your first find'), findsOneWidget);
    expect(find.text('Share finds'), findsOneWidget);
    expect(find.text('as Sightings on the species page'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.byKey(const Key('plate')), findsOneWidget);
    expect(find.text('Find'), findsNothing);
  });

  testWidgets('apple is hidden when this phone cannot use it', (tester) async {
    await _open(tester, _page(showApple: false));

    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets(
      'dark mode uses the light Apple button and the dark Google button',
      (tester) async {
    await _open(
      tester,
      _page(appearance: GuideAppearance.dark),
    );

    final apple = _button(tester, 'Continue with Apple');
    expect(apple.color, const Color(0xFFFFFFFF));
    expect(_label(tester, 'Continue with Apple').style?.color,
        const Color(0xFF000000));

    final google = _button(tester, 'Continue with Google');
    expect(google.color, const Color(0xFF131314));
    expect((google.shape as StadiumBorder).side.color, const Color(0xFF8E918F));
    expect(_label(tester, 'Continue with Google').style?.color,
        const Color(0xFFE3E3E3));
  });

  testWidgets('light mode keeps Apple black and Google white', (tester) async {
    await _open(
      tester,
      _page(appearance: GuideAppearance.light),
    );

    expect(
        _button(tester, 'Continue with Apple').color, const Color(0xFF000000));
    expect(
      _button(tester, 'Continue with Google').color,
      const Color(0xFFFFFFFF),
    );
    expect(
      (_button(tester, 'Continue with Google').shape as StadiumBorder)
          .side
          .color,
      const Color(0xFF747775),
    );
  });

  testWidgets('closing returns to the page that opened it', (tester) async {
    await _open(tester, _page());

    await tester.tap(find.byTooltip('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('terms and privacy open their pages', (tester) async {
    final opened = <String>[];
    await _open(tester, _page(onOpenUrl: opened.add));

    await tester.ensureVisible(find.text('Terms of use'));
    await tester.tap(find.text('Terms of use'));
    await tester.pump();
    await tester.ensureVisible(find.text('Privacy policy'));
    await tester.tap(find.text('Privacy policy'));
    await tester.pump();

    expect(
      opened,
      [
        'https://storage.googleapis.com/abherbs-resources/misc/TermsOfServiceofWhatsthatflower.htm',
        'https://storage.googleapis.com/abherbs-resources/misc/PrivacyPolicyofWhatsthatflower.htm',
      ],
    );
  });

  testWidgets('apple and google sign in and close', (tester) async {
    var apple = 0;
    var google = 0;
    await _open(
      tester,
      _page(
        onApple: () async => apple++,
        onGoogle: () async => google++,
      ),
    );

    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();
    expect(apple, 1);
    expect(find.text('open'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(google, 1);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('email creates or signs in from one form', (tester) async {
    final attempts = <(String, String)>[];
    GuideEmailFollowUp follow = GuideEmailFollowUp.wrongPassword;
    await _open(
      tester,
      _page(
        onEmail: (email, password) async {
          attempts.add((email, password));
          return follow;
        },
      ),
    );

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(
      find.text('New here? The same form creates your account.'),
      findsOneWidget,
    );
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(attempts, isEmpty);

    await tester.enterText(
      find.byKey(const Key('guideSignInEmail')),
      'ada@example.com',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text("Password can't be empty"), findsOneWidget);

    await tester.enterText(find.byKey(const Key('guideSignInPassword')), 'no');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Use at least 6 characters.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('guideSignInPassword')),
      'secret',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(attempts, [('ada@example.com', 'secret')]);
    expect(
      find.text('That password doesn’t match. Reset it, or try another way.'),
      findsOneWidget,
    );

    follow = GuideEmailFollowUp.signedIn;
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(attempts, [
      ('ada@example.com', 'secret'),
      ('ada@example.com', 'secret'),
    ]);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('email, password, and phone boxes fill the form', (tester) async {
    await _open(tester, _page(initialCountry: Country.parse('SK')));

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    final email = tester.getSize(find.byKey(const Key('guideSignInEmail')));
    final password =
        tester.getSize(find.byKey(const Key('guideSignInPassword')));
    final button = tester.getSize(
      find
          .ancestor(
            of: find.text('Continue'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(email.height, 48);
    expect(password.height, 48);
    expect(email.width, button.width);
    expect(password.width, button.width);
    final emailField =
        tester.widget<TextField>(find.byKey(const Key('guideSignInEmail')));
    expect(emailField.decoration?.isDense, isFalse);
    var outline = 0.0;
    for (final element in find
        .descendant(
          of: find.byKey(const Key('guideSignInEmail')),
          matching: find.byType(CustomPaint),
        )
        .evaluate()) {
      final box = element.renderObject;
      if (box is RenderBox && box.hasSize && box.size.height > outline) {
        outline = box.size.height;
      }
    }
    expect(outline, 48);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    final phone = tester.getSize(find.byKey(const Key('guideSignInPhone')));
    final code = tester.getSize(find.byKey(const Key('guideSignInCallingCode')));
    final send = tester.getSize(
      find
          .ancestor(
            of: find.text('Send code'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(phone.height, 48);
    expect(code.height, 48);
    expect(phone.width + code.width + 8, send.width);
  });

  testWidgets('a new email asks the person to verify, and stays here',
      (tester) async {
    await _open(
      tester,
      _page(
        onEmail: (email, password) async =>
            GuideEmailFollowUp.needsVerification,
      ),
    );

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('guideSignInEmail')),
      'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('guideSignInPassword')),
      'secret',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your account'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with email'), findsOneWidget);
  });

  testWidgets('forgot password sends a reset for the address on the form',
      (tester) async {
    final sent = <String>[];
    await _open(
      tester,
      _page(onResetPassword: (email) async => sent.add(email)),
    );

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(sent, isEmpty);

    await tester.enterText(
      find.byKey(const Key('guideSignInEmail')),
      'ada@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(sent, ['ada@example.com']);
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.textContaining('ada@example.com'), findsWidgets);
  });

  testWidgets('phone sends a code, then signs in with it', (tester) async {
    final sent = <String>[];
    final codes = <String>[];
    await _open(
      tester,
      _page(
        initialCountry: Country.parse('SK'),
        onSendCode: (phone) async => sent.add(phone),
        onConfirmCode: (code) async => codes.add(code),
      ),
    );

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with phone'), findsOneWidget);
    expect(find.text('We send a six-digit code by SMS.'), findsOneWidget);
    expect(find.text('+421'), findsOneWidget);

    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(sent, isEmpty);

    await tester.enterText(
      find.byKey(const Key('guideSignInPhone')),
      '905 123 456',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(sent, ['+421905123456']);
    expect(
      find.text('Enter the six-digit code we sent to +421905123456.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter a valid SMS code'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('guideSignInCode')), '123456');
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    expect(sent, ['+421905123456', '+421905123456']);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(codes, ['123456']);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets(
      'back from a form returns to the providers, and the system back does too',
      (tester) async {
    await _open(tester, _page());

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Apple'), findsOneWidget);
  });
}

GuideSignInPage _page({
  bool showApple = true,
  GuideAppearance? appearance,
  Country? initialCountry,
  Future<void> Function()? onApple,
  Future<void> Function()? onGoogle,
  Future<GuideEmailFollowUp> Function(String email, String password)? onEmail,
  Future<void> Function(String email)? onResetPassword,
  Future<void> Function(String phone)? onSendCode,
  Future<void> Function(String code)? onConfirmCode,
  void Function(String url)? onOpenUrl,
}) {
  return GuideSignInPage(
    showApple: showApple,
    appearance: appearance,
    initialCountry: initialCountry,
    plate: (_) => const ColoredBox(
      key: Key('plate'),
      color: Color(0xFFEFE6D3),
    ),
    onApple: onApple,
    onGoogle: onGoogle,
    onEmail: onEmail ?? ((email, password) async => GuideEmailFollowUp.failed),
    onResetPassword: onResetPassword,
    onSendCode: onSendCode,
    onConfirmCode: onConfirmCode,
    onOpenUrl: onOpenUrl,
  );
}

Material _button(WidgetTester tester, String label) {
  return tester.widget<Material>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(Material),
        )
        .first,
  );
}

Text _label(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label));
}

Future<void> _open(WidgetTester tester, GuideSignInPage page) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => page),
                );
              },
              child: const Text('open'),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
