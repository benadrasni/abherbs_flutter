import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/observation_scope_switch.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: home),
  );
}

void main() {
  testWidgets('starts on my observations and switches to shared', (tester) async {
    var isPublic = false;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) {
        return ObservationScopeSwitch(
          isPublic: isPublic,
          onChanged: (value) => setState(() => isPublic = value),
        );
      },
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);

    final button = tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>));
    expect(button.selected, {false});

    await tester.tap(find.byIcon(Icons.people));
    await tester.pumpAndSettle();
    expect(isPublic, isTrue);
    expect(
      tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>)).selected,
      {true},
    );

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(isPublic, isFalse);
  });

  test('notification browse action still matches the FCM payload', () {
    expect(notificationAttributeActionBrowse, 'browse');
    expect(notificationAttributeUri, 'uri');
    expect(notificationAttributeActionPlant, 'plant');
    expect(notificationAttributeActionList, 'list');
  });
}
