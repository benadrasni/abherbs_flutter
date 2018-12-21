import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/settings/setting_my_region.dart';
import 'package:abherbs_flutter/settings/setting_pref_language.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  Settings(this.onChangeLanguage);

  @override
  _SettingsState createState() => new _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<String> _prefLanguageF;
  String _prefLanguage;
  Future<String> _myRegionF;

  void _resetPrefLanguage() {
    setState(() {
      _prefLanguageF = Prefs.setString(keyPreferredLanguage, null).then((bool success) {
        widget.onChangeLanguage(null);
        return null;
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

  @override
  void initState() {
    super.initState();
    _prefLanguageF = Prefs.getStringF(keyPreferredLanguage);
    _prefLanguageF.then((language) {
      _prefLanguage = language;
    });
    _myRegionF = Prefs.getStringF(keyMyRegion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: ListView(shrinkWrap: true, padding: const EdgeInsets.all(10.0), children: [
        ListTile(
          title: Text(S.of(context).pref_language,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              )),
          subtitle: FutureBuilder<String>(
              future: _prefLanguageF,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                var value = "";
                if (snapshot.connectionState == ConnectionState.done) {
                  value = snapshot.data.isNotEmpty ? languages[snapshot.data] : "";
                }

                return Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
                );
              }),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _resetPrefLanguage();
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
        ),
        ListTile(
          title: Text(
            S.of(context).my_region,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
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
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
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
        ),
      ]),
    );
  }
}
