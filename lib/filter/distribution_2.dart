import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/color.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/filter/habitat.dart';
import 'package:abherbs_flutter/filter/petal.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Distribution2 extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final int region;
  Distribution2(this.onChangeLanguage, this.filter, this.region);

  @override
  _Distribution2State createState() => _Distribution2State();
}

class _Distribution2State extends State<Distribution2> {
  Future<int> _count;
  GlobalKey<ScaffoldState> _key;

  void _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(widget.filter);
    newFilter[filterDistribution] = value;

    countsReference.child(getFilterKey(newFilter)).once().then((DataSnapshot snapshot) {
      if (snapshot.value != null && snapshot.value > 0) {
        Navigator.pushReplacement(context, getNextFilterRoute(context, widget.onChangeLanguage, newFilter));
      } else {
        Ads.hideBannerAd();
        _key.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).snack_no_flowers),
        ));
      }
    });
  }

  _setCount() {
    _count = countsReference.child(getFilterKey(widget.filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  Widget _getBody(BuildContext context) {
    var _secondLevelTextStyle = TextStyle(
      fontSize: 20.0,
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
            padding: const EdgeInsets.only(bottom: 50.0),
            mainAxisSpacing: 3.0,
            crossAxisSpacing: 3.0,
            children: subRegions.map((List<String> items) {
              return GridTile(
                child: FlatButton(
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
    _key = new GlobalKey<ScaffoldState>();

    _setCount();

    Ads.showBannerAd(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: new AppBar(
        title: new Text(S.of(context).filter_distribution),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, widget.filter, null),
      body: _getBody(context),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Image(
                image: AssetImage('res/images/color.png'),
                width: 25.0,
                height: 25.0,
              ),
              title: Text(S.of(context).filter_color)),
          BottomNavigationBarItem(
              icon: Image(
                image: AssetImage('res/images/habitat.png'),
                width: 25.0,
                height: 25.0,
              ),
              title: Text(S.of(context).filter_habitat)),
          BottomNavigationBarItem(
              icon: Image(
                image: AssetImage('res/images/petal.png'),
                width: 25.0,
                height: 25.0,
              ),
              title: Text(S.of(context).filter_petal)),
        ],
        fixedColor: Colors.grey,
        onTap: (index) {
          var route;
          var nextFilterAttribute;
          switch (index) {
            case 0:
              route = MaterialPageRoute(builder: (context) => Color(widget.onChangeLanguage, widget.filter));
              nextFilterAttribute = filterColor;
              break;
            case 1:
              route = MaterialPageRoute(builder: (context) => Habitat(widget.onChangeLanguage, widget.filter));
              nextFilterAttribute = filterHabitat;
              break;
            case 2:
              route = MaterialPageRoute(builder: (context) => Petal(widget.onChangeLanguage, widget.filter));
              nextFilterAttribute = filterPetal;
              break;
          }
          if (filterRoutes[nextFilterAttribute] != null) {
            Navigator.removeRoute(context, filterRoutes[nextFilterAttribute]);
          }
          filterRoutes[nextFilterAttribute] = route;
          Navigator.pushReplacement(context, route);
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
                          clearFilter(widget.filter, _setCount);
                        });
                      },
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PlantList(widget.onChangeLanguage, widget.filter)),
                          );
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
}
