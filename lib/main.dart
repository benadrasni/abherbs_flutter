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
      _localeF = Future<Locale>(() {
        return language.isEmpty ? null : Locale(language, '');
      });
    });
  }

  onBuyProduct() {
    setState(() {
      _purchasesF = FlutterInappPurchase.getAvailablePurchases();
    });
  }

  Future<List<PurchasedItem>> initPlatformState() {
    return FlutterInappPurchase.initConnection.then((value) {
      return FlutterInappPurchase.getAvailablePurchases().catchError((error) {
        print(error);
        return Future<List<PurchasedItem>>(() {
          return <PurchasedItem>[];
        });
      });
    }).catchError((error) {
      print(error);
      return Future<List<PurchasedItem>>(() {
        return <PurchasedItem>[];
      });
    });
  }

  @override
  void initState() {
    super.initState();
    Ads.initialize();
    Prefs.init();
    _purchasesF = initPlatformState();
    _localeF = Prefs.getStringF(keyPreferredLanguage).then((String language) {
      return language.isEmpty ? null : Locale(language, '');
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
    return FutureBuilder<List<Object>>(
        future: Future.wait([_localeF, _purchasesF]),
        builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              for(PurchasedItem product in snapshot.data[1]) {
                if (product.productId == productNoAdsAndroid || product.productId == productNoAdsIOS) {
                  Ads.isAllowed = false;
                  break;
                }
              }
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: snapshot.data[0],
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
