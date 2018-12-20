import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/generated/i18n.dart';

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

  void _openRegion(int region) {
    setState(() {
      _region = region == _region ? 0 : region;
    });
  }

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterDistribution] = value;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => getNextFilter(widget.onChangeLanguage, newFilter)),
    );
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterDistribution);
    _region = 0;

    _count = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).filter_distibution),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, _filter),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(5.0),
        children: _getRegions(),
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
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    return FloatingActionButton(
                      onPressed: () {},
                      child: Text(snapshot.data.toString()),
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
      fontSize: 25.0,
    );
    var _secondLevelTextStyle = TextStyle(
      fontSize: 20.0,
    );

    var regions = <Widget>[];
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_my_region.webp'),
            ),
            Text(S.of(context).my_region,
              style: _firstLevelTextStyle,
            ),
          ]),
      onPressed: () {

      },
    ));

    // Europe
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_europe.webp'),
            ),
            Text(S.of(context).europe,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northern_europe.webp'),
                      ),
                      Text(S.of(context).northern_europe,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_middle_europe.webp'),
                      ),
                      Text(S.of(context).middle_europe,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southwestern_europe.webp'),
                      ),
                      Text(S.of(context).southwestern_europe,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southeastern_europe.webp'),
                      ),
                      Text(S.of(context).southeastern_europe,
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
              child: Container(
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_eastern_europe.webp'),
                      ),
                      Text(S.of(context).eastern_europe,
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
              child: Container(
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Africa
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_africa.webp'),
            ),
            Text(S.of(context).africa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northern_africa.webp'),
                      ),
                      Text(S.of(context).northern_africa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_macaronesia.webp'),
                      ),
                      Text(S.of(context).macaronesia,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_west_tropical_africa.webp'),
                      ),
                      Text(S.of(context).west_tropical_africa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_central_tropical_africa.webp'),
                      ),
                      Text(S.of(context).west_central_tropical_africa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northeast_tropical_africa.webp'),
                      ),
                      Text(S.of(context).northeast_tropical_africa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_east_tropical_africa.webp'),
                      ),
                      Text(S.of(context).east_tropical_africa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_south_tropical_africa.webp'),
                      ),
                      Text(S.of(context).south_tropical_africa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southern_africa.webp'),
                      ),
                      Text(S.of(context).southern_africa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_middle_atlantic_ocean.webp'),
                      ),
                      Text(S.of(context).middle_atlantic_ocean,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_western_indian_ocean.webp'),
                      ),
                      Text(S.of(context).western_indian_ocean,
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
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_asia_temperate.webp'),
            ),
            Text(S.of(context).asia_temperate,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_siberia.webp'),
                      ),
                      Text(S.of(context).siberia,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_russian_far_east.webp'),
                      ),
                      Text(S.of(context).russian_far_east,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_middle_asia.webp'),
                      ),
                      Text(S.of(context).middle_asia,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_caucasus.webp'),
                      ),
                      Text(S.of(context).caucasus,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_western_asia.webp'),
                      ),
                      Text(S.of(context).western_asia,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_arabian_peninsula.webp'),
                      ),
                      Text(S.of(context).arabian_peninsula,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_china.webp'),
                      ),
                      Text(S.of(context).china,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_mongolia.webp'),
                      ),
                      Text(S.of(context).mongolia,
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
              child: Container(
              ),
              flex: 1,
            ),
            Expanded(
              child: FlatButton(
                padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_east_asia.webp'),
                      ),
                      Text(S.of(context).eastern_asia,
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
              child: Container(
              ),
              flex: 1,
            ),
          ],
        ),
      ]);
    }

    // Asia tropical
    regions.add(FlatButton(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_asia_tropical.webp'),
            ),
            Text(S.of(context).asia_tropical,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_indian_subcontinent.webp'),
                      ),
                      Text(S.of(context).indian_subcontinent,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_indochina.webp'),
                      ),
                      Text(S.of(context).indochina,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_malesia.webp'),
                      ),
                      Text(S.of(context).malesia,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_papuasia.webp'),
                      ),
                      Text(S.of(context).papuasia,
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
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_australasia.webp'),
            ),
            Text(S.of(context).australasia,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_australia.webp'),
                      ),
                      Text(S.of(context).australia,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_new_zealand.webp'),
                      ),
                      Text(S.of(context).new_zealand,
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
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_pacific.webp'),
            ),
            Text(S.of(context).pacific,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southwestern_pacific.webp'),
                      ),
                      Text(S.of(context).southwestern_pacific,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_south_central_pacific.webp'),
                      ),
                      Text(S.of(context).south_central_pacific,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northwestern_pacific.webp'),
                      ),
                      Text(S.of(context).northwestern_pacific,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_north_central_pacific.webp'),
                      ),
                      Text(S.of(context).north_central_pacific,
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
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_northern_america.webp'),
            ),
            Text(S.of(context).northern_america,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_subarctic_america.webp'),
                      ),
                      Text(S.of(context).subarctic_america,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_western_canada.webp'),
                      ),
                      Text(S.of(context).western_canada,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_eastern_canada.webp'),
                      ),
                      Text(S.of(context).eastern_canada,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northwestern_united_states.webp'),
                      ),
                      Text(S.of(context).northwestern_usa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_north_central_united_states.webp'),
                      ),
                      Text(S.of(context).north_central_usa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northeastern_united_states.webp'),
                      ),
                      Text(S.of(context).northeastern_usa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southwestern_united_states.webp'),
                      ),
                      Text(S.of(context).southwestern_usa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_south_central_united_states.webp'),
                      ),
                      Text(S.of(context).south_central_usa,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southeastern_united_states.webp'),
                      ),
                      Text(S.of(context).southeastern_usa,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_mexico.webp'),
                      ),
                      Text(S.of(context).mexico,
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
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_southern_america.webp'),
            ),
            Text(S.of(context).southern_america,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_central_america.webp'),
                      ),
                      Text(S.of(context).central_america,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_caribbean.webp'),
                      ),
                      Text(S.of(context).caribbean,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_northern_south_america.webp'),
                      ),
                      Text(S.of(context).northern_south_america,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_western_south_america.webp'),
                      ),
                      Text(S.of(context).western_south_america,
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
                padding: EdgeInsets.only(bottom: 10.0, right:5.0),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_brazil.webp'),
                      ),
                      Text(S.of(context).brazil,
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
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image(
                        image: AssetImage('res/images/wgsrpd_southern_south_america.webp'),
                      ),
                      Text(S.of(context).southern_south_america,
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
      padding: EdgeInsets.only(bottom: 50.0),
      child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              image: AssetImage('res/images/wgsrpd_antarctic.webp'),
            ),
            Text(S.of(context).subantarctic_islands,
              style: _firstLevelTextStyle,
            ),
          ]),
      onPressed: () {
        _navigate('90');
      },
    ));

    return regions;
  }
}
