import 'dart:async';

import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:flutter/material.dart';

class SettingMyFilter extends StatefulWidget {
  final Map<String, String> filter;
  SettingMyFilter(this.filter);

  @override
  _SettingMyFilterState createState() => _SettingMyFilterState();
}

class _SettingMyFilterState extends State<SettingMyFilter> {
  Future<List<String>> _myFilterF;

  Widget _getBody(BuildContext context, List<String> myFilter) {
    const TextStyle filterTextStyle = TextStyle(fontSize: 20.0);
    var filterWidgets = <Widget>[];

    for (String item in myFilter) {
      filterWidgets.add(Container(
          padding: EdgeInsets.all(10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              getFilterText(context, item),
              style: filterTextStyle,
            ),
            Row(
              children: [
                item == myFilter.first
                    ? Container(
                        width: 50.0,
                      )
                    : IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () {
                          var newFilter = <String>[];
                          for (var i = 0; i < myFilter.length; i++) {
                            if (i + 1 == myFilter.indexOf(item)) {
                              newFilter.add(myFilter[i + 1]);
                            } else if (i == myFilter.indexOf(item)) {
                              newFilter.add(myFilter[i - 1]);
                            } else {
                              newFilter.add(myFilter[i]);
                            }
                          }
                          setState(() {
                            _myFilterF = Prefs.setStringList(keyMyFilter, newFilter).then((success) {
                              return newFilter;
                            });
                          });
                        },
                      ),
                item == myFilter.last
                    ? Container(
                        width: 50.0,
                      )
                    : IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          var newFilter = <String>[];
                          for (var i = 0; i < myFilter.length; i++) {
                            if (i == myFilter.indexOf(item)) {
                              newFilter.add(myFilter[i + 1]);
                            } else if (i == myFilter.indexOf(item) + 1) {
                              newFilter.add(myFilter[i - 1]);
                            } else {
                              newFilter.add(myFilter[i]);
                            }
                          }
                          setState(() {
                            _myFilterF = Prefs.setStringList(keyMyFilter, newFilter).then((success) {
                              return newFilter;
                            });
                          });
                        },
                      ),
                myFilter.length == minFilterAttributes
                    ? Container(
                        width: 50.0,
                      )
                    : IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          var newFilter = <String>[];
                          for (var i = 0; i < myFilter.length; i++) {
                            if (i != myFilter.indexOf(item)) {
                              newFilter.add(myFilter[i]);
                            }
                          }

                          // delete filter attribute from the filter
                          widget.filter.remove(item);
                          // delete filter attribute from the navigator
                          if (filterRoutes[item] != null && filterRoutes[item].isActive && context != null) {
                            Navigator.removeRoute(context, filterRoutes[item]);
                            if (item == filterDistribution && filterRoutes[filterDistribution2] != null && filterRoutes[filterDistribution2].isActive) {
                              Navigator.removeRoute(context, filterRoutes[filterDistribution2]);
                            }
                          }

                          setState(() {
                            _myFilterF = Prefs.setStringList(keyMyFilter, newFilter).then((success) {
                              return newFilter;
                            });
                          });
                        },
                      ),
              ],
            ),
          ])));
    }

    filterWidgets.add(Container(
      height: 5.0,
      color: Theme.of(context).buttonColor,
    ));

    for (String item in filterAttributes) {
      if (myFilter.indexOf(item) == -1)
        filterWidgets.add(Container(
            padding: EdgeInsets.all(10.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                getFilterText(context, item),
                style: filterTextStyle,
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  List<String> newFilter = List.from(myFilter);
                  newFilter.add(item);
                  setState(() {
                    _myFilterF = Prefs.setStringList(keyMyFilter, newFilter).then((success) {
                      return newFilter;
                    });
                  });
                },
              ),
            ])));
    }

    return ListView(
      padding: EdgeInsets.all(10.0),
      children: filterWidgets,
    );
  }

  @override
  void initState() {
    super.initState();
    _myFilterF = Prefs.getStringListF(keyMyFilter, filterAttributes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).my_filter),
      ),
      body: FutureBuilder<List<String>>(
          future: _myFilterF,
          builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                return _getBody(context, snapshot.data);
              default:
                return Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Center(
                    child: const CircularProgressIndicator(),
                  ),
                );
            }
          }),
    );
  }
}
