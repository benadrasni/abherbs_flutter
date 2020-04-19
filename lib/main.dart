import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/splash.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen/screen.dart';

import 'ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  InAppPurchaseConnection.enablePendingPurchases();
  FlutterCrashlytics().initialize();
  Ads.initialize();

  runZoned<Future<Null>>(() async {
    Screen.keepOn(true);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .then((_) {
      runApp(App());
    });
  }, onError: (error, stackTrace) async {
    await FlutterCrashlytics()
        .reportCrash(error, stackTrace, forceCrash: false);
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();

  StreamSubscription<List<PurchaseDetails>> _subscription;
  Map<String, dynamic> _notificationData;
  Future<Locale> _localeF;
  Future<void> _initStoreF;

  Future<void> _logFailedPurchaseEvent() async {
    await _firebaseAnalytics.logEvent(name: 'purchase_failed');
  }

  onChangeLanguage(String language) {
    setState(() {
      translationCache = {};
      _localeF = Future<Locale>(() {
        var languageCountry = language?.split('_');
        return language == null || language.isEmpty
            ? null
            : Locale(languageCountry[0], languageCountry[1]);
      });
    });
  }

  _listenToPurchaseUpdated(List<PurchaseDetails> purchases) {
    var isPurchase = false;
    for (PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        final pending = Platform.isIOS
            ? purchase.pendingCompletePurchase
            : !purchase.billingClientPurchase.isAcknowledged;
        if (pending) {
          InAppPurchaseConnection.instance.completePurchase(purchase);
        }
        Purchases.purchases.add(purchase);
        isPurchase = true;
      }
    }
    if (isPurchase) {
      Prefs.setStringList(keyPurchases,
          Purchases.purchases.map((item) => item.productID).toList());
      setState(() {});
    }
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
          _notificationData = Map.from(
              Platform.isIOS ? message : message[notificationAttributeData]);
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = Map.from(
              Platform.isIOS ? message : message[notificationAttributeData]);
        });
      },
    );
  }

  void _iOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  void _iapError() {
    Fluttertoast.showToast(
        msg: 'IAP not prepared. Check if Platform service is available.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5);
    Purchases.purchases = [];
  }

  void _checkPromotions() {
    rootReference
        .child(firebasePromotions)
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        if (snapshot.value[firebaseAttributeObservations] != null) {
          var observationsFrom = DateTime.parse(snapshot
              .value[firebaseAttributeObservations][firebaseAttributeFrom]);
          var observationsTo = DateTime.parse(snapshot
              .value[firebaseAttributeObservations][firebaseAttributeTo]);

          var currentDate = DateTime.now();
          Purchases.observationPromotionFrom = observationsFrom;
          Purchases.observationPromotionTo = observationsTo;
          Purchases.isObservationPromotion =
              currentDate.isAfter(observationsFrom) &&
                  currentDate.isBefore(observationsTo.add(Duration(days: 1)));
        }
        if (snapshot.value[firebaseAttributeSearch] != null) {
          var searchFrom = DateTime.parse(
              snapshot.value[firebaseAttributeSearch][firebaseAttributeFrom]);
          var searchTo = DateTime.parse(
              snapshot.value[firebaseAttributeSearch][firebaseAttributeTo]);

          var currentDate = DateTime.now();
          Purchases.searchPromotionFrom = searchFrom;
          Purchases.searchPromotionTo = searchTo;
          Purchases.isSearchPromotion = currentDate.isAfter(searchFrom) &&
              currentDate.isBefore(searchTo.add(Duration(days: 1)));
        }
        if (snapshot.value[firebaseAttributeSearchByPhoto] != null) {
          var searchByPhotoFrom = DateTime.parse(snapshot
              .value[firebaseAttributeSearchByPhoto][firebaseAttributeFrom]);
          var searchByPhotoTo = DateTime.parse(snapshot
              .value[firebaseAttributeSearchByPhoto][firebaseAttributeTo]);

          var currentDate = DateTime.now();
          Purchases.searchByPhotoPromotionFrom = searchByPhotoFrom;
          Purchases.searchByPhotoPromotionTo = searchByPhotoTo;
          Purchases.isSearchByPhotoPromotion =
              currentDate.isAfter(searchByPhotoFrom) &&
                  currentDate.isBefore(searchByPhotoTo.add(Duration(days: 1)));
        }
      }
    });
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await InAppPurchaseConnection.instance.isAvailable();
    if (!isAvailable) {
      _iapError();
    }

    final QueryPurchaseDetailsResponse purchaseResponse =
        await InAppPurchaseConnection.instance.queryPastPurchases();
    if (purchaseResponse.error != null) {
      var purchases = await Prefs.getStringListF(keyPurchases, []);
      Purchases.purchases = purchases
          .map((productId) => Purchases.offlineProducts[productId])
          .toList();
    } else {
      Purchases.purchases = [];
      for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
        if (await verifyPurchase(purchase)) {

          final pending = Platform.isIOS
              ? purchase.pendingCompletePurchase
              : !purchase.billingClientPurchase.isAcknowledged;

          if (pending) {
            await InAppPurchaseConnection.instance.completePurchase(purchase);
          }
          Purchases.purchases.add(purchase);
        }
      }
      Prefs.setStringList(keyPurchases,
          Purchases.purchases.map((item) => item.productID).toList());
    }

    Offline.initialize();
    _checkPromotions();
    await Auth.getCurrentUser();
  }

  @override
  void initState() {
    super.initState();
    Prefs.init();
    Stream purchaseUpdated = InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      _logFailedPurchaseEvent();
      if (mounted) {
        Fluttertoast.showToast(
            msg: S.of(context).product_purchase_failed,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 5);
      }
    });
    _initStoreF = initStoreInfo();

    _localeF = Prefs.getStringF(keyPreferredLanguage).then((String language) {
      var languageCountry = language.split('_');
      return languageCountry.length < 2
          ? null
          : Locale(languageCountry[0], languageCountry[1]);
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

  Locale _localeResolutionCallback(
      Locale locale, Locale deviceLocale, Iterable<Locale> supportedLocales) {
    Locale resultLocale = locale;
    if (resultLocale == null) {
      Map<String, Locale> defaultLocale = {};
      for (Locale locale in supportedLocales) {
        if ((locale.languageCode == 'en' && locale.countryCode == 'US') ||
            (locale.languageCode == 'ar' && locale.countryCode == 'EG') ||
            (locale.languageCode == 'de' && locale.countryCode == 'DE') ||
            (locale.languageCode == 'es' && locale.countryCode == 'ES') ||
            (locale.languageCode == 'fr' && locale.countryCode == 'FR') ||
            (locale.languageCode == 'pt' && locale.countryCode == 'PT') ||
            (locale.languageCode == 'it' && locale.countryCode == 'IT') ||
            (locale.languageCode == 'ru' && locale.countryCode == 'RU') ||
            (locale.languageCode == 'sr' && locale.countryCode == 'RS')) {
          defaultLocale[locale.languageCode] = locale;
        } else if (!['en', 'ar', 'de', 'es', 'fr', 'pt', 'it', 'ru', 'sr']
            .contains(locale.languageCode)) {
          defaultLocale[locale.languageCode] = locale;
        }

        if (locale.languageCode == deviceLocale.languageCode &&
            locale.countryCode == deviceLocale.countryCode) {
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
    Prefs.setStringList(keyLanguageAndCountry,
        [resultLocale.languageCode, resultLocale.countryCode]);
    return resultLocale;
  }

  @override
  void dispose() {
    Prefs.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
        future: Future.wait([_localeF, _initStoreF]),
        builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                FlutterCrashlytics().log(snapshot.error.toString());
              }
              Map<String, dynamic> notificationData = _notificationData != null
                  ? Map.from(_notificationData)
                  : null;
              _notificationData = null;
              return MaterialApp(
                localeResolutionCallback: (deviceLocale, supportedLocales) {
                  return _localeResolutionCallback(
                      snapshot.data == null ? null : snapshot.data[0], deviceLocale, supportedLocales);
                },
                debugShowCheckedModeBanner: false,
                localizationsDelegates: [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                home: Splash(this.onChangeLanguage, notificationData),
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
