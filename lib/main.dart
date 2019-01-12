import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/splash.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen/screen.dart';

class Ads {
  static BannerAd _bannerAd;
  static bool isShown = false;
  static bool _isGoingToBeShown = false;

  static void showBannerAd([State state]) {
    if (state != null && !state.mounted) return;
    if (_bannerAd == null) setBannerAd();
    if (!isShown) {
      _isGoingToBeShown = true;
      _bannerAd
        ..load()
        ..show(anchorOffset: 60.0, anchorType: AnchorType.bottom);
    }
  }

  static void hideBannerAd() {
    if (_bannerAd != null && !_isGoingToBeShown) {
      _bannerAd.dispose().then((disposed) {
        isShown = !disposed;
      });
      _bannerAd = null;
    }
  }

  static void setBannerAd() {
    MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      keywords: <String>['flower', 'identify flower', 'plant', 'tree'],
      contentUrl: 'https://whatsthatflower.com/',
      childDirected: false,
      testDevices: <String>[], // Android emulators are considered test devices
    );
    _bannerAd = BannerAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: BannerAd.testAdUnitId,
      size: AdSize.banner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        if (event == MobileAdEvent.loaded) {
          isShown = true;
          _isGoingToBeShown = false;
        } else if (event == MobileAdEvent.failedToLoad) {
          isShown = false;
          _isGoingToBeShown = false;
        }
        print("BannerAd event is $event");
      },
    );
  }
}

void main() {
  Screen.keepOn(true);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(App());
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Future<Locale> _localeF;

  onChangeLanguage(String language) {
    setState(() {
      _localeF = new Future<Locale>(() {
        return language.isEmpty ? null : Locale(language, '');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: adAppId);

    Prefs.init();
    Prefs.getStringF('pref_language').then((String language) {
      onChangeLanguage(language);
    });
  }

  @override
  void dispose() {
    Prefs.dispose();
    Ads.hideBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Locale>(
        future: _localeF,
        builder: (BuildContext context, AsyncSnapshot<Locale> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return MaterialApp(
                locale: snapshot.data,
                localizationsDelegates: [
                  S.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: S.delegate.supportedLocales,
                localeResolutionCallback: S.delegate.resolution(fallback: new Locale("en", "")),
                home: Splash(this.onChangeLanguage),
              );
            default:
              return const CircularProgressIndicator();
          }
        });
  }
}
