import 'dart:io';

import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    TextStyle feedbackTextStyle = TextStyle(
      fontSize: 18.0,
    );

//    AdmobInterstitial interstitialAd = AdmobInterstitial(
//      adUnitId: interstitialAdUnitId,
//      listener: (AdmobAdEvent event, Map<String, dynamic> args) {},
//    );
//    interstitialAd.load();
//
//    AdmobReward rewardAd = AdmobReward(
//        adUnitId: rewardAdUnitId,
//        listener: (AdmobAdEvent event, Map<String, dynamic> args) {});
//    rewardAd.load();

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
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
              SizedBox(height: 10.0),
              GestureDetector(
                onTap: () {
                  if (Platform.isAndroid) {
                    launchURL('market://details?id=sk.ab.herbs');
                  } else {
                    launchURL('https://itunes.apple.com/us/app/whats-that-flower/id1449982118?mt=8&action=write-review');
                  }
                },
                child: Platform.isAndroid
                    ? Image(image: AssetImage('res/images/google_play.png'))
                    : Image(image: AssetImage('res/images/app_store.png')),
              ),
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
              SizedBox(height: 10.0),
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
              SizedBox(height: 10.0),
              GestureDetector(
                onTap: () {
                  if (Platform.isAndroid) {
                    launchURL('market://details?id=sk.ab.herbsplus');
                  } else {
                    key.currentState.showSnackBar(new SnackBar(
                      content: new Text(S.of(context).snack_publish),
                    ));
                  }
                },
                child: Platform.isAndroid
                    ? Image(image: AssetImage('res/images/google_play.png'))
                    : Image(image: AssetImage('res/images/app_store.png')),
              ),
            ]),
          ),
        ),
//        Card(
//          child: Container(
//            padding: EdgeInsets.all(10.0),
//            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
//              Text(
//                S.of(context).feedback_run_ads,
//                style: feedbackTextStyle,
//                textAlign: TextAlign.center,
//              ),
//              Container(
//                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
//                child: Row(
//                  mainAxisAlignment: MainAxisAlignment.spaceAround,
//                  children: [
//                    Image(
//                      image: AssetImage('res/images/admob.png'),
//                      width: 50.0,
//                      height: 50.0,
//                    ),
//                  ],
//                ),
//              ),
//              RaisedButton(
//                onPressed: () async {
//                  if (await interstitialAd.isLoaded) {
//                    interstitialAd.show();
//                  } else {
//                    key.currentState.showSnackBar(SnackBar(
//                      content: Text(S.of(context).snack_loading_ad),
//                    ));
//                  }
//                },
//                child: Text(S.of(context).feedback_run_ads_fullscreen),
//              ),
//              RaisedButton(
//                onPressed: () async {
//                  if (await rewardAd.isLoaded) {
//                    rewardAd.show();
//                  } else {
//                    key.currentState.showSnackBar(SnackBar(
//                      content: Text(S.of(context).snack_loading_ad),
//                    ));
//                  }
//                },
//                child: Text(S.of(context).feedback_run_ads_video),
//              ),
//            ]),
//          ),
//        ),
      ]),
    );
  }
}
