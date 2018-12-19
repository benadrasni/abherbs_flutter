import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/generated/i18n.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class ColorOfFlower extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  ColorOfFlower(this.onChangeLanguage, this.filter);

  @override
  _ColorOfFlowerState createState() => _ColorOfFlowerState();
}

class _ColorOfFlowerState extends State<ColorOfFlower> {
  Future<int> _count;
  Map<String, String> _filter;

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterColorOfFlower);
    _count = countsReference.child('___').once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).color_of_flower),
      ),
      drawer: AppDrawer(widget.onChangeLanguage),
      body: new Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              new Expanded(
                child: new Container(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 15.0, bottom: 5.0),
                  child: Image(
                    image: AssetImage('res/images/white.webp'),
                  ),
                ),
                flex: 1,
              ),
              new Expanded(
                child: new Container(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 15.0, bottom: 5.0),
                  child: Image(
                    image: AssetImage('res/images/yellow.webp'),
                  ),
                ),
                flex: 1,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              new Expanded(
                child: new Container(
                  padding: EdgeInsets.all(5.0),
                  child: Image(
                    image: AssetImage('res/images/red.webp'),
                  ),
                ),
                flex: 1,
              ),
              new Expanded(
                child: new Container(
                  padding: EdgeInsets.all(5.0),
                  child: Image(
                    image: AssetImage('res/images/blue.webp'),
                  ),
                ),
                flex: 1,
              ),
            ],
          ),
          new Container(
            padding: EdgeInsets.all(5.0),
            child: Image(
              image: AssetImage('res/images/green.webp'),
            ),
          ),
        ],
      ),
      floatingActionButton: new Container(
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
                    return FloatingActionButton(
                      onPressed: () {},
                      child: Text(snapshot.data.toString()),
                    );
                }
              }),
        ),
      ),
    );
  }
}