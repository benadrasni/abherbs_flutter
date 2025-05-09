import 'dart:async';
import 'dart:math';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const families = [ "Acanthaceae", "Acoraceae", "Adoxaceae", "Alismataceae", "Amaranthaceae", "Amaryllidaceae", "Anacardiaceae", "Apiaceae", "Apocynaceae", "Aquifoliaceae", "Araceae", "Araliaceae",
  "Aristolochiaceae", "Asclepiadaceae", "Asparagaceae", "Asteraceae", "Balsaminaceae", "Berberidaceae", "Bignoniaceae", "Boraginaceae", "Brassicaceae", "Butomaceae", "Cactaceae", "Campanulaceae",
  "Cannabaceae", "Caprifoliaceae", "Caryophyllaceae", "Celastraceae", "Ceratophyllaceae", "Cistaceae", "Colchicaceae", "Commelinaceae", "Convolvulaceae", "Cornaceae", "Crassulaceae", "Cucurbitaceae",
  "Droseraceae", "Elaeagnaceae", "Equisetaceae", "Ericaceae", "Euphorbiaceae", "Fabaceae", "Fumariaceae", "Gelsemiaceae", "Gentianaceae", "Geraniaceae", "Grossulariaceae", "Haloragaceae",
  "Hamamelidaceae", "Hydrocharitaceae", "Hypericaceae", "Iridaceae", "Lamiaceae", "Lentibulariaceae", "Liliaceae", "Linaceae", "Loasaceae", "Lythraceae", "Magnoliaceae", "Malvaceae", "Martyniaceae",
  "Melanthiaceae", "Melastomataceae", "Menispermaceae", "Menyanthaceae", "Mimosaceae", "Montiaceae", "Nelumbonaceae", "Nymphaeaceae", "Oleaceae", "Onagraceae", "Orchidaceae", "Orobanchaceae",
  "Oxalidaceae", "Paeoniaceae", "Papaveraceae", "Passifloraceae", "Phytolaccaceae", "Plantaginaceae", "Plumbaginaceae", "Polemoniaceae", "Polygalaceae", "Polygonaceae", "Portulacaceae",
  "Potamogetonaceae", "Primulaceae", "Ranunculaceae", "Resedaceae", "Rhamnaceae", "Rosaceae", "Rubiaceae", "Rutaceae", "Salicaceae", "Santalaceae", "Sapindaceae", "Sarraceniaceae", "Saururaceae",
  "Saxifragaceae", "Scheuchzeriaceae", "Scrophulariaceae", "Solanaceae", "Thymelaeaceae", "Tiliaceae", "Typhaceae", "Ulmaceae", "Urticaceae", "Valerianaceae", "Verbenaceae", "Violaceae", "Vitaceae",
  "Nyctaginaceae", "Paulowniaceae", "Hypoxidaceae", "Myrtaceae", "Mazaceae", "Betulaceae", "Tropaeolaceae", "Hydrangeaceae", "Begoniaceae", "Zingiberaceae", "Alstroemeriaceae", "Asphodelaceae",
  "Cannaceae", "Platanaceae", "Theaceae", "Gesneriaceae", "Bromeliaceae", "Garryaceae", "Pontederiaceae", "Cyperaceae", "Staphyleaceae", "Strelitziaceae", "Goodeniaceae", "Buxaceae", "Caricaceae",
  "Moraceae", "Fagaceae", "Nartheciaceae", "Simaroubaceae", "Juglandaceae", "Cleomaceae", "Aizoaceae", "Nepenthaceae", "Linderniaceae", "Juncaceae", "Zygophyllaceae", "Pittosporaceae", "Clethraceae"];

class CustomListScreen extends StatefulWidget {
  final Locale myLocale;
  CustomListScreen(this.myLocale);

  @override
  _CustomListScreenState createState() => _CustomListScreenState();
}

class _CustomListScreenState extends State<CustomListScreen> {
  FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late StreamSubscription<firebase_auth.User?> _listener;
  late DateFormat _dateFormat;

  Future<void> _logCustomListOpenEvent(event) async {
    await _firebaseAnalytics.logEvent(name: 'custom_list_open', parameters: {"type" : event});
  }

