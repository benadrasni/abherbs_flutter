import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/flutter_localized_countries.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/settings/settings_remote.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wakelock/wakelock.dart';

import 'detail/plant_detail.dart';
import 'entity/plant.dart';
import 'filter/color.dart';
import 'filter/distribution.dart';
import 'filter/filter_utils.dart';
import 'filter/habitat.dart';
import 'filter/petal.dart';

void _iapError() {
  Fluttertoast.showToast(
      msg: 'IAP not prepared. Check if Platform service is available.', toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.BOTTOM, timeInSecForIosWeb: 5, backgroundColor: Colors.redAccent);
}

Future<void> initializeFlutterFire() async {
  // Wait for Firebase to initialize
  await Firebase.initializeApp();
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(firebaseCacheSize);

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!isInDebugMode);

  await RemoteConfiguration.setupRemoteConfig();

  // Pass all uncaught errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
}

Future<Locale> initializeLocale() async {
  return Prefs.getStringF(keyPreferredLanguage).then((String language) {
    var languageCountry = language.split('_');
    return languageCountry.length < 2 ? null : Locale(languageCountry[0], languageCountry[1]);
  });
}

Future<Map<String, String>> initializeFilter() async {
  return Prefs.getBoolF(keyAlwaysMyRegion, false).then((alwaysMyRegionValue) {
    Map<String, String> filter = {};
    if (alwaysMyRegionValue) {
      return Prefs.getStringF(keyMyRegion, null).then((myRegionValue) {
        if (myRegionValue != null) {
          filter[filterDistribution] = myRegionValue;
        }
        return filter;
      });
    }
    return filter;
  });
}

Future<String> initializeRoute() {
  return Prefs.getStringListF(keyMyFilter, filterAttributes).then((myFilter) {
    String initialRoute = '/' + filterColor;
    Preferences.myFilterAttributes = myFilter;
    if (myFilter != null && myFilter.length > 0) {
      initialRoute = '/' + myFilter[0];
    }
    return initialRoute;
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    initializeFlutterFire().then((_) async {
      Wakelock.enable();
      await Prefs.init();
      await AppTrackingTransparency.requestTrackingAuthorization();
      MobileAds.instance.initialize();
      Locale locale = await initializeLocale();
      Map<String, String> filter = await initializeFilter();
      String initialRoute = await initializeRoute();
      runApp(App(locale, filter, initialRoute));
    }).catchError((error) {
      print('FlutterFire: Caught error in FlutterFire initialization.');
      FirebaseCrashlytics.instance.recordError(error, null);
    });
  }, (error, stackTrace) {
    print('runZonedGuarded: Caught error in my root zone.');
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });
}

class App extends StatefulWidget {
  static BuildContext currentContext;
  final Locale locale;
  final Map<String, String> filter;
  final String initialRoute;
  App(this.locale, this.filter, this.initialRoute);

  static void setLocale(BuildContext context, String language) async {
    _AppState state = context.findAncestorStateOfType<_AppState>();
    state.changeLanguage(language);
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>> _subscription;
  Locale _locale;

  Future<void> _logFailedPurchaseEvent() async {
    await _firebaseAnalytics.logEvent(name: 'purchase_failed');
  }

  changeLanguage(String language) {
    var languageCountry = language?.split('_');
    setState(() {
      translationCache = {};
      _locale = language == null || language.isEmpty ? null : Locale(languageCountry[0], languageCountry[1]);
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.restored) {
        Purchases.purchases[purchaseDetails.productID] = purchaseDetails;
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        if (mounted && (purchaseDetails.productID == productNoAdsAndroid || purchaseDetails.productID == productNoAdsIOS)) {
          setState(() {});
        }
      }
    });
  }

