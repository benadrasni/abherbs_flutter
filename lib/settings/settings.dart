import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/setting_my_filter.dart';
import 'package:abherbs_flutter/settings/setting_my_region.dart';
import 'package:abherbs_flutter/settings/setting_offline.dart';
import 'package:abherbs_flutter/settings/setting_pref_language.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  SettingsScreen(this.onChangeLanguage, this.filter);

  @override
  _SettingsScreenState createState() => new _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  FirebaseAnalytics _firebaseAnalytics;
  Future<String> _prefLanguageF;
  String _prefLanguage;
  bool _downloadFinished;
  Future<String> _myRegionF;
  Future<bool> _alwaysMyRegionF;
  Future<List<String>> _myFilterF;
  Future<bool> _offlineF;
  Future<bool> _scaleDownPhotosF;

  void onDownloadFinished(bool result) {
    setState(() {
      _downloadFinished = result;
    });
  }

  void _resetPrefLanguage() {
    Prefs.setString(keyPreferredLanguage, null).then((bool success) {
      _logPrefLanguageEvent('default');
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
          _logPrefLanguageEvent(language);
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

  void _setOffline(bool offline) {
    Offline.onChange(offline);
    if (offline) {
      _offlineDownloadDialog();
      setState(() {
        _offlineF = Prefs.setBool(keyOffline, offline).then((success) {
          return offline;
        });
      });
    } else {
      _offlineDeleteDialog();
    }
  }

  void _setMyFilter(List<String> filter) {
    setState(() {
      _myFilterF = Prefs.setStringList(keyMyFilter, filter).then((success) {
        Preferences.myFilterAttributes = filter == null ? filterAttributes : filter;
        return Preferences.myFilterAttributes;
      });
    });
  }

  void _setScaleDownPhotos(bool scaleDownPhotos) {
    setState(() {
      _scaleDownPhotosF = Prefs.setBool(keyScaleDownPhotos, scaleDownPhotos).then((success) {
        return scaleDownPhotos;
      });
    });
  }

  Future<void> _offlineDownloadDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SettingOffline(this.onDownloadFinished);
      },
    );
  }

  Future<void> _offlineDeleteDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).offline_title),
          content: Text(S.of(context).offline_delete_message),
          actions: <Widget>[
            FlatButton(
              child: Text(S.of(context).yes.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _offlineF = Prefs.setBool(keyOffline, false).then((success) {
                    return false;
                  });
                });
                Offline.delete();
              },
            ),
            FlatButton(
              child: Text(S.of(context).no.toUpperCase(), style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logPrefLanguageEvent(String language) async {
    await _firebaseAnalytics.logEvent(name: 'setting', parameters: {
      'type': 'preffered_language',
      'language': language
    });
  }

  Future<void> _logMyRegionEvent(String region) async {
    await _firebaseAnalytics.logEvent(name: 'setting', parameters: {
      'type': 'my_region',
      'region': region
    });
  }

  Future<void> _logMyFilterEvent(String filter) async {
    await _firebaseAnalytics.logEvent(name: 'setting', parameters: {
      'type': 'my_filter',
      'region': filter
    });
  }

  @override
  void initState() {
    super.initState();
    _firebaseAnalytics = FirebaseAnalytics();
    _prefLanguageF = Prefs.getStringF(keyPreferredLanguage);
    _prefLanguageF.then((language) {
      _prefLanguage = language;
    });
    _myRegionF = Prefs.getStringF(keyMyRegion);
    _alwaysMyRegionF = Prefs.getBoolF(keyAlwaysMyRegion, false);
    _myFilterF = Prefs.getStringListF(keyMyFilter, filterAttributes);
    _offlineF = Prefs.getBoolF(keyOffline, false);
    _downloadFinished = Offline.downloadFinished;
    _scaleDownPhotosF = Prefs.getBoolF(keyScaleDownPhotos, false);
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
            _myRegionF = Prefs.getStringF(keyMyRegion).then((value) {
              _logMyRegionEvent(value);
              return value;
            });
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
          S.of(context).my_filter,
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
                _logMyFilterEvent(myFilter.join(', '));
                return myFilter;
              });
            });
          });
        },
      ));
    }

    // offline
    if (Purchases.isOffline()) {
      widgets.add(FutureBuilder<bool>(
          future: _offlineF,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            return ListTile(
              title: snapshot.data == null || !snapshot.data || _downloadFinished
                  ? Text(
                      S.of(context).offline_title,
                      style: titleTextStyle,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).offline_title,
                          style: titleTextStyle,
                        ),
                        RaisedButton(
                          color: Theme.of(context).accentColor,
                          child: Text(S.of(context).offline_download),
                          onPressed: () {
                            _offlineDownloadDialog();
                          },
                        ),
                      ],
                    ),
              subtitle: Text(
                S.of(context).offline_subtitle,
                style: subtitleTextStyle,
              ),
              trailing: Switch(
                value: snapshot.data ?? false,
                onChanged: (bool value) {
                  _setOffline(value);
                },
              ),
              onTap: () {},
            );
          }));
    }

    // scale down observation's photos
    if (Purchases.isObservations()) {
      widgets.add(ListTile(
          title: Text(S.of(context).scale_down_photos_title,
            style: titleTextStyle,
          ),
          subtitle: Text(
            S.of(context).scale_down_photos_subtitle,
            style: subtitleTextStyle,
          ),
          trailing: FutureBuilder<bool>(
              future: _scaleDownPhotosF,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                bool scaleDownPhotos = false;
                if (snapshot.connectionState == ConnectionState.done) {
                  scaleDownPhotos = snapshot.data;
                }
                return Switch(
                  value: scaleDownPhotos,
                  onChanged: (bool value) {
                    _setScaleDownPhotos(value);
                  },
                );
              }),
        )
      );
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