  @override
  void initState() {
    super.initState();

    _listener = Auth.subscribe((firebase_auth.User? user) => setState(() {}));
    _dateFormat = DateFormat.yMMMMEEEEd(widget.myLocale.toString());
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle listTextStyle = TextStyle(
      fontSize: 18.0,
    );

    double newFlowersHeight = MediaQuery.of(context).size.height / 1.5;

    var _widgets = <Widget>[];
    _widgets.add(Card(
      child: ListTile(
        title: Text(
          S.of(context).favorite_title,
          style: listTextStyle,
        ),
        leading: Icon(
          Icons.favorite,
          color: Colors.red,
        ),
        trailing: FittedBox(
          fit: BoxFit.fill,
          child: FutureBuilder<int>(future: Future<int>(() {
            if (Auth.appUser != null) {
              return usersReference.child(Auth.appUser!.uid).child(firebaseAttributeFavorite).once().then((event) {
                if (event.snapshot.value != null) {
                  if (event.snapshot.value is List) {
                    int i = 0;
                    (event.snapshot.value as List).forEach((value) {
                      if (value != null) {
                        i++;
                      }
                    });
                    return i;
                  } else {
                    return (event.snapshot.value as List).length;
                  }
                }
                return 0;
              });
            }
            return 0;
          }), builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.active:
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              default:
                return Text(snapshot.data == null ? '' : snapshot.data.toString());
            }
          }),
        ),
        onTap: () {
          if (Auth.appUser != null) {
            _logCustomListOpenEvent("favorite");
            String path = '/' + firebaseUsers + '/' + Auth.appUser!.uid + '/' + firebaseAttributeFavorite;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlantList({}, S.of(context).favorite_empty, rootReference.child(path)), settings: RouteSettings(name: 'PlantList')),
            );
          } else {
            favoriteDialog(context, _key);
          }
        },
      ),
    ));

    _widgets.add(FutureBuilder<int>(
        future: listsCustomReference.child("by language").child(widget.myLocale.languageCode).once().then((event) {
          return event.snapshot.value == null ? 0 : 1;
        }),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == 1) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        S.of(context).common_lists,
                        style: listTextStyle,
                      ),
                      leading: Icon(
                        Icons.language,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: MyFirebaseAnimatedList(
                          shrinkWrap: true,
                          defaultChild: Center(child: CircularProgressIndicator()),
                          query: listsCustomReference.child("by language").child(widget.myLocale.languageCode),
                          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                            Random random = Random();

                            return FutureBuilder<List<String>>(
                                future: listsCustomReference.child("by language").child(widget.myLocale.languageCode).child(snapshot.key!).once().then((event) {
                                  var result = (event.snapshot.value as Map)[firebaseAttributeList]??[];
                                  int length = result is List ? result.fold(0, (t, value) => t + (value == null ? 0 : 1) ) : result.values.length;
                                  String icon = (event.snapshot.value as Map)["icon"]??families[random.nextInt(families.length-1)];

                                  return [length.toString(), icon];
                                }),
                                builder: (BuildContext context, AsyncSnapshot<List<String>> localSnapshot) {
                                  String count = "";
                                  String icon = "";
                                  if (localSnapshot.connectionState == ConnectionState.done && localSnapshot.data != null) {
                                    count = localSnapshot.data![0];
                                    icon = localSnapshot.data![1];

                                    return ListTile(
                                      title: Text(snapshot.key!),
                                      leading: getImage(
                                          storageFamilies + icon + defaultExtension,
                                          Container(
                                            width: 0.0,
                                            height: 0.0,
                                          ),
                                          width: 50.0,
                                          height: 50.0),
                                      trailing: Text(count),
                                      onTap: () {
                                        _logCustomListOpenEvent(widget.myLocale.languageCode + ": " + snapshot.key!);
                                        String path = '/' + firebaseListsCustom + '/by language/' + widget.myLocale.languageCode + '/' + snapshot.key! + '/' + firebaseAttributeList;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PlantList({}, "", rootReference.child(path)), settings: RouteSettings(name: 'PlantList')),
                                        );
                                      },
                                    );
                                  } else {
                                    return Container();
                                  }
                                });
                          }),
                    ),
                  ],
                ),
              );
            }
          }
          return Container();
        }));

    _widgets.add(Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(
              S.of(context).new_flowers,
              style: listTextStyle,
            ),
            leading: Icon(
              Icons.date_range,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            height: newFlowersHeight,
            child: MyFirebaseAnimatedList(
                shrinkWrap: true,
                defaultChild: Center(child: CircularProgressIndicator()),
                query: listsCustomReference.child("new").orderByChild("time"),
                itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                  Random random = Random();

                  return ListTile(
                    title: Text(_dateFormat.format(DateTime.parse(snapshot.key!))),
                    leading: getImage(
                        storageFamilies + families[random.nextInt(families.length-1)] + defaultExtension,
                        Container(
                          width: 0.0,
                          height: 0.0,
                        ),
                        width: 50.0,
                        height: 50.0),
                    trailing: FutureBuilder<int>(
                        future: listsCustomReference.child("new").child(snapshot.key!).child(firebaseAttributeList).once().then((event) {
                          var result = event.snapshot.value??[];
                          int length = result is List ? result.fold(0, (t, value) => t + (value == null ? 0 : 1) ) : (result as Map).values.length;
                          return length;
                        }),
                        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                          String count = "";
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (snapshot.data != null) {
                              count = snapshot.data.toString();
                            }
                          }
                          return Text(count);
                        }),
                    onTap: () {
                      _logCustomListOpenEvent("new: " + snapshot.key!);
                      String path = '/' + firebaseListsCustom + '/new/' + snapshot.key! + '/' + firebaseAttributeList;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PlantList({}, "", rootReference.child(path)), settings: RouteSettings(name: 'PlantList')),
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    ));

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).custom_lists),
      ),
      body: ListView(children: _widgets),
    );
  }
}
