import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';

class SettingMyFilter extends StatefulWidget {

  @override
  _SettingMyFilterState createState() => _SettingMyFilterState();
}

class _SettingMyFilterState extends State<SettingMyFilter> {
  List<String> _myFilter;

  void _setMyFilter(List<String> myFilter) {
    Prefs.setStringList(keyMyFilter, myFilter);
    Navigator.pop(context);
  }

  Widget _getBody(BuildContext context) {
    var regionWidgets = <Widget>[];

    return ListView(
      padding: EdgeInsets.all(5.0),
      children: regionWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).my_filter),
      ),
      body: _getBody(context),
    );
  }
}
