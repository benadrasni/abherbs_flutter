import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class SettingMyRegion2 extends StatefulWidget {
  final int region;
  SettingMyRegion2(this.region);

  @override
  _SettingMyRegion2State createState() => _SettingMyRegion2State();
}

class _SettingMyRegion2State extends State<SettingMyRegion2> {
  void _setMyRegion(String myRegion) {
    Prefs.setString(keyMyRegion, myRegion);
    Navigator.pop(context);
    Navigator.pop(context);
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
                    _setMyRegion(items[2]);
                  },
                ),
              );
            }).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).my_region),
      ),
      body: _getBody(context),
    );
  }
}
