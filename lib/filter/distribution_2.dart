import 'dart:async';

import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../keys.dart';

class Distribution2 extends StatefulWidget {
  final Map<String, String> filter;
  final int region;
  Distribution2(this.filter, this.region);

  @override
  _Distribution2State createState() => _Distribution2State();
}

class _Distribution2State extends State<Distribution2> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  int _count = -1;
  late StreamSubscription<firebase_auth.User?> _listener;
  BannerAd? _ad;

  void _navigate(String value) {
    var newFilter = Map<String, String>();
    newFilter.addAll(widget.filter);
    newFilter[filterDistribution] = value;

    var filter = getFilterKey(newFilter);
    countsReference.child(filter).keepSynced(true);
    countsReference.child(filter).once().then((event) {
      if (this.mounted) {
        if (event.snapshot.value != null && (event.snapshot.value as int) > 0) {
          Navigator.push(context, getNextFilterRoute(context, newFilter));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).snack_no_flowers),
          ));
        }
      }
    });
  }

  Future<void> _setCount() async {
    final event = await countsReference.child(getFilterKey(widget.filter)).once();
    int count = event.snapshot.value as int? ?? 0;
    if (this.mounted) {
      setState(() {
        _count = count;
      });
    }
  }

  Widget _getBody(BuildContext context) {
    var _secondLevelTextStyle = TextStyle(
      fontSize: 20.0,
      color: Colors.black,
    );

    var subRegions = <List<String>>[];
    switch (widget.region) {
      case 1:
        subRegions.add([S.of(context).northern_europe, 'res/images/wgsrpd_northern_europe.webp', '10']);
        subRegions.add([S.of(context).middle_europe, 'res/images/wgsrpd_middle_europe.webp', '11']);
        subRegions.add([S.of(context).southwestern_europe, 'res/images/wgsrpd_southwestern_europe.webp', '12']);
        subRegions.add([S.of(context).southeastern_europe, 'res/images/wgsrpd_southeastern_europe.webp', '13']);
        subRegions.add([S.of(context).eastern_europe, 'res/images/wgsrpd_eastern_europe.webp', '14']);
        break;
      case 2:
        subRegions.add([S.of(context).northern_africa, 'res/images/wgsrpd_northern_africa.webp', '20']);
        subRegions.add([S.of(context).macaronesia, 'res/images/wgsrpd_macaronesia.webp', '21']);
        subRegions.add([S.of(context).west_tropical_africa, 'res/images/wgsrpd_west_tropical_africa.webp', '22']);
        subRegions.add([S.of(context).west_central_tropical_africa, 'res/images/wgsrpd_central_tropical_africa.webp', '23']);
        subRegions.add([S.of(context).northeast_tropical_africa, 'res/images/wgsrpd_northeast_tropical_africa.webp', '24']);
        subRegions.add([S.of(context).east_tropical_africa, 'res/images/wgsrpd_east_tropical_africa.webp', '25']);
        subRegions.add([S.of(context).south_tropical_africa, 'res/images/wgsrpd_south_tropical_africa.webp', '26']);
        subRegions.add([S.of(context).southern_africa, 'res/images/wgsrpd_southern_africa.webp', '27']);
        subRegions.add([S.of(context).middle_atlantic_ocean, 'res/images/wgsrpd_middle_atlantic_ocean.webp', '28']);
        subRegions.add([S.of(context).western_indian_ocean, 'res/images/wgsrpd_western_indian_ocean.webp', '29']);
        break;
      case 3:
        subRegions.add([S.of(context).siberia, 'res/images/wgsrpd_siberia.webp', '30']);
        subRegions.add([S.of(context).russian_far_east, 'res/images/wgsrpd_russian_far_east.webp', '31']);
        subRegions.add([S.of(context).middle_asia, 'res/images/wgsrpd_middle_asia.webp', '32']);
        subRegions.add([S.of(context).caucasus, 'res/images/wgsrpd_caucasus.webp', '33']);
        subRegions.add([S.of(context).western_asia, 'res/images/wgsrpd_western_asia.webp', '34']);
        subRegions.add([S.of(context).arabian_peninsula, 'res/images/wgsrpd_arabian_peninsula.webp', '35']);
        subRegions.add([S.of(context).china, 'res/images/wgsrpd_china.webp', '36']);
        subRegions.add([S.of(context).mongolia, 'res/images/wgsrpd_mongolia.webp', '37']);
        subRegions.add([S.of(context).eastern_asia, 'res/images/wgsrpd_east_asia.webp', '38']);
        break;
      case 4:
        subRegions.add([S.of(context).indian_subcontinent, 'res/images/wgsrpd_indian_subcontinent.webp', '40']);
        subRegions.add([S.of(context).indochina, 'res/images/wgsrpd_indochina.webp', '41']);
        subRegions.add([S.of(context).malesia, 'res/images/wgsrpd_malesia.webp', '42']);
        subRegions.add([S.of(context).papuasia, 'res/images/wgsrpd_papuasia.webp', '43']);
        break;
      case 5:
        subRegions.add([S.of(context).australia, 'res/images/wgsrpd_australia.webp', '50']);
        subRegions.add([S.of(context).new_zealand, 'res/images/wgsrpd_new_zealand.webp', '51']);
        break;
      case 6:
        subRegions.add([S.of(context).southwestern_pacific, 'res/images/wgsrpd_southwestern_pacific.webp', '60']);
        subRegions.add([S.of(context).south_central_pacific, 'res/images/wgsrpd_south_central_pacific.webp', '61']);
        subRegions.add([S.of(context).northwestern_pacific, 'res/images/wgsrpd_northwestern_pacific.webp', '62']);
        subRegions.add([S.of(context).north_central_pacific, 'res/images/wgsrpd_north_central_pacific.webp', '63']);
        break;
      case 7:
        subRegions.add([S.of(context).subarctic_america, 'res/images/wgsrpd_subarctic_america.webp', '70']);
        subRegions.add([S.of(context).western_canada, 'res/images/wgsrpd_western_canada.webp', '71']);
        subRegions.add([S.of(context).eastern_canada, 'res/images/wgsrpd_eastern_canada.webp', '72']);
        subRegions.add([S.of(context).northwestern_usa, 'res/images/wgsrpd_northwestern_united_states.webp', '73']);
        subRegions.add([S.of(context).north_central_usa, 'res/images/wgsrpd_north_central_united_states.webp', '74']);
        subRegions.add([S.of(context).northeastern_usa, 'res/images/wgsrpd_northeastern_united_states.webp', '75']);
        subRegions.add([S.of(context).southwestern_usa, 'res/images/wgsrpd_southwestern_united_states.webp', '76']);
        subRegions.add([S.of(context).south_central_usa, 'res/images/wgsrpd_south_central_united_states.webp', '77']);
        subRegions.add([S.of(context).southeastern_usa, 'res/images/wgsrpd_southeastern_united_states.webp', '78']);
        subRegions.add([S.of(context).mexico, 'res/images/wgsrpd_mexico.webp', '79']);
        break;
      case 8:
        subRegions.add([S.of(context).central_america, 'res/images/wgsrpd_central_america.webp', '80']);
        subRegions.add([S.of(context).caribbean, 'res/images/wgsrpd_caribbean.webp', '81']);
        subRegions.add([S.of(context).northern_south_america, 'res/images/wgsrpd_northern_south_america.webp', '82']);
        subRegions.add([S.of(context).western_south_america, 'res/images/wgsrpd_western_south_america.webp', '83']);
        subRegions.add([S.of(context).brazil, 'res/images/wgsrpd_brazil.webp', '84']);
        subRegions.add([S.of(context).southern_south_america, 'res/images/wgsrpd_southern_south_america.webp', '85']);
        break;
    }

    return Container(
        color: Colors.white30,
        child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            padding: EdgeInsets.only(bottom: getFABPadding()),
            mainAxisSpacing: 3.0,
            crossAxisSpacing: 3.0,
            children: subRegions.map((List<String> items) {
              return GridTile(
                child: TextButton(
                  child: Stack(alignment: Alignment.center, children: [
                    Image(
                      image: AssetImage(items[1]),
                    ),
                    Text(
                      items[0],
                      style: _secondLevelTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ]),
                  onPressed: () {
                    _navigate(items[2]);
                  },
                ),
              );
            }).toList()));
  }

  @override
  void initState() {
    super.initState();

    _listener = Auth.subscribe((firebase_auth.User? user) => setState(() {}));

    if (!Purchases.isNoAds()) {
      _ad = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
          },
          onAdClosed: (Ad ad) {
            ad.dispose();
          },
        ),
      );
      _ad?.load();
    }

    _setCount();
  }

  @override
  void dispose() {
    filterRoutes.remove(filterDistribution2);
    _listener.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mainContext = context;
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).filter_distribution),
        actions: getActions(context, _key, widget.filter),
      ),
      drawer: AppDrawer(widget.filter, () => {}),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              "res/images/app_background.webp",
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: _getBody(context),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: !Purchases.isNoAds() && _ad != null
                    ? Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(bottom: 5.0, top: 5.0),
                        child: AdWidget(ad: _ad!),
                        width: _ad!.size.width.toDouble(),
                        height: _ad!.size.height.toDouble(),
                      )
                    : Container(
                        height: 0.0,
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Preferences.myFilterAttributes.indexOf(filterDistribution),
        items: getBottomNavigationBarItems(context, widget.filter),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          onBottomNavigationBarTap(context, widget.filter, index, -1);
        },
      ),
      floatingActionButton: Container(
        height: 70.0 + getFABPadding(),
        width: 70.0,
        padding: EdgeInsets.only(bottom: getFABPadding()),
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              clearFilter(widget.filter, _setCount);
            });
          },
          child: FloatingActionButton(
            onPressed: () {
              filterRoutes.remove(filterDistribution2);
              Navigator.pushReplacement(
                mainContext,
                MaterialPageRoute(builder: (context) => PlantList(widget.filter, '', keysReference.child(getFilterKey(widget.filter))), settings: RouteSettings(name: 'PlantList')),
              );
            },
            child: _count == -1 ? CircularProgressIndicator() : Text('$_count'),
          ),
        ),
      ),
    );
  }
}
