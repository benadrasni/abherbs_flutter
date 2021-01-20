import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:flutter/material.dart';

class SettingMyFilter extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  SettingMyFilter(this.onChangeLanguage, this.filter);

  @override
  _SettingMyFilterState createState() => _SettingMyFilterState();
}

class _SettingMyFilterState extends State<SettingMyFilter> {
  List<String> _myFilter;

  Widget _getBody(BuildContext context, List<String> myFilter) {
    const TextStyle filterTextStyle = TextStyle(fontSize: 20.0);
    var filterWidgets = <Widget>[];

    if (myFilter != null) {
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
                        _myFilter = newFilter;
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
                        _myFilter = newFilter;
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

                      setState(() {
                        _myFilter = newFilter;
                      });
                    },
                  ),
                ],
              ),
            ])));
      }
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
                    _myFilter = newFilter;
                  });
                },
              ),
            ])));
    }

    filterWidgets.add(Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      FlatButton(
        color: Colors.lightBlueAccent,
        child: Text(S.of(context).apply,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            )),
        onPressed: () {
          Prefs.setStringList(keyMyFilter, _myFilter).then((success) {
            Prefs.getStringF(keyPreferredLanguage).then((language) {
              widget.onChangeLanguage(language);
            });
          });
          Navigator.pop(context);
        },
      ),
      FlatButton(
        color: Colors.lightBlueAccent,
        child: Text(S.of(context).cancel,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            )),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ]));

    return ListView(
      padding: EdgeInsets.all(10.0),
      children: filterWidgets,
    );
  }

  @override
  void initState() {
    super.initState();
    Prefs.getStringListF(keyMyFilter, filterAttributes).then((myFilter) {
      setState(() {
        _myFilter = myFilter;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).my_filter),
      ),
      body: _getBody(context, _myFilter),
    );
  }
}
