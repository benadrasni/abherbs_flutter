import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/splash.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_database/firebase_database.dart';
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
  Future<void> _initializationF;

  onChangeLanguage(String language) {
    setState(() {
      translationCache = {};
      _localeF = Future<Locale>(() {
        var languageCountry = language?.split('_');
        return language == null || language.isEmpty ? null : Locale(languageCountry[0], languageCountry[1]);
      });
    });
  }

  onBuyProduct(PurchasedItem purchased) {
    setState(() {
      Purchases.purchases.add(purchased);
      Prefs.setStringList(keyPurchases, Purchases.purchases.map((item) => item.productId).toList());
    });
  }

  void _firebaseCloudMessagingListeners() {
    if (Platform.isIOS) _iOSPermission();

    _firebaseMessaging.getToken().then((token) {
      Prefs.setString(keyToken, token);
      print('token $token');
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print(message);
      },
      onResume: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = Map.from(message[notificationAttributeData]);
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = Map.from(Platform.isIOS ? message : message[notificationAttributeData]);
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
    Purchases.purchases = <PurchasedItem>[];
  }

  void _checkPromotions() {
    rootReference.child(firebasePromotions).once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        if (snapshot.value[firebaseAttributeObservations] != null) {
          var observationsFrom = DateTime.parse(snapshot.value[firebaseAttributeObservations][firebaseAttributeFrom]);
          var observationsTo = DateTime.parse(snapshot.value[firebaseAttributeObservations][firebaseAttributeTo]);

          var currentDate = DateTime.now();
          Purchases.observationPromotionFrom = observationsFrom;
          Purchases.observationPromotionTo = observationsTo;
          Purchases.isObservationPromotion = currentDate.isAfter(observationsFrom) && currentDate.isBefore(observationsTo.add(Duration(days: 1)));
        }
        if (snapshot.value[firebaseAttributeSearch] != null) {
          var searchFrom = DateTime.parse(snapshot.value[firebaseAttributeSearch][firebaseAttributeFrom]);
          var searchTo = DateTime.parse(snapshot.value[firebaseAttributeSearch][firebaseAttributeTo]);

          var currentDate = DateTime.now();
          Purchases.searchPromotionFrom = searchFrom;
          Purchases.searchPromotionTo = searchTo;
          Purchases.isSearchPromotion = currentDate.isAfter(searchFrom) && currentDate.isBefore(searchTo.add(Duration(days: 1)));
        }
        if (snapshot.value[firebaseAttributeSearchByPhoto] != null) {
          var searchByPhotoFrom = DateTime.parse(snapshot.value[firebaseAttributeSearchByPhoto][firebaseAttributeFrom]);
          var searchByPhotoTo = DateTime.parse(snapshot.value[firebaseAttributeSearchByPhoto][firebaseAttributeTo]);

          var currentDate = DateTime.now();
          Purchases.searchByPhotoPromotionFrom = searchByPhotoFrom;
          Purchases.searchByPhotoPromotionTo = searchByPhotoTo;
          Purchases.isSearchByPhotoPromotion = currentDate.isAfter(searchByPhotoFrom) && currentDate.isBefore(searchByPhotoTo.add(Duration(days: 1)));
        }
      }
    });
  }

  Future<void> _initPlatformState() async {
    await FlutterInappPurchase.initConnection.then((value) async {
      // TODO check for a fix: when iOS is offline it doesn't return purchased products
      if (Platform.isIOS) {
        await Prefs.getStringListF(keyPurchases, []).then((products) {
          Purchases.purchases = products.map((productId) => Purchases.offlineProducts[productId]).toList();
          Offline.initialize();
          _checkPromotions();
        });
      } else if (Platform.isAndroid) {
        await FlutterInappPurchase.getAvailablePurchases().then((value) async {
          Purchases.purchases = value;
          Prefs.setStringList(keyPurchases, Purchases.purchases.map((item) => item.productId).toList());
          Offline.initialize();
          _checkPromotions();
        }).catchError((error) {
          _iapError();
        });
      } else {
        throw PlatformException(code: Platform.operatingSystem, message: "platform not supported");
      }
    }).catchError((error) {
      _iapError();
    });
  }

  @override
  void initState() {
    super.initState();
    Ads.initialize();
    Prefs.init();
    _initializationF = _initPlatformState();

    _firebaseMessaging = FirebaseMessaging();
    _firebaseAnalytics = FirebaseAnalytics();

    _localeF = Prefs.getStringF(keyPreferredLanguage).then((String language) {
      var languageCountry = language.split('_');
      return languageCountry.length < 2 ? null : Locale(languageCountry[0], languageCountry[1]);
    });

    Prefs.getStringF(keyRateCount, rateCountInitial.toString()).then((value) {
      if (int.parse(value) < 0) {
        Prefs.getStringF(keyRateState, rateStateInitial).then((value) {
          if (value == rateStateInitial) {
            Prefs.setString(keyRateState, rateStateShould);
          }
        });
      } else {
        Prefs.setString(keyRateCount, (int.parse(value) - 1).toString());
      }
    }).catchError((_) {
      // deal with previous int shared preferences
      Prefs.setString(keyRateCount, rateCountInitial.toString());
    });

    _firebaseCloudMessagingListeners();
  }

  Locale _localeResolutionCallback(Locale locale, Locale deviceLocale, Iterable<Locale> supportedLocales) {
    Locale resultLocale = locale;
    if (resultLocale == null) {
      Map<String, Locale> defaultLocale = {};
      for (Locale locale in supportedLocales) {
        if ((locale.languageCode == 'en' && locale.countryCode == 'US')
          || (locale.languageCode == 'ar' && locale.countryCode == 'EG')
          || (locale.languageCode == 'de' && locale.countryCode == 'DE')
          || (locale.languageCode == 'es' && locale.countryCode == 'ES')
          || (locale.languageCode == 'fr' && locale.countryCode == 'FR')
          || (locale.languageCode == 'pt' && locale.countryCode == 'PT')
          || (locale.languageCode == 'it' && locale.countryCode == 'IT')
          || (locale.languageCode == 'ru' && locale.countryCode == 'RU')
          || (locale.languageCode == 'sr' && locale.countryCode == 'RS')
          ) {
          defaultLocale[locale.languageCode] = locale;
        } else if (!['en', 'ar', 'de', 'es', 'fr', 'pt', 'it', 'ru', 'sr'].contains(locale.languageCode)) {
          defaultLocale[locale.languageCode] = locale;
        }

        if (locale.languageCode == deviceLocale.languageCode && locale.countryCode == deviceLocale.countryCode) {
          resultLocale = locale;
          break;
        }
      }
      if (resultLocale == null) {
        for (Locale locale in supportedLocales) {
          if (locale.languageCode == deviceLocale.languageCode) {
            resultLocale = defaultLocale[locale.languageCode];
            break;
          }
        }
      }
      if (resultLocale == null) {
        resultLocale = defaultLocale[languageEnglish];
      }
    }
    Prefs.setStringList(keyLanguageAndCountry, [resultLocale.languageCode, resultLocale.countryCode]);
    return resultLocale;
  }

  @override
  void dispose() {
    Prefs.dispose();
    Ads.hideBannerAd();
    FlutterInappPurchase.endConnection;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
        future: Future.wait([_localeF, _initializationF, Auth.getCurrentUser()]),
        builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              Map<String, dynamic> notificationData = _notificationData != null ? Map.from(_notificationData) : null;
              _notificationData = null;
              return MaterialApp(
                localeResolutionCallback: (deviceLocale, supportedLocales) {
                  return _localeResolutionCallback(snapshot.data[0], deviceLocale, supportedLocales);
                },
                debugShowCheckedModeBanner: false,
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
