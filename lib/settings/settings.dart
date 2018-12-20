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
  Future<String> _myRegionF;

  void _changePrefLanguage(String language) {
    setState(() {
      _prefLanguageF = Prefs.setString(keyPreferredLanguage, language).then((bool success) {
        widget.onChangeLanguage(language);
        return language == null ? "" : language;
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
              _changePrefLanguage(null);
            },
          ),
//          subtitle: FutureBuilder<String>(
//              future: _prefLanguageF,
//              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
//                String langCode = snapshot.data;
//                if (langCode != null && langCode.isEmpty) {
//                  langCode = null;
//                }
//
//                switch (snapshot.connectionState) {
//                  case ConnectionState.waiting:
//                    return const CircularProgressIndicator();
//                  default:
//                    return Row(children: [
//                      Container(
//                          child: DropdownButton<String>(
//                        value: langCode,
//                        hint: Text(S.of(context).default_language),
//                        items: languages.keys.map((String value) {
//                          return DropdownMenuItem<String>(
//                            value: value,
//                            child: Text(languages[value]),
//                          );
//                        }).toList(),
//                        onChanged: (newVal) {
//                          _changePrefLanguage(newVal);
//                        },
//                      )),
//                      IconButton(
//                        icon: Icon(Icons.delete),
//                        onPressed: langCode == null ? null : () { _changePrefLanguage(null); },
//                      ),
//                    ]);
//                }
//              }),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingPrefLanguage()),
            ).then((result) {
              setState(() {
                _prefLanguageF = Prefs.getStringF(keyPreferredLanguage);
              });
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
