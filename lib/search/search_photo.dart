import 'dart:io';

import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/purchase/rewarded_ad.dart';
import 'package:abherbs_flutter/search/plant_id_search.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/signin/sign_in.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const int maxFailedLoadAttempts = 3;

class SearchPhoto extends StatefulWidget {
  final Locale myLocale;
  SearchPhoto(this.myLocale);

  @override
  _SearchPhotoState createState() => _SearchPhotoState();
}

class _SearchPhotoState extends State<SearchPhoto> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  File? _image;
  Future<List<SearchResult>>? _searchResultF;

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  Future<void> _logPhotoSearchEvent() async {
    await _firebaseAnalytics.logEvent(name: 'search_photo');
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

  Future<void> _showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).snack_loading_ad),
        duration: Duration(milliseconds: 1500),
      ));
      return;
    }
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _createRewardedAd();
      },
    );

    ad.setImmersiveMode(true);
    await tieRewardedAd(ad);
    ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          await Auth.waitForAdReward(Auth.credits);
          if (mounted) setState(() {});
        });
  }

  Future<void> _getImage(GlobalKey<ScaffoldState> _key, ImageSource source, double maxSize) async {
    if (Purchases.isPhotoSearch() || Auth.credits > 0) {
      setState(() {
        _image = null;
        _searchResultF = Future<List<SearchResult>>(() {
          return <SearchResult>[];
        });
      });
      var image = await _picker.pickImage(source: source, maxWidth: maxSize);
      if (image != null) {
        _logPhotoSearchEvent();
        setState(() {
          _image = File(image.path);
          _searchResultF = identifyPlantPhoto(
            image: _image!,
            languageCode: plantIdLanguageTag(widget.myLocale),
            onCreditsChanged: () {
              if (mounted) setState(() {});
            },
          ).then((identification) => identification.results);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (!Purchases.isPhotoSearch()) {
      _createRewardedAd();
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var self = this;
    double maxSize = MediaQuery.of(context).size.width;
    TextStyle feedbackTextStyle = TextStyle(
      fontSize: 18.0,
    );
    TextStyle creditsTextStyle = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );

    var _widgets = <Widget>[];
    _widgets.add(Card(
      child: Container(
        padding: EdgeInsets.all(5.0),
        width: maxSize,
        height: maxSize,
        child: _image == null
            ? Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              child: Icon(Icons.add_a_photo, color: Theme.of(context).secondaryHeaderColor, size: 80.0),
              onTap: () {
                _getImage(_key, ImageSource.camera, maxSize);
              },
            ),
            SizedBox(width: 80.0),
            GestureDetector(
              child: Icon(Icons.add_photo_alternate, color: Theme.of(context).secondaryHeaderColor, size: 80.0),
              onTap: () {
                _getImage(_key, ImageSource.gallery, maxSize);
              },
            )
          ]),
        )
            : Image.file(_image!, fit: BoxFit.cover, width: maxSize, height: maxSize),
      ),
    ));

    if (!Purchases.isPhotoSearch()) {
      if (Auth.appUser == null) {
        _widgets.add(Card(
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
        ));
      } else {
        _widgets.add(Card(
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
                    Text(Auth.credits.toString(), style: creditsTextStyle,),
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
        ));
      }
    }

    if (_image == null) {
      _widgets.add(Card(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              S.of(context).photo_search_note,
              style: TextStyle(fontSize: 18.0),
            ))));
    } else {
      _widgets.add(Card(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: FutureBuilder<List<SearchResult>>(
                future: _searchResultF,
                builder: (BuildContext context, AsyncSnapshot<List<SearchResult>> results) {
                  switch (results.connectionState) {
                    case ConnectionState.done:
                      if (results.data == null || results.data!.isEmpty) {
                        return Text(
                          S.of(context).photo_search_empty,
                          style: TextStyle(fontSize: 18.0),
                        );
                      } else {
                        return Column(
                          children: results.data!.map((result) {
                            if (result.path != null && result.path!.isNotEmpty) {
                              var title = result.labelInLanguage!.isNotEmpty ? result.labelInLanguage! : result.labelLatin!;
                              return Material(
                                  color: Colors.lightBlueAccent,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                          NumberFormat.percentPattern().format(result.confidence)),
                                      backgroundColor: Colors.white,
                                    ),
                                    title: Text(title),
                                    subtitle: result.labelInLanguage!.isNotEmpty ? Text(result.labelLatin!) : null,
                                    trailing: Text(result.count.toString()),
                                    onTap: () {
                                      if (result.path!.contains('/')) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PlantList({}, '', rootReference.child(result.path!)), settings: RouteSettings(name: 'PlantList')),
                                        );
                                      } else {
                                        goToDetail(self, context, widget.myLocale, result.path!, {});
                                      }
                                    },
                                    onLongPress: () {
                                      Clipboard.setData(new ClipboardData(text: title));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(S.of(context).snack_copy),
                                      ));
                                    },
                                  ));
                            } else {
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(NumberFormat.percentPattern().format(result.confidence)),
                                  backgroundColor: Colors.white,
                                ),
                                title: result.commonName != null && result.commonName!.isNotEmpty ? Text(result.commonName!) : Text(result.labelLatin!),
                                subtitle: result.commonName != null && result.commonName!.isNotEmpty ? Text(result.labelLatin!) : null,
                                onLongPress: () {
                                  Clipboard.setData(new ClipboardData(text: result.labelLatin!));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(S.of(context).snack_copy),
                                  ));
                                },
                              );
                            }
                          }).toList(),
                        );
                      }
                    default:
                      return Center(
                        child: const CircularProgressIndicator(),
                      );
                  }
                }),
          )));
    }

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).product_photo_search_title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              _getImage(_key, ImageSource.camera, maxSize);
            },
          ),
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: () {
              _getImage(_key, ImageSource.gallery, maxSize);
            },
          ),
        ],
      ),
      body: ListView(
        children: _widgets,
      ),
    );
  }
}
