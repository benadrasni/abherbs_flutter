import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/filter/color_of_flower.dart';

void main() async => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Future<Locale> _locale;

  onChangeLanguage(String language) {
    setState(() {
      _locale = new Future<Locale>(() {
        return language == null ? null : Locale(language, '');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    Prefs.init();
    Prefs.getStringF('pref_language').then((String language) {
      onChangeLanguage(language);
    });
  }

  @override
  void dispose() {
    Prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Locale>(
        future: _locale,
        builder: (BuildContext context, AsyncSnapshot<Locale> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const CircularProgressIndicator();
            default:
              return MaterialApp(
                  locale: snapshot.data,
                  localizationsDelegates: [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate,],
                  supportedLocales: S.delegate.supportedLocales,
                  localeResolutionCallback: S.delegate.resolution(fallback: new Locale("en", "")),
                  home: ColorOfFlower(this.onChangeLanguage, new Map<String, String>()));
          }
        }
    );
  }
}
