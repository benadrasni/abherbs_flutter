import 'dart:async';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/settings/setting_my_filter.dart';
import 'package:abherbs_flutter/settings/setting_my_region.dart';
import 'package:abherbs_flutter/settings/setting_pref_language.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';
import 'package:abherbs_flutter/preferences.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  SettingsScreen(this.onChangeLanguage, this.filter);

  @override
  _SettingsScreenState createState() => new _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<String> _prefLanguageF;
  String _prefLanguage;
  Future<String> _myRegionF;
  Future<bool> _alwaysMyRegionF;
  Future<List<String>> _myFilterF;

  void _resetPrefLanguage() {
    Prefs.setString(keyPreferredLanguage, null).then((bool success) {
      Navigator.pop(context);
      widget.onChangeLanguage('');
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
      if (region == null) {
        _alwaysMyRegionF = Prefs.setBool(keyAlwaysMyRegion, false).then((success) {
          return false;
        });
      }
    });
  }

  void _setAlwaysMyRegion(bool alwaysMyRegion) {
    setState(() {
      _alwaysMyRegionF = Prefs.setBool(keyAlwaysMyRegion, alwaysMyRegion).then((success) {
        return alwaysMyRegion;
      });
    });
  }

  void _setMyFilter(List<String> filter) {
    setState(() {
      _myFilterF = Prefs.setStringList(keyMyFilter, filter).then((success) {
        return filter == null ? filterAttributes : filter;
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
    _alwaysMyRegionF = Prefs.getBoolF(keyAlwaysMyRegion, false);
    _myFilterF = Prefs.getStringListF(keyMyFilter, filterAttributes);

    Ads.hideBannerAd();
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

    // preferred language
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

    // my region
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

    // always add my region
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
              height: 0.0,
            );
          }
        }));

    // my filter
    if (Purchases.isCustomFilter()) {
      widgets.add(ListTile(
        title: Text(
          S
              .of(context)
              .my_filter,
          style: titleTextStyle,
        ),
        subtitle: FutureBuilder<List<String>>(
            future: _myFilterF,
            builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              var value = "";
              if (snapshot.connectionState == ConnectionState.done) {
                value = snapshot.data
                    .map((item) {
                  return getFilterText(context, item);
                })
                    .toList()
                    .join(', ');
              }
              return Text(
                value,
                style: subtitleTextStyle,
              );
            }),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _setMyFilter(null);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingMyFilter(widget.filter)),
          ).then((result) {
            setState(() {
              _myFilterF = Prefs.getStringListF(keyMyFilter, filterAttributes).then((myFilter) {
                Preferences.myFilterAttributes = myFilter;
                return myFilter;
              });
            });
          });
        },
      ));
    }

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
