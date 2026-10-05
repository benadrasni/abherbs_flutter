import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/shell/guide_actions.dart';
import 'package:abherbs_flutter/shell/guide_shell.dart';
import 'package:abherbs_flutter/book/list_page.dart';
import 'package:abherbs_flutter/species/species_page.dart';
import 'package:abherbs_flutter/purchase/owned_purchases.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/offline/offline.dart';
import 'package:abherbs_flutter/shell/app_version.dart';
import 'package:abherbs_flutter/shell/app_version_check.dart';
import 'package:abherbs_flutter/shell/settings_remote.dart';
import 'package:abherbs_flutter/shell/version_gate.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/shell/dialogs.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/shell/safe_focus_traversal.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'firebase_options.dart';

void _iapError() {
  Fluttertoast.showToast(
      msg: 'IAP not prepared. Check if Platform service is available.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.redAccent);
}

Future<void> initializeFlutterFire() async {
  // Wait for Firebase to initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    providerAndroid: isInDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: isInDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(firebaseCacheSize);

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!isInDebugMode);

  await RemoteConfiguration.setupRemoteConfig();

  FlutterError.onError = (details) {
    if (isIgnorableFlutterError(details)) {
      return;
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (isIgnorableNonFatalError(error)) {
      return true;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

String? notificationTitle(RemoteMessage message) {
  return message.notification?.title ?? message.data['title'];
}

String? notificationBody(RemoteMessage message) {
  return message.notification?.body ?? message.data['body'];
}

Locale getDeviceLocale() {
  // device locale could be "en", "en_US" or "en_US.UTF-8"
  List<String> localeHelper = Platform.localeName.split(".")[0].split("_");
  if (localeHelper.length > 1) {
    return Locale(localeHelper[0], localeHelper[1]);
  } else {
    return Locale(localeHelper[0]);
  }
}

Future<Locale> initializeLocale() async {
  return Prefs.getStringF(keyPreferredLanguage).then((String language) {
    var languageCountry = language.split('_');
    if (languageCountry.length < 2) {
      return getDeviceLocale();
    } else {
      return Locale(languageCountry[0], languageCountry[1]);
    }
  });
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    initializeFlutterFire().then((_) async {
      WakelockPlus.enable();
      await Prefs.init();
      await applyRememberedVersionBlock();
      unawaited(Auth.startGuest());
      await AppTrackingTransparency.requestTrackingAuthorization();
      await MobileAds.instance.initialize();
      Locale locale = await initializeLocale();
      runApp(App(locale));
    }).catchError((error) {
      print('FlutterFire: Caught error in FlutterFire initialization.');
      FirebaseCrashlytics.instance.recordError(error, null);
    });
  }, (error, stackTrace) {
    print('runZonedGuarded: Caught error in my root zone.');
    if (isIgnorableNonFatalError(error)) {
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });
}

class App extends StatefulWidget {
  final Locale locale;

  App(this.locale);

  static void setLocale(BuildContext context, String language) async {
    _AppState state = context.findAncestorStateOfType<_AppState>()!;
    state.changeLanguage(language);
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late Locale _locale;
  String? _currentTopic;

  Future<void> _logFailedPurchaseEvent() async {
    await _firebaseAnalytics.logEvent(name: 'purchase_failed');
  }

  void _subscribeToLanguageTopic(String languageCode) {
    final topic = 'notifications-$languageCode';
    FirebaseMessaging.instance.subscribeToTopic(topic).then((_) {
      print('Subscribed to $topic');
      _currentTopic = topic;
    }).catchError((error) {
      print('Failed to subscribe to $topic: $error');
    });
  }

  void _unsubscribeFromTopic(String topic) {
    FirebaseMessaging.instance.unsubscribeFromTopic(topic).then((_) {
      print('Unsubscribed from $topic');
    }).catchError((error) {
      print('Failed to unsubscribe from $topic: $error');
    });
  }

  changeLanguage(String language) {
    if (language.isEmpty) {
      setState(() {
        translationCache = {};
        _locale = getDeviceLocale();
      });
    } else {
      var languageCountry = language.split('_');
      setState(() {
        translationCache = {};
        _locale = Locale(languageCountry[0], languageCountry[1]);
      });
    }

    if (_currentTopic != null) {
      _unsubscribeFromTopic(_currentTopic!);
    }

    _subscribeToLanguageTopic(_locale.languageCode);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    final remembered = <String>[
      for (final purchase in purchaseDetailsList)
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored)
          purchase.productID,
    ];
    if (remembered.isNotEmpty) {
      unawaited(rememberStorePurchases(remembered));
    }
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.restored) {
        Purchases.purchases[purchaseDetails.productID] = purchaseDetails;
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        if (mounted &&
            (purchaseDetails.productID == productNoAdsAndroid ||
                purchaseDetails.productID == productNoAdsIOS)) {
          setState(() {});
        }
      }
    });
  }

  Future<dynamic> handleMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      String action = message.data[notificationAttributeAction];
      if (action.isNotEmpty && _navigatorKey.currentContext != null) {
        switch (action) {
          case notificationAttributeActionList:
            String path = message.data[notificationAttributePath];
            final openNew = notificationPathOpensNewInBook(path);
            if (!openNew) {
              rootReference.child(path).keepSynced(true);
            }
            return notificationPopup(
              _navigatorKey.currentContext!,
              notificationTitle(message),
              notificationBody(message),
            ).then((open) {
              final context = _navigatorKey.currentContext;
              if (open && context != null) {
                Navigator.push(
                  context,
                  openNew
                      ? guideNewInBookRoute()
                      : guideNotificationListRoute(
                          path,
                          title: notificationTitle(message),
                        ),
                );
              }
            });
          case notificationAttributeActionPlant:
            return notificationPopup(
              _navigatorKey.currentContext!,
              notificationTitle(message),
              notificationBody(message),
            ).then((open) {
              final context = _navigatorKey.currentContext;
              final route = guideNotificationPlantRoute(
                message.data[notificationAttributeName],
              );
              if (open && context != null && route != null) {
                Navigator.push(context, route);
              }
            });
          case notificationAttributeActionBrowse:
            String uri = message.data[notificationAttributeUri];
            return notificationPopup(
              _navigatorKey.currentContext!,
              notificationTitle(message),
              notificationBody(message),
            ).then((open) {
              if (open && uri.isNotEmpty) {
                launchURL(uri);
              }
            });
        }
      }
    }
    return Future.value(null);
  }

  void _persistFcmToken(String? token) {
    if (token == null || token.isEmpty) {
      return;
    }
    Prefs.setString(keyToken, token);
    if (Auth.appUser != null) {
      usersReference
          .child(Auth.appUser!.uid)
          .child(firebaseAttributeToken)
          .set(token);
    }
  }

  void _firebaseCloudMessagingListeners() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getToken().then((token) {
      print('token $token');
      _persistFcmToken(token);
    }).onError((error, stackTrace) => null);
    FirebaseMessaging.instance.onTokenRefresh.listen(_persistFcmToken);

    FirebaseMessaging.instance.getInitialMessage().then((value) async {
      if (value != null) {
        await _openFromNotification(value);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _openFromNotification(message);
    });
  }

  Future<void> _openFromNotification(RemoteMessage message) async {
    if (message.data.isEmpty || _navigatorKey.currentContext == null) {
      return;
    }
    MaterialPageRoute<dynamic>? redirect = await findRedirectF(message.data);
    if (redirect != null && _navigatorKey.currentContext != null) {
      Navigator.push(_navigatorKey.currentContext!, redirect);
    }
  }

  Future<MaterialPageRoute<dynamic>>? findRedirectF(
      Map<String, dynamic> notificationData) {
    if (notificationData.isEmpty) {
      return null;
    } else {
      String action = notificationData[notificationAttributeAction];
      if (action.isEmpty) {
        return null;
      } else {
        switch (action) {
          case notificationAttributeActionBrowse:
            String uri = notificationData[notificationAttributeUri];
            if (uri.isNotEmpty) {
              launchURL(uri);
              return null;
            }
            return null;
          case notificationAttributeActionList:
            String path = notificationData[notificationAttributePath];
            if (path.isNotEmpty && notificationPathOpensNewInBook(path)) {
              return Future<MaterialPageRoute<dynamic>>.value(
                  guideNewInBookRoute());
            }
            if (path.isNotEmpty) {
              rootReference.child(path).keepSynced(true);
              return Future<MaterialPageRoute<dynamic>>.value(
                guideNotificationListRoute(
                  path,
                  title: notificationData['title']?.toString(),
                ),
              );
            }
            return null;
          case notificationAttributeActionPlant:
            final route = guideNotificationPlantRoute(
              notificationData[notificationAttributeName]?.toString(),
            );
            if (route == null) return null;
            return Future<MaterialPageRoute<dynamic>>.value(route);
          default:
            return null;
        }
      }
    }
  }

  Locale localeResolution(
      Locale savedLocale, Iterable<Locale> supportedLocales) {
    Locale? resultLocale;
    Map<String, Locale> defaultLocale = {};
    for (Locale locale in supportedLocales) {
      if (locale.languageCode == savedLocale.languageCode &&
          locale.countryCode == savedLocale.countryCode) {
        resultLocale = locale;
        break;
      }

      if (locale.languageCode != languageEnglish ||
          locale.countryCode == 'US') {
        defaultLocale[locale.languageCode] = locale;
      }
    }

    if (resultLocale == null) {
      for (Locale locale in supportedLocales) {
        if (locale.languageCode == savedLocale.languageCode) {
          resultLocale = defaultLocale[locale.languageCode];
          break;
        }
      }
    }

    if (resultLocale == null) {
      resultLocale = defaultLocale[languageEnglish];
    }

    Prefs.setStringList(keyLanguageAndCountry,
        [resultLocale!.languageCode, resultLocale.countryCode ?? '']);
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
    Purchases.hasLifetimeSubscription =
        Prefs.getBool(keyLifetimeSubscription, false);
    Auth.setUser();
    Offline.initialize();
  }

  @override
  void initState() {
    super.initState();

    _firebaseCloudMessagingListeners();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
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
    initStoreInfo();

    _locale = widget.locale;
    _subscribeToLanguageTopic(_locale.languageCode);
  }

  @override
  void dispose() {
    Prefs.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      locale: localeResolution(_locale, S.delegate.supportedLocales),
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        return FocusTraversalGroup(
          policy: safeReadingOrderTraversalPolicy,
          child: ListenableBuilder(
            listenable: VersionGateController.instance,
            builder: (context, navigator) {
              final blocked =
                  VersionGateController.instance.prompt == VersionPrompt.block;
              return Stack(
                children: [
                  IgnorePointer(
                    ignoring: blocked,
                    child: ExcludeFocus(
                      excluding: blocked,
                      child: ExcludeSemantics(
                        excluding: blocked,
                        child: navigator ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  if (blocked)
                    Positioned.fill(
                      child: VersionRequiredPage(
                        onUpdate: () => openAppUpdate(requiredUpdate: true),
                      ),
                    ),
                ],
              );
            },
            child: child,
          ),
        );
      },
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        CountryLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      initialRoute: '/guide',
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: _firebaseAnalytics),
      ],
      routes: {
        '/guide': (context) => const GuideShell(),
      },
    );
  }
}
