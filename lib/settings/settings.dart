import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
//import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/settings/setting_my_region.dart';
import 'package:abherbs_flutter/settings/setting_pref_language.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  SettingsScreen(this.onChangeLanguage);

  @override
  _SettingsScreenState createState() => new _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<String> _prefLanguageF;
  String _prefLanguage;
  Future<String> _myRegionF;
  Future<bool> _alwaysMyRegionF;

  void _resetPrefLanguage() {
    setState(() {
      _prefLanguageF = Prefs.setString(keyPreferredLanguage, null).then((bool success) {
        widget.onChangeLanguage(null);
        return null;
      });
      _alwaysMyRegionF = Prefs.setBool(keyAlwaysMyRegion, false).then((success) {
        return false;
      });
    });
  }

  void _getPrefLanguage() {
    setState(() {
      _prefLanguageF = Prefs.getStringF(keyPreferredLanguage);
      _prefLanguageF.then((language) {
        if (language != _prefLanguage) {
          _prefLanguage = language;
          widget.onChangeLanguage(_prefLanguage);
        }
        return language;
      });
    });
  }

  void _setMyRegion(String region) {
    setState(() {
      _myRegionF = Prefs.setString(keyMyRegion, region).then((success) {
        return region == null ? "" : region;
      });
    });
  }

  void _setAlwaysMyRegion(bool alwaysMyRegion) {
    setState(() {
      _alwaysMyRegionF = Prefs.setBool(keyAlwaysMyRegion, alwaysMyRegion).then((success) {
        return alwaysMyRegion;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _prefLanguageF = Prefs.getStringF(keyPreferredLanguage);
    _prefLanguageF.then((language) {
      _prefLanguage = language;
    });
    _myRegionF = Prefs.getStringF(keyMyRegion);
    _alwaysMyRegionF = Prefs.getBoolF(keyAlwaysMyRegion);

    //Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle titleTextStyle = TextStyle(
      fontSize: 18.0,
    );
    TextStyle subtitleTextStyle = TextStyle(
      fontSize: 16.0,
    );

    var widgets = <Widget>[];
    widgets.add(ListTile(
      title: Text(
        S.of(context).pref_language,
        style: titleTextStyle,
      ),
      subtitle: FutureBuilder<String>(
          future: _prefLanguageF,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            var value = "";
            if (snapshot.connectionState == ConnectionState.done) {
              value = snapshot.data.isNotEmpty ? languages[snapshot.data] : "";
            }

            return Text(
              value,
              style: subtitleTextStyle,
            );
          }),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          if (_prefLanguage.isNotEmpty) {
            _resetPrefLanguage();
          }
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingPrefLanguage()),
        ).then((result) {
          _getPrefLanguage();
        });
      },
    ));
    widgets.add(ListTile(
      title: Text(
        S.of(context).my_region,
        style: titleTextStyle,
      ),
      subtitle: FutureBuilder<String>(
          future: _myRegionF,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            var value = "";
            if (snapshot.connectionState == ConnectionState.done) {
              value = snapshot.data.isNotEmpty ? getFilterDistributionValue(context, snapshot.data) : "";
            }
            return Text(
              value,
              style: subtitleTextStyle,
            );
          }),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          _setMyRegion(null);
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingMyRegion()),
        ).then((result) {
          setState(() {
            _myRegionF = Prefs.getStringF(keyMyRegion);
          });
        });
      },
    ));

    widgets.add(FutureBuilder<String>(
        future: _myRegionF,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data.isNotEmpty) {
            return ListTile(
              title: Text(
                S.of(context).always_my_region_title,
                style: titleTextStyle,
              ),
              subtitle: Text(
                S.of(context).always_my_region_subtitle,
                style: subtitleTextStyle,
              ),
              trailing: FutureBuilder<bool>(
                  future: _alwaysMyRegionF,
                  builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    bool alwaysMyRegion = false;
                    if (snapshot.connectionState == ConnectionState.done) {
                      alwaysMyRegion = snapshot.data;
                    }
                    return Switch(
                      value: alwaysMyRegion,
                      onChanged: (bool value) {
                        _setAlwaysMyRegion(value);
                      },
                    );
                  }),
            );
          } else {
            return Container(
              height: 50.0,
            );
          }
        }));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(10.0),
        children: widgets,
      ),
    );
  }
}