  Future<dynamic> handleMessage(RemoteMessage message) {
    if (message != null) {
      String action = message.data[notificationAttributeAction];
      if (action != null && App.currentContext != null) {
        switch (action) {
          case notificationAttributeActionList:
            String path = message.data[notificationAttributePath];
            rootReference.child(path).keepSynced(true);
            return showDialog(
              context: App.currentContext,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S
                      .of(context)
                      .notification),
                  content: Text(message.notification.title != null ? message.notification.title : message.notification.body),
                  actions: <Widget>[
                    TextButton(
                      child: Text(S
                          .of(context)
                          .notification_open,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          )),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PlantList({}, '', rootReference.child(path)), settings: RouteSettings(name: 'PlantList')));
                      },
                    ),
                    TextButton(
                      child: Text(S
                          .of(context)
                          .notification_close,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          )),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          case notificationAttributeActionPlant:
            String name = message.data[notificationAttributeName];
            return showDialog(
              context: App.currentContext,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(S
                      .of(context)
                      .notification),
                  content: Text(message.notification.title != null ? message.notification.title : message.notification.body),
                  actions: <Widget>[
                    TextButton(
                      child: Text(S
                          .of(context)
                          .notification_open,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          )),
                      onPressed: () {
                        Navigator.of(context).pop();
                        goToDetail(this, context, Localizations.localeOf(context), name, widget.filter);
                      },
                    ),
                    TextButton(
                      child: Text(S
                          .of(context)
                          .notification_close,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          )),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
        }
      } else {
        return Future<dynamic>(() {
          return null;
        });
      }
    }

    return Future<dynamic>(() {
      return null;
    });
  }

  void _firebaseCloudMessagingListeners() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    FirebaseMessaging.instance.getToken().then((token) {
      Prefs.setString(keyToken, token);
      print('token $token');
    }).onError((error, stackTrace) => null);

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage message) async {
      if (message != null) {
        MaterialPageRoute<dynamic> redirect = await findRedirectF(message.data);
        if (redirect != null) {
          Navigator.push(App.currentContext, redirect);
        }
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      handleMessage(message);
    });
  }

  Future<MaterialPageRoute<dynamic>> findRedirectF(Map<String, dynamic> notificationData) {
    if (notificationData == null) {
      return Future<MaterialPageRoute<dynamic>>(() {
        return null;
      });
    } else {
      String action = notificationData[notificationAttributeAction];
      if (action == null) {
        return Future<MaterialPageRoute<dynamic>>(() {
          return null;
        });
      } else {
        switch (action) {
          case notificationAttributeActionBrowse:
            String uri = notificationData[notificationAttributeUri];
            if (uri != null) {
              launchURLF(uri);
              return Future<MaterialPageRoute<dynamic>>(() {
                return null;
              });
            }
            return Future<MaterialPageRoute<dynamic>>(() {
              return null;
            });
          case notificationAttributeActionList:
            String path = notificationData[notificationAttributePath];
            if (path != null) {
              rootReference.child(path).keepSynced(true);
              rootReference.child(firebasePlantHeaders).keepSynced(true);
              return rootReference.child(path).once().then((event) {
                var result = event.snapshot.value ?? [];
                int length = result is List ? result.fold(0, (t, value) => t + (value == null ? 0 : 1)) : (result as Map).values.length;
                if (length == 0) {
                  rootReference.child(path).child("refreshMock").set("mock").catchError((error) {
                    FirebaseCrashlytics.instance.log("0-length custom list");
                  });
                }
                return Future<MaterialPageRoute<dynamic>>(() {
                  return MaterialPageRoute(builder: (context) => PlantList({}, '', rootReference.child(path)), settings: RouteSettings(name: 'PlantList'));
                });
              });
            }
            return Future<MaterialPageRoute<dynamic>>(() {
              return null;
            });
          case notificationAttributeActionPlant:
            String name = notificationData[notificationAttributeName];
            if (name != null) {
              rootReference.child(firebasePlants).keepSynced(true);
              return plantsReference.child(name).once().then((event) {
                if (event.snapshot.value != null && (event.snapshot.value as Map)['id'] != null) {
                  Plant plant = Plant.fromJson(event.snapshot.key, event.snapshot.value);
                  return Future<MaterialPageRoute<dynamic>>(() {
                    return MaterialPageRoute(builder: (context) => PlantDetail(Localizations.localeOf(context), Map<String, String>(), plant), settings: RouteSettings(name: 'PlantDetail'));
                  });
                }
                return Future<MaterialPageRoute<dynamic>>(() {
                  return null;
                });
              });
            }
            return Future<MaterialPageRoute<dynamic>>(() {
              return null;
            });
          default:
            return Future<MaterialPageRoute<dynamic>>(() {
              return null;
            });
        }
      }
    }
  }

  Locale localeResolution(Locale savedLocale, Locale deviceLocale, Iterable<Locale> supportedLocales) {
    if (savedLocale != null) {
      return savedLocale;
    }

    Locale resultLocale;
    Map<String, Locale> defaultLocale = {};
    for (Locale locale in supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode && locale.countryCode != null && locale.countryCode == deviceLocale.countryCode) {
        resultLocale = locale;
        break;
      }

      if (locale.languageCode != languageEnglish || locale.countryCode == 'US') {
        defaultLocale[locale.languageCode] = locale;
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

    Prefs.setStringList(keyLanguageAndCountry, [resultLocale.languageCode, resultLocale.countryCode]);
    return resultLocale;
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _iapError();
      Purchases.purchases = {};
      setState(() {});
    } else {
      _inAppPurchase.restorePurchases();
    }
    Purchases.hasOldVersion = Prefs.getBool(keyOldVersion, false);
    Purchases.hasLifetimeSubscription = Prefs.getBool(keyLifetimeSubscription, false);
    Auth.setUser();
    Offline.initialize();
  }

  @override
  void initState() {
    super.initState();

    _firebaseCloudMessagingListeners();
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      _logFailedPurchaseEvent();
      if (mounted) {
        Fluttertoast.showToast(msg: S.of(context).product_purchase_failed, toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.BOTTOM, timeInSecForIosWeb: 5);
      }
    });
    initStoreInfo();

    _locale = widget.locale;

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
  }

  @override
  void dispose() {
    Prefs.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Locale deviceLocale;
    List<String> localeHelper = Platform.localeName?.split("_");
    if (localeHelper != null) {
      deviceLocale = Locale(localeHelper[0], localeHelper.length > 1 ? localeHelper[1] : null);
    }
    return MaterialApp(
      locale: localeResolution(_locale, deviceLocale, S.delegate.supportedLocales),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        CountryNamesLocalizationsDelegate(),
        CountryLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      initialRoute: widget.initialRoute,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: _firebaseAnalytics),
      ],
      routes: {
        '/filterColor': (context) => Color(widget.filter),
        '/filterHabitat': (context) => Habitat(widget.filter),
        '/filterPetal': (context) => Petal(widget.filter),
        '/filterDistribution': (context) => Distribution(widget.filter),
      },
    );
  }
}
