import 'dart:io';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    TextStyle feedbackTextStyle = TextStyle(
      fontSize: 18.0,
    );

    AdmobInterstitial interstitialAd = AdmobInterstitial(
      adUnitId: interstitialAdUnitId,
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {},
    );

    AdmobReward rewardAd = AdmobReward(
        adUnitId: 'ca-app-pub-3940256099942544/5224354917',
        listener: (AdmobAdEvent event, Map<String, dynamic> args) {});

    Locale myLocale = Localizations.localeOf(context);
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(S.of(context).feedback_title),
      ),
      body: ListView(shrinkWrap: true, padding: const EdgeInsets.all(10.0), children: [
        Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).feedback_intro,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
        Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).feedback_review,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0, left: 50.0, right: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Image(
                      image: AssetImage('res/images/color.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                    Image(
                      image: AssetImage('res/images/color.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                    Image(
                      image: AssetImage('res/images/color.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                    Image(
                      image: AssetImage('res/images/color.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                    Image(
                      image: AssetImage('res/images/color.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                  ],
                ),
              ),
              RaisedButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    launchURL('market://details?id=sk.ab.herbs');
                  } else {
                    key.currentState.showSnackBar(SnackBar(
                      content: Text(S.of(context).snack_publish),
                    ));
                  }
                },
                child: Text(S.of(context).feedback_google_play),
              )
            ]),
          ),
        ),
        Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).feedback_translate,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Image(
                      image: AssetImage('res/images/translate.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                  ],
                ),
              ),
              RaisedButton(
                onPressed: () {
                  launchURL(webUrl + 'translate_app?lang=' + myLocale.languageCode);
                },
                child: Text(S.of(context).feedback_submit_translate_app),
              ),
              RaisedButton(
                onPressed: () {
                  launchURL(webUrl + 'translate_flower?lang=' + myLocale.languageCode);
                },
                child: new Text(S.of(context).feedback_submit_translate_data),
              ),
            ]),
          ),
        ),
        Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).feedback_buy_extended,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Image(
                      image: AssetImage('res/images/extended.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                  ],
                ),
              ),
              RaisedButton(
                onPressed: () {
                  if (Theme.of(context).platform == TargetPlatform.android) {
                    launchURL('market://details?id=sk.ab.herbsplus');
                  } else {
                    key.currentState.showSnackBar(new SnackBar(
                      content: new Text(S.of(context).snack_publish),
                    ));
                  }
                },
                child: Text(S.of(context).feedback_submit_buy),
              )
            ]),
          ),
        ),
        Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                S.of(context).feedback_run_ads,
                style: feedbackTextStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Image(
                      image: AssetImage('res/images/admob.png'),
                      width: 50.0,
                      height: 50.0,
                    ),
                  ],
                ),
              ),
              RaisedButton(
                onPressed: () async {
                  interstitialAd.load();
                  if (await interstitialAd.isLoaded) {
                    interstitialAd.show();
                  }
                },
                child: Text(S.of(context).feedback_run_ads_fullscreen),
              ),
              RaisedButton(
                onPressed: () async {
                  rewardAd.load();
                  if (await rewardAd.isLoaded) {
                    rewardAd.show();
                  }
                },
                child: Text(S.of(context).feedback_run_ads_video),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
