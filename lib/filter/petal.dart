import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class Petal extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  Petal(this.onChangeLanguage, this.filter);

  @override
  _PetalState createState() => _PetalState();
}

class _PetalState extends State<Petal> {
  Future<int> _count;
  Map<String, String> _filter;

  _navigate(String value) {
    var newFilter = new Map<String, String>();
    newFilter.addAll(_filter);
    newFilter[filterPetal] = value;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => getNextFilter(widget.onChangeLanguage, newFilter)),
    );
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
    _filter.remove(filterPetal);

    _count = countsReference.child(getFilterKey(_filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    var _defaultTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 22.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).filter_petal),
      ),
      drawer: AppDrawer(widget.onChangeLanguage, _filter, null),
      body: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(5.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, right: 5.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      S.of(context).petal_4,
                      style: _defaultTextStyle,
                    ),
                    Image(
                      image: AssetImage('res/images/nop_4.webp'),
                    ),
                  ]),
                  onPressed: () {
                    _navigate('1');
                  },
                ),
                flex: 1,
              ),
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      S.of(context).petal_5,
                      style: _defaultTextStyle,
                    ),
                    Image(
                      image: AssetImage('res/images/nop_5.webp'),
                    ),
                  ]),
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      S.of(context).petal_many,
                      style: _defaultTextStyle,
                    ),
                    Image(
                      image: AssetImage('res/images/nop_many.webp'),
                    ),
                  ]),
                  onPressed: () {
                    _navigate('3');
                  },
                ),
                flex: 1,
              ),
              Expanded(
                child: FlatButton(
                  padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      S.of(context).petal_zygomorphic,
                      style: _defaultTextStyle,
                    ),
                    Image(
                      image: AssetImage('res/images/nop_zygomorphic.webp'),
                    ),
                  ]),
                  onPressed: () {
                    _navigate('4');
                  },
                ),
                flex: 1,
              ),
            ],
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
