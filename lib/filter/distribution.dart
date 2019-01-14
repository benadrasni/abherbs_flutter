import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/color.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/filter/habitat.dart';
import 'package:abherbs_flutter/filter/petal.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Distribution extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  Distribution(this.onChangeLanguage, this.filter);

  @override
  _DistributionState createState() => _DistributionState();
}

class _DistributionState extends State<Distribution> {
  Future<int> _count;
  Map<String, String> _filter;
  int _region;
  Future<String> _myRegionF;
  String _myRegion;
  GlobalKey<ScaffoldState> _key;

  void _openRegion(int region) {
    setState(() {
      _region = region == _region ? 0 : region;
    });
  }

  void _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterDistribution] = value;

    countsReference.child(getFilterKey(newFilter)).once().then((DataSnapshot snapshot) {
      if (snapshot.value != null && snapshot.value > 0) {
        Navigator.push(context, getNextFilterRoute(context, widget.onChangeLanguage, newFilter)).then((result) {
          Ads.showBannerAd(this);
        });
      } else {
        Ads.hideBannerAd();
        _key.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).snack_no_flowers),
        ));
      }
    });
  }

  _setCount() {
    _count = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  void setMyRegion() {
    _myRegion = "";
    _myRegionF = Prefs.getStringF(keyMyRegion);
    _myRegionF.then((region) {
      setState(() {
        _myRegion = region;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterDistribution);
    _region = 0;
    _key = new GlobalKey<ScaffoldState>();

    _setCount();

    setMyRegion();

    Ads.showBannerAd(this);
  }

  @override
  void dispose() {
    filterRoutes[filterDistribution] = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: new AppBar(
        title: new Text(S.of(context).filter_distribution),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, _filter, this.setMyRegion),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(5.0),
        children: _getRegions(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Image(image: AssetImage('res/images/color.png'), width: 25.0, height: 25.0,), title: Text(S.of(context).filter_color)),
          BottomNavigationBarItem(icon: Image(image: AssetImage('res/images/habitat.png'), width: 25.0, height: 25.0,), title: Text(S.of(context).filter_habitat)),
          BottomNavigationBarItem(icon: Image(image: AssetImage('res/images/petal.png'), width: 25.0, height: 25.0,), title: Text(S.of(context).filter_petal)),
        ],
        fixedColor: Colors.grey,
        onTap: (index) {
          var route;
          var nextFilterAttribute;
          switch (index) {
            case 0:
              route = MaterialPageRoute(builder: (context) => Color(widget.onChangeLanguage, _filter));
              nextFilterAttribute = filterColor;
              break;
            case 1:
              route = MaterialPageRoute(builder: (context) => Habitat(widget.onChangeLanguage, _filter));
              nextFilterAttribute = filterHabitat;
              break;
            case 2:
              route = MaterialPageRoute(builder: (context) => Petal(widget.onChangeLanguage, _filter));
              nextFilterAttribute = filterPetal;
              break;
          }
          if (filterRoutes[nextFilterAttribute] != null) {
            Navigator.removeRoute(context, filterRoutes[nextFilterAttribute]);
          }
          filterRoutes[nextFilterAttribute] = route;
          Navigator.push(context, route).then((result) {
            Ads.showBannerAd(this);
          });
        },
      ),
      floatingActionButton: new Container(
        padding: EdgeInsets.only(bottom: 50.0),
        height: 120.0,
        width: 70.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FutureBuilder<int>(
              future: _count,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          clearFilter(_filter, _setCount);
                        });
                      },
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlantList(widget.onChangeLanguage, _filter)),
                          ).then((result) {
                            Ads.showBannerAd(this);
                          });
                        },
                        child: Text(snapshot.data == null ? '' : snapshot.data.toString()),
                      ),
                    );
                }
              }),
        ),
      ),
    );
  }

  _getRegions() {
    var _firstLevelTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
    );
    var _secondLevelTextStyle = TextStyle(
      fontSize: 20.0,
    );

    var regions = <Widget>[];
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_my_region.webp'),
        ),
        Column(children: [
          Text(
            S.of(context).my_region,
            style: _firstLevelTextStyle,
          ),
          FutureBuilder<String>(
              future: _myRegionF,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                var value = "";
                if (snapshot.connectionState == ConnectionState.done) {
                  value = snapshot.data.isNotEmpty ? getFilterDistributionValue(context, snapshot.data) : "";
                }
                return Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }),
        ])
      ]),
      onPressed: () {
        if (_myRegion.isNotEmpty) {
          _navigate(_myRegion);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen(widget.onChangeLanguage)),
          ).then((result) {
            setMyRegion();
          });
        }
      },
    ));

    // Europe
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_europe.webp'),
        ),
        Text(
          S.of(context).europe,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(1);
      },
    ));
    if (_region == 1) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northern_europe.webp'),
                  ),
                  Text(
                    S.of(context).northern_europe,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('10');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_middle_europe.webp'),
                  ),
                  Text(
                    S.of(context).middle_europe,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('11');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southwestern_europe.webp'),
                  ),
                  Text(
                    S.of(context).southwestern_europe,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('12');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southeastern_europe.webp'),
                  ),
                  Text(
                    S.of(context).southeastern_europe,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('13');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Container(),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_eastern_europe.webp'),
                  ),
                  Text(
                    S.of(context).eastern_europe,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('14');
                },
              ),
              flex: 2,
            ),
            Expanded(
              child: Container(),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Africa
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_africa.webp'),
        ),
        Text(
          S.of(context).africa,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(2);
      },
    ));
    if (_region == 2) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northern_africa.webp'),
                  ),
                  Text(
                    S.of(context).northern_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('20');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_macaronesia.webp'),
                  ),
                  Text(
                    S.of(context).macaronesia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('21');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_west_tropical_africa.webp'),
                  ),
                  Text(
                    S.of(context).west_tropical_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('22');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_central_tropical_africa.webp'),
                  ),
                  Text(
                    S.of(context).west_central_tropical_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('23');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northeast_tropical_africa.webp'),
                  ),
                  Text(
                    S.of(context).northeast_tropical_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('24');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_east_tropical_africa.webp'),
                  ),
                  Text(
                    S.of(context).east_tropical_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('25');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_south_tropical_africa.webp'),
                  ),
                  Text(
                    S.of(context).south_tropical_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('26');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southern_africa.webp'),
                  ),
                  Text(
                    S.of(context).southern_africa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('27');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_middle_atlantic_ocean.webp'),
                  ),
                  Text(
                    S.of(context).middle_atlantic_ocean,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('28');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_western_indian_ocean.webp'),
                  ),
                  Text(
                    S.of(context).western_indian_ocean,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('29');
                },
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Asia temperate
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_asia_temperate.webp'),
        ),
        Text(
          S.of(context).asia_temperate,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(3);
      },
    ));
    if (_region == 3) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_siberia.webp'),
                  ),
                  Text(
                    S.of(context).siberia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('30');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_russian_far_east.webp'),
                  ),
                  Text(
                    S.of(context).russian_far_east,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('31');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_middle_asia.webp'),
                  ),
                  Text(
                    S.of(context).middle_asia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('32');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_caucasus.webp'),
                  ),
                  Text(
                    S.of(context).caucasus,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('33');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_western_asia.webp'),
                  ),
                  Text(
                    S.of(context).western_asia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('34');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_arabian_peninsula.webp'),
                  ),
                  Text(
                    S.of(context).arabian_peninsula,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('35');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_china.webp'),
                  ),
                  Text(
                    S.of(context).china,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('36');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_mongolia.webp'),
                  ),
                  Text(
                    S.of(context).mongolia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('37');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Container(),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_east_asia.webp'),
                  ),
                  Text(
                    S.of(context).eastern_asia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('38');
                },
              ),
              flex: 2,
            ),
            Expanded(
              child: Container(),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Asia tropical
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_asia_tropical.webp'),
        ),
        Text(
          S.of(context).asia_tropical,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(4);
      },
    ));
    if (_region == 4) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_indian_subcontinent.webp'),
                  ),
                  Text(
                    S.of(context).indian_subcontinent,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('40');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_indochina.webp'),
                  ),
                  Text(
                    S.of(context).indochina,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('41');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_malesia.webp'),
                  ),
                  Text(
                    S.of(context).malesia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('42');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_papuasia.webp'),
                  ),
                  Text(
                    S.of(context).papuasia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('43');
                },
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Australasia
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_australasia.webp'),
        ),
        Text(
          S.of(context).australasia,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(5);
      },
    ));
    if (_region == 5) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_australia.webp'),
                  ),
                  Text(
                    S.of(context).australia,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('50');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_new_zealand.webp'),
                  ),
                  Text(
                    S.of(context).new_zealand,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('51');
                },
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Pacific
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_pacific.webp'),
        ),
        Text(
          S.of(context).pacific,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(6);
      },
    ));
    if (_region == 6) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southwestern_pacific.webp'),
                  ),
                  Text(
                    S.of(context).southwestern_pacific,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('60');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_south_central_pacific.webp'),
                  ),
                  Text(
                    S.of(context).south_central_pacific,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('61');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northwestern_pacific.webp'),
                  ),
                  Text(
                    S.of(context).northwestern_pacific,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('62');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_north_central_pacific.webp'),
                  ),
                  Text(
                    S.of(context).north_central_pacific,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('63');
                },
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // North America
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_northern_america.webp'),
        ),
        Text(
          S.of(context).northern_america,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(7);
      },
    ));
    if (_region == 7) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_subarctic_america.webp'),
                  ),
                  Text(
                    S.of(context).subarctic_america,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('70');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_western_canada.webp'),
                  ),
                  Text(
                    S.of(context).western_canada,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('71');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_eastern_canada.webp'),
                  ),
                  Text(
                    S.of(context).eastern_canada,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('72');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northwestern_united_states.webp'),
                  ),
                  Text(
                    S.of(context).northwestern_usa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('73');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_north_central_united_states.webp'),
                  ),
                  Text(
                    S.of(context).north_central_usa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('74');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northeastern_united_states.webp'),
                  ),
                  Text(
                    S.of(context).northeastern_usa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('75');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southwestern_united_states.webp'),
                  ),
                  Text(
                    S.of(context).southwestern_usa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('76');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_south_central_united_states.webp'),
                  ),
                  Text(
                    S.of(context).south_central_usa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('77');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southeastern_united_states.webp'),
                  ),
                  Text(
                    S.of(context).southeastern_usa,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('78');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_mexico.webp'),
                  ),
                  Text(
                    S.of(context).mexico,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('79');
                },
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Pacific
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_southern_america.webp'),
        ),
        Text(
          S.of(context).southern_america,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _openRegion(8);
      },
    ));
    if (_region == 8) {
      regions.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_central_america.webp'),
                  ),
                  Text(
                    S.of(context).central_america,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('80');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_caribbean.webp'),
                  ),
                  Text(
                    S.of(context).caribbean,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('81');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_northern_south_america.webp'),
                  ),
                  Text(
                    S.of(context).northern_south_america,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('82');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_western_south_america.webp'),
                  ),
                  Text(
                    S.of(context).western_south_america,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('83');
                },
              ),
              flex: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_brazil.webp'),
                  ),
                  Text(
                    S.of(context).brazil,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('84');
                },
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(alignment: Alignment.center, children: [
                  Image(
                    image: AssetImage('res/images/wgsrpd_southern_south_america.webp'),
                  ),
                  Text(
                    S.of(context).southern_south_america,
                    style: _secondLevelTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ]),
                onPressed: () {
                  _navigate('85');
                },
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Antarctic
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(alignment: Alignment.center, children: [
        Image(
          image: AssetImage('res/images/wgsrpd_antarctic.webp'),
        ),
        Text(
          S.of(context).subantarctic_islands,
          style: _firstLevelTextStyle,
        ),
      ]),
      onPressed: () {
        _navigate('90');
      },
    ));

    regions.add(Container(
    height: 50.0,
    ));

    return regions;
  }
}
