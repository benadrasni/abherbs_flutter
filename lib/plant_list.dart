import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/firebase_animated_index_list.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);
final listsReference = FirebaseDatabase.instance.reference().child(firebasePlantHeaders);
final keysReference = FirebaseDatabase.instance.reference().child(firebaseLists);
final translationsReference = FirebaseDatabase.instance.reference().child(firebaseTranslations);
final translationsTaxonomyReference = FirebaseDatabase.instance.reference().child(firebaseTranslationsTaxonomy);

class PlantList extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  PlantList(this.onChangeLanguage, this.filter);

  @override
  _PlantListState createState() => _PlantListState();
}

class _PlantListState extends State<PlantList> {
  Future<int> _count;

  @override
  void initState() {
    super.initState();

    _count = countsReference.child(getFilterKey(widget.filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).filter_color),
        ),
        drawer: AppDrawer(widget.onChangeLanguage, widget.filter, null),
        body: Container(
          child: Column(
            children: <Widget>[
              Flexible(
                child: FirebaseAnimatedIndexList(
                    query: listsReference,
                    keyQuery: keysReference.child(getFilterKey(widget.filter)),
                    itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                      String label = snapshot.value['name'];
                      String family = snapshot.value['family'];

                      Locale myLocale = Localizations.localeOf(context);
                      Future<DataSnapshot> labelF = translationsReference.child(myLocale.languageCode).child(label).child('label').once();
                      Future<DataSnapshot> familyF = translationsTaxonomyReference.child(myLocale.languageCode).child(family).once();

                      return Card(
                        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                          ListTile(
                            title: FutureBuilder<DataSnapshot>(
                                future: labelF,
                                builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
                                  String labelLocal = label;
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    if (snapshot.data.value != null) {
                                      labelLocal = snapshot.data.value + ' / ' + label;
                                    }
                                  }
                                  return Text(labelLocal);
                                }),
                            subtitle: FutureBuilder<DataSnapshot>(
                                future: familyF,
                                builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
                                  String familyLocal = family;
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    if (snapshot.data.value != null && snapshot.data.value.length > 0) {
                                      familyLocal = snapshot.data.value[0] + ' / ' + family;
                                    }
                                  }
                                  return Text(familyLocal);
                                }),
                            leading: Image.network(
                              storageEndpoit + storageFamilies + snapshot.value['family'] + defaultExtension,
                              width: 50.0,
                              height: 50.0,
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CircularProgressIndicator(),
                              FlatButton(
                                padding: EdgeInsets.all(10.0),
                                child: FadeInImage.assetNetwork(
                                  fit: BoxFit.scaleDown,
                                  placeholder: 'res/images/placeholder.webp',
                                  image: storageEndpoit + storagePhotos + snapshot.value['url'],
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ]),
                      );
                    }),
              ),
            ],
          ),
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
