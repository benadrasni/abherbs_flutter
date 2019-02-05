import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/splash.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:screen/screen.dart';

void main() async {
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
  FirebaseMessaging _firebaseMessaging;
  FirebaseAnalytics _firebaseAnalytics;
  Map<String, dynamic> _notificationData;
  Future<Locale> _localeF;

  onChangeLanguage(String language) {
    setState(() {
      _localeF = Future<Locale>(() {
        return language == null || language.isEmpty ? null : Locale(language, '');
      });
    });
  }

  onBuyProduct() {
    setState(() {
      FlutterInappPurchase.getAvailablePurchases().then((value) {
        Purchases.purchases = value;
      });
    });
  }

  void _firebaseCloudMessagingListeners() {
    if (Platform.isIOS) _iOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print('token $token');
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
//        TODO: whether to show upcoming notification or not when app is active
//        setState(() {
//          _notification = message['data'];
//        });
      },
      onResume: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = message;
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = message;
        });
      },
    );
  }

  void _iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  void _iapError() {
    Fluttertoast.showToast(
        msg: 'IAP not prepared. Check if Platform service is available.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 5);
    Purchases.isAllowed = false;
    Purchases.purchases = <PurchasedItem>[];
  }

  void _initPlatformState() async {
    FlutterInappPurchase.initConnection.then((value) {
      FlutterInappPurchase.getAvailablePurchases().then((value) {
        Purchases.isAllowed = true;
        Purchases.purchases = value;
      }).catchError((error) {
        _iapError();
      });
    }).catchError((error) {
      _iapError();
    });
  }

  @override
  void initState() {
    super.initState();
    Ads.initialize();
    Prefs.init();
    _initPlatformState();

    _firebaseMessaging = FirebaseMessaging();
    _firebaseAnalytics = FirebaseAnalytics();
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

    _firebaseCloudMessagingListeners();
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
    return FutureBuilder<Locale>(
        future: _localeF,
        builder: (BuildContext context, AsyncSnapshot<Locale> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              Map<String, dynamic> notificationData = _notificationData != null ? Map.from(_notificationData) : null;
              _notificationData = null;
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: snapshot.data,
                localizationsDelegates: [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                home: Splash(this.onChangeLanguage, this.onBuyProduct, notificationData),
                navigatorObservers: [
                  FirebaseAnalyticsObserver(analytics: _firebaseAnalytics),
                ],
              );
            default:
              return Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Center(
                  child: Image(
                    image: AssetImage('res/images/home.png'),
                  ),
                ),
              );
          }
        });
  }
}
