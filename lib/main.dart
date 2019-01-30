import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  FirebaseMessaging _firebaseMessaging;
  Map<String, dynamic> _notificationData;
  Future<List<PurchasedItem>> _purchasesF;
  Future<Locale> _localeF;
  Future<Widget> _firstPageF;

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
//          _firstPageF = _findFirstPage();
//        });
      },
      onResume: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = message;
          _firstPageF = _findFirstPage();
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        setState(() {
          _notificationData = message;
          _firstPageF = _findFirstPage();
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

  Future<List<PurchasedItem>> _iapError() {
    Fluttertoast.showToast(
        msg: 'IAP not prepared. Check if Platform service is available.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 5
    );
    return Future<List<PurchasedItem>>(() {
      return <PurchasedItem>[];
    });
  }

  Future<List<PurchasedItem>> _initPlatformState() {
    return FlutterInappPurchase.initConnection.then((value) {
      return FlutterInappPurchase.getAvailablePurchases().catchError((error) {
        return _iapError();
      });
    }).catchError((error) {
      return _iapError();
    });
  }

  Future<Widget> _getFirstFilterPage() {
    return Prefs.getBoolF(keyAlwaysMyRegion, false).then((alwaysMyRegionValue) {
      Map<String, String> filter = {};
      if (alwaysMyRegionValue) {
        return Prefs.getStringF(keyMyRegion, null).then((myRegionValue) {
          if (myRegionValue != null) {
            filter[filterDistribution] = myRegionValue;
          }
          return Future<Widget>(() {
            return getFirstFilterPage(this.onChangeLanguage, this.onBuyProduct, filter);
          });
        });
      } else {
        return Future<Widget>(() {
          return getFirstFilterPage(this.onChangeLanguage, this.onBuyProduct, filter);
        });
      }
    });
  }

  Future<Widget> _findFirstPage() {
    if (_notificationData == null) {
      return _getFirstFilterPage();
    } else {
      String action = _notificationData['action'];
      if (action == null) {
        return _getFirstFilterPage();
      } else {
        switch (action) {
          case 'browse':
            String uri = _notificationData['uri'];
            if (uri != null) {
              launchURLF(uri);
              _notificationData = null;
              return _getFirstFilterPage();
            }
            return _getFirstFilterPage();
          case 'list':
            String count = _notificationData['count'];
            String path = _notificationData['path'];
            if (count != null && path != null) {
              return Future<Widget>(() {
                return PlantList(this.onChangeLanguage, this.onBuyProduct, {}, count, path);
              });
            }
            return _getFirstFilterPage();
          default:
            return _getFirstFilterPage();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Ads.initialize();
    Prefs.init();

    _firebaseMessaging = FirebaseMessaging();
    _purchasesF = _initPlatformState();
    _localeF = Prefs.getStringF(keyPreferredLanguage).then((String language) {
      return language.isEmpty ? null : Locale(language, '');
    });
    _firstPageF = _findFirstPage();

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
    return FutureBuilder<List<Object>>(
        future: Future.wait([_localeF, _purchasesF, _firstPageF]),
        builder: (BuildContext context, AsyncSnapshot<List<Object>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _notificationData = null;
              for (PurchasedItem product in snapshot.data[1]) {
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
                home: snapshot.data[2],
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
