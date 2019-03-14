import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/settings/setting_my_region_2.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class SettingMyRegion extends StatefulWidget {
  @override
  _SettingMyRegionState createState() => _SettingMyRegionState();
}

class _SettingMyRegionState extends State<SettingMyRegion> {
  void _openRegion(String region) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingMyRegion2(int.parse(region))));
  }

  void _setMyRegion(String myRegion) {
    Prefs.setString(keyMyRegion, myRegion);
    Navigator.pop(context);
  }

  Widget _getBody(BuildContext context) {
    var _firstLevelTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
    );

    var regions = <List<String>>[];
    regions.add([S.of(context).europe, 'res/images/wgsrpd_europe.webp', '1']);
    regions.add([S.of(context).africa, 'res/images/wgsrpd_africa.webp', '2']);
    regions.add([S.of(context).asia_temperate, 'res/images/wgsrpd_asia_temperate.webp', '3']);
    regions.add([S.of(context).asia_tropical, 'res/images/wgsrpd_asia_tropical.webp', '4']);
    regions.add([S.of(context).australasia, 'res/images/wgsrpd_australasia.webp', '5']);
    regions.add([S.of(context).pacific, 'res/images/wgsrpd_pacific.webp', '6']);
    regions.add([S.of(context).northern_america, 'res/images/wgsrpd_northern_america.webp', '7']);
    regions.add([S.of(context).southern_america, 'res/images/wgsrpd_southern_america.webp', '8']);

    var regionWidgets = <Widget>[];
    regionWidgets.addAll(regions.map((List<String> items) {
      return FlatButton(
        padding: EdgeInsets.only(bottom: 5.0),
        child: Stack(alignment: Alignment.center, children: [
          Image(
            image: AssetImage(items[1]),
          ),
          Text(
            items[0],
            style: _firstLevelTextStyle,
          ),
        ]),
        onPressed: () {
          _openRegion(items[2]);
        },
      );
    }).toList());

    regionWidgets.add(FlatButton(
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
        _setMyRegion('90');
      },
    ));

    return ListView(
      padding: EdgeInsets.all(5.0),
      children: regionWidgets,
    );
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
