import 'package:abherbs_flutter/detail/plant_detail.dart';
import 'package:abherbs_flutter/drawer.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/firebase_animated_index_list.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/utils.dart';
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
  Map<String, String> translationCache;

  @override
  void initState() {
    super.initState();

    _count = countsReference.child(getFilterKey(widget.filter)).once().then((DataSnapshot snapshot) {
      return snapshot.value;
    });

    translationCache = {};

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).list_info),
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
                    String name = snapshot.value['name'];
                    String family = snapshot.value['family'];

                    Locale myLocale = Localizations.localeOf(context);
                    Future<String> nameF = translationCache.containsKey(name)
                        ? new Future<String>(() {
                            return translationCache[name];
                          })
                        : translationsReference.child(myLocale.languageCode).child(name).child('label').once().then((DataSnapshot snapshot) {
                            if (snapshot.value != null) {
                              translationCache[name] = snapshot.value;
                              return snapshot.value;
                            } else {
                              return null;
                            }
                          });
                    Future<String> familyF = translationCache.containsKey(family)
                        ? new Future<String>(() {
                            return translationCache[family];
                          })
                        : translationsTaxonomyReference.child(myLocale.languageCode).child(family).once().then((DataSnapshot snapshot) {
                            if (snapshot.value != null && snapshot.value.length > 0) {
                              translationCache[family] = snapshot.value[0];
                              return snapshot.value[0];
                            } else {
                              return null;
                            }
                          });

                    return Card(
                      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        ListTile(
                          title: FutureBuilder<String>(
                              future: nameF,
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                String labelLocal = name;
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.data != null) {
                                    labelLocal = snapshot.data + ' / ' + name;
                                  }
                                }
                                return Text(labelLocal);
                              }),
                          subtitle: FutureBuilder<String>(
                              future: familyF,
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                String familyLocal = family;
                                if (snapshot.connectionState == ConnectionState.done) {
                                  if (snapshot.data != null) {
                                    familyLocal = snapshot.data + ' / ' + family;
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PlantDetail(myLocale, widget.onChangeLanguage, widget.filter, name)),
                                );
                              },
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
