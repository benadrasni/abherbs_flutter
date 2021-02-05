import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/purchase/enhancements.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/signin/sign_in.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  final AppUser currentUser;
  final Map<String, String> filter;

  FeedbackScreen(this.currentUser, this.filter);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  AdmobInterstitial _interstitialAd;
  AdmobReward _rewardAd;
  bool _isInterstitialLoading;
  bool _isRewardLoading;

  void handleEvent(AdmobAdEvent event, Map<String, dynamic> args, String adType) async {
    switch (event) {
      case AdmobAdEvent.loaded:
        if (adType == 'Interstitial') {
          _isInterstitialLoading = false;
        } else if (adType == 'Reward') {
          _isRewardLoading = false;
        }
        break;
      case AdmobAdEvent.failedToLoad:
        if (adType == 'Interstitial') {
          _isInterstitialLoading = true;
          _interstitialAd.load();
        } else if (adType == 'Reward') {
          _isRewardLoading = true;
          _rewardAd.load();
        }
        break;
      case AdmobAdEvent.clicked:
        break;
      case AdmobAdEvent.impression:
        break;
      case AdmobAdEvent.opened:
        break;
      case AdmobAdEvent.leftApplication:
        break;
      case AdmobAdEvent.closed:
        if (adType == 'Interstitial') {
          _isInterstitialLoading = true;
          _interstitialAd.load();
        } else if (adType == 'Reward') {
          _isRewardLoading = true;
          _rewardAd.load();
        }
        break;
      case AdmobAdEvent.completed:
        break;
      case AdmobAdEvent.rewarded:
        await Auth.changeCredits(1, "1");
        setState(() {});
        break;
      case AdmobAdEvent.started:
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _isInterstitialLoading = true;
    _interstitialAd = AdmobInterstitial(
      adUnitId: getInterstitialAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        handleEvent(event, args, 'Interstitial');
      },
    );
    _interstitialAd.load();

    _isRewardLoading = true;
    _rewardAd = AdmobReward(
      adUnitId: getRewardAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        handleEvent(event, args, 'Reward');
      },
    );
    _rewardAd.load();
  }

  @override
  void dispose() {
    _interstitialAd.dispose();
    _rewardAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    TextStyle feedbackTextStyle = TextStyle(
      fontSize: 18.0,
    );
    TextStyle creditsTextStyle = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );

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
        widget.currentUser == null
            ? Card(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(
                      S.of(context).credit_login,
                      style: feedbackTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    RaisedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignInScreen(), settings: RouteSettings(name: 'SignIn')),
                        ).then((result) {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        });
                      },
                      child: Text(S.of(context).auth_sign_in),
                    ),
                  ]),
                ),
              )
            : Card(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(
                      S.of(context).credit_message,
                      style: feedbackTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(S.of(context).credit_count, style: creditsTextStyle,),
                          Text(widget.currentUser.credits.toString(), style: creditsTextStyle,),
                        ],
                      ),
                    ),
                    RaisedButton(
                      onPressed: () async {
                        if (_isRewardLoading) {
                          key.currentState.showSnackBar(SnackBar(
                            content: Text(S.of(context).snack_loading_ad),
                            duration: Duration(milliseconds: 1500),
                          ));
                        } else {
                          _rewardAd.show();
                        }
                      },
                      child: Text(S.of(context).credit_ads_video),
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
                    launchURL(playStore);
                  } else {
                    launchURL(appStore);
                  }
                },
                child: Platform.isAndroid ? Image(image: AssetImage('res/images/google_play.png')) : Image(image: AssetImage('res/images/app_store.png')),
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
                  launchURL(webUrl + 'translate_app?lang=' + getLanguageCode(myLocale.languageCode));
                },
                child: Text(S.of(context).feedback_submit_translate_app),
              ),
              RaisedButton(
                onPressed: () {
                  launchURL(webUrl + 'translate_flower?lang=' + getLanguageCode(myLocale.languageCode));
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
              RaisedButton(
                color: Theme.of(context).accentColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EnhancementsScreen(widget.filter), settings: RouteSettings(name: 'Enhancements')),
                  );
                },
                child: Text(
                  S.of(context).enhancements,
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
                  if (_isInterstitialLoading) {
                    key.currentState.showSnackBar(SnackBar(
                      content: Text(S.of(context).snack_loading_ad),
                      duration: Duration(milliseconds: 1500),
                    ));
                  } else {
                    _interstitialAd.show();
                  }
                },
                child: Text(S.of(context).feedback_run_ads_fullscreen),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
