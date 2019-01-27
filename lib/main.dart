import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/splash.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen/screen.dart';

class MainMerged {
  final Locale locale;
  final List<PurchasedItem> purchases;

  MainMerged({this.locale, this.purchases});
}

void main() async {
  bool isInDebugMode = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  await FlutterCrashlytics().initialize();

  runZoned<Future<Null>>(() async {
    Screen.keepOn(true);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(App());
    });
  }, onError: (error, stackTrace) async {
    await FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: false);
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Future<List<PurchasedItem>> _purchasesF;
  Future<Locale> _localeF;

  onChangeLanguage(String language) {
    setState(() {
      _localeF = new Future<Locale>(() {
        return language.isEmpty ? null : Locale(language, '');
      });
    });
  }

  onBuyProduct() {
    setState(() {
      _purchasesF = FlutterInappPurchase.getAvailablePurchases();
    });
  }

  Future<List<PurchasedItem>> initPlatformState() async {
    // prepare
    var result = await FlutterInappPurchase.initConnection;
    print('result: $result');

    return FlutterInappPurchase.getAvailablePurchases();
  }

  @override
  void initState() {
    super.initState();
    Ads.initialize();
    _purchasesF = initPlatformState();

    Prefs.init();
    Prefs.getStringF(keyPreferredLanguage).then((String language) {
      onChangeLanguage(language);
    });

    Prefs.getIntF(keyRateCount, rateCountInitial).then((value) {
      if (value < 0) {
        Prefs.getStringF(keyRateState, rateStateInitial).then((value) {
          if (value == rateStateInitial) {
            Prefs.setString(keyRateState, rateStateShould);
          }
        });
      } else {
        Prefs.setInt(keyRateCount, value - 1);
      }
    });
  }

  @override
  void dispose() async {
    Prefs.dispose();
    Ads.hideBannerAd();
    await FlutterInappPurchase.endConnection;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MainMerged>(
        future: Future.wait([_localeF, _purchasesF]).then((response) {
          return MainMerged(locale: response[0], purchases: response[1]);
        }),
        builder: (BuildContext context, AsyncSnapshot<MainMerged> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              for(PurchasedItem product in snapshot.data.purchases) {
                if (product.productId == productNoAdsAndroid || product.productId == productNoAdsIOS) {
                  Ads.isAllowed = false;
                  break;
                }
              }
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: snapshot.data.locale,
                localizationsDelegates: [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                home: Splash(this.onChangeLanguage, this.onBuyProduct),
              );
            default:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(),
                  CircularProgressIndicator(),
                  Container(),
                ],
              );
          }
        });
  }
}
