import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/purchase/enhancements.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/signin/sign_in.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const int maxFailedLoadAttempts = 3;

class FeedbackScreen extends StatefulWidget {
  final AppUser currentUser;
  final Map<String, String> filter;

  FeedbackScreen(this.currentUser, this.filter);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  InterstitialAd _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  RewardedAd _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: getInterstitialAdUnitId(),
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).snack_loading_ad),
        duration: Duration(milliseconds: 1500),
      ));
      return;
    }
    _interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd.show();
    _interstitialAd = null;
  }

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: getRewardAdUnitId(),
        request: AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).snack_loading_ad),
        duration: Duration(milliseconds: 1500),
      ));
      return;
    }
    _rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd.setImmersiveMode(true);
    _rewardedAd.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          await Auth.changeCredits(1, "1");
          setState(() {});
        });
    _rewardedAd = null;
  }


  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
    _createRewardedAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
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
                    ElevatedButton(
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
                    ElevatedButton(
                      onPressed: () async {
                        _showRewardedAd();
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
              ElevatedButton(
                onPressed: () {
                  launchURL(webUrl + 'translate_app?lang=' + getLanguageCode(myLocale.languageCode));
                },
                child: Text(S.of(context).feedback_submit_translate_app),
              ),
              ElevatedButton(
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
              ElevatedButton(
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
              ElevatedButton(
                onPressed: () async {
                  _showInterstitialAd();
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
