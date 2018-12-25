import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Color extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  Color(this.onChangeLanguage, this.filter);

  @override
  _ColorState createState() => _ColorState();
}

class _ColorState extends State<Color> {
  Future<int> _count;
  Map<String, String> _filter;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterColor] = value;
    Navigator.push(context, getNextFilterRoute(context, widget.onChangeLanguage, newFilter));
  }

  _setCount() {
    _count = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterColor);

    _setCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).filter_color),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, _filter, null),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //shrinkWrap: true,
        //padding: EdgeInsets.all(5.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                  child: Image(
                    image: AssetImage('res/images/white.webp'),
                  ),
                  onPressed: () {
                    _navigate('1');
                  },
                ),
                flex: 1,
              ),
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                  child: Image(
                    image: AssetImage('res/images/yellow.webp'),
                  ),
                  onPressed: () {
                    _navigate('2');
                  },
                ),
                flex: 1,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                  child: Image(
                    image: AssetImage('res/images/red.webp'),
                  ),
                  onPressed: () {
                    _navigate('3');
                  },
                ),
                flex: 1,
              ),
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                  child: Image(
                    image: AssetImage('res/images/blue.webp'),
                  ),
                  onPressed: () {
                    _navigate('4');
                  },
                ),
                flex: 1,
              ),
            ],
          ),
          FlatButton(
            child: Image(
              image: AssetImage('res/images/green.webp'),
            ),
            onPressed: () {
              _navigate('5');
            },
          ),
          Container(
            height: 50.0,
          ),
        ],
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.only(bottom: 50.0),
        height: 120.0,
        width: 70.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FutureBuilder<int>(
              future: _count,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  default:
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _filter.clear();
                          _setCount();
                        });
                      },
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlantList(widget.onChangeLanguage, _filter)),
                          );
                        },
                        child: Text(snapshot.data.toString()),
                      ),
                    );
                }
              }),
        ),
      ),
    );
  }
}
