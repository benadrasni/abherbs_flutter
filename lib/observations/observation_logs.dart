import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/purchase/subscription.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import 'observation_edit.dart';
import 'observations_map.dart';

class ObservationLogs extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  ObservationLogs(this.currentUser, this.myLocale, this.onChangeLanguage);

  @override
  _ObservationLogsState createState() => _ObservationLogsState();
}

class _ObservationLogsState extends State<ObservationLogs> {
  GlobalKey<ScaffoldState> _key;
  DateFormat _dateFormat;
  Future<DataSnapshot> _privateStatsF;
  Future<DataSnapshot> _publicStatsF;

  @override
  void initState() {
    super.initState();
    _key = new GlobalKey<ScaffoldState>();
    _dateFormat = DateFormat.yMMMMEEEEd(widget.myLocale.toString()).add_jm();

    _privateStatsF = privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsStats).once();
    _publicStatsF = publicObservationsReference.child(firebaseObservationsStats).once();
  }

  Widget getItems(Map<dynamic, dynamic> observations) {
    var items = observations.keys.where((x) => x != firebaseAttributeTime).map((id) {
      return FutureBuilder<Observation>(
          future: privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).child(id.toString()).once().then((snapshot) {
            var observation = Observation.fromJson(snapshot.key, snapshot.value);
            observation.uploadStatus = observations[id][firebaseAttributeStatus];
            return observation;
          }),
          builder: (BuildContext context, AsyncSnapshot<Observation> snapshot) {
            if (snapshot.data != null) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  return GestureDetector(
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(snapshot.data.plant),
                          Text(_dateFormat.format(snapshot.data.date)),
                        ],
                      ),
                      trailing: snapshot.data.uploadStatus == firebaseValueSuccess ? Icon(Icons.done) : Icon(Icons.error),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ObservationEdit(widget.currentUser, Localizations.localeOf(context), widget.onChangeLanguage, snapshot.data),
                            settings: RouteSettings(name: 'ObservationEdit')),
                      );
                    },
                  );
                default:
                  return Container(width: 0.0, height: 0.0);
              }
            }
            return Container(width: 0.0, height: 0.0);
          });
    }).toList();

    return Container(
      child: Column(children: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var self = this;
    var mainContext = context;

    TextStyle listTextStyle = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
    double uploadsHeight = MediaQuery.of(context).size.height / 2;
    double mapWidth = MediaQuery.of(context).size.width;
    double mapHeight = 100.0;

    var _widgets = <Widget>[];
    _widgets.add(Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text(
              S.of(context).observation_private,
              style: listTextStyle,
            ),
          ),
          FutureBuilder<DataSnapshot>(
              future: _privateStatsF,
              builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    if (snapshot.data.value == null) {
                      return ListTile(
                        title: Center(child: Text(S.of(context).observation_empty)),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(S.of(context).observation_count),
                                Text(S.of(context).observation_distinct_flowers),
                              ],
                            ),
                            leading: CircleAvatar(
                              child: Text(snapshot.data.value['count'].toString()),
                            ),
                            trailing: CircleAvatar(
                              child: Text(snapshot.data.value['distinctFlowers'].toString()),
                            ),
                          ),
                          const Divider(
                            color: Colors.blue,
                            height: 20,
                            thickness: 2,
                            indent: 30,
                            endIndent: 30,
                          ),
                          Container(
                            child: Text(S.of(context).observation_first),
                            alignment: Alignment.center,
                          ),
                          ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snapshot.data.value['firstFlower']),
                                Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(snapshot.data.value['firstDate']))),
                              ],
                            ),
                            leading: Icon(Icons.local_florist),
                            onTap: () {
                              goToDetail(self, mainContext, widget.myLocale, snapshot.data.value['firstFlower'], widget.onChangeLanguage, {});
                            },
                          ),
                          const Divider(
                            color: Colors.blue,
                            height: 20,
                            thickness: 2,
                            indent: 30,
                            endIndent: 30,
                          ),
                          Container(
                            child: Text(S.of(context).observation_last),
                            alignment: Alignment.center,
                          ),
                          ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snapshot.data.value['lastFlower']),
                                Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(snapshot.data.value['lastDate']))),
                              ],
                            ),
                            leading: Icon(Icons.local_florist),
                            onTap: () {
                              goToDetail(self, mainContext, widget.myLocale, snapshot.data.value['lastFlower'], widget.onChangeLanguage, {});
                            },
                          ),
                          const Divider(
                            color: Colors.blue,
                            height: 20,
                            thickness: 2,
                            indent: 30,
                            endIndent: 30,
                          ),
                          Container(
                            child: Text(S.of(context).observation_most),
                            alignment: Alignment.center,
                          ),
                          ListTile(
                            title: Text(snapshot.data.value['mostObserved']),
                            leading: Icon(Icons.local_florist),
                            trailing: CircleAvatar(
                              child: Text(snapshot.data.value['mostObservedCount'].toString()),
                            ),
                            onTap: () {
                              goToDetail(self, mainContext, widget.myLocale, snapshot.data.value['mostObserved'], widget.onChangeLanguage, {});
                            },
                          ),
                        ],
                      ),
                    );
                  default:
                    return Container(width: 0.0, height: 0.0);
                }
              })
        ],
      ),
    ));

    _widgets.add(FutureBuilder<List<dynamic>>(
        future: privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).once().then((snapshot) {
          List<dynamic> result = [];
          Map<MarkerId, Marker> markers = {};
          MarkerId newestMarker;
          int order = 0;
          if (snapshot.value != null && snapshot.value.keys.length > 0) {
            for (Map<dynamic, dynamic> item in snapshot.value.values) {
              var markerId = MarkerId(item['id']);
              if (item['order'] != null && order > item['order']) {
                order = item['order'];
                newestMarker = markerId;
              }
              markers[markerId] = Marker(
                markerId: markerId,
                //draggable: true,
                position: LatLng(
                  item['latitude'] ?? 0.0,
                  item['longitude'] ?? 0.0,
                ),
              );
            }
            result.add(newestMarker);
            result.add(markers);
          }

          return result;
        }),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          Widget result = Container(width: 0.0, height: 0.0);
          if (snapshot.connectionState == ConnectionState.done && snapshot.data.isNotEmpty) {
            result = FlatButton(
              padding: EdgeInsets.all(5.0),
              child: CachedNetworkImage(
                fit: BoxFit.contain,
                width: mapWidth,
                height: mapHeight,
                placeholder: (context, url) => Container(
                  width: mapWidth,
                  height: mapHeight,
                ),
                imageUrl: getMapImageUrl(snapshot.data[1][snapshot.data[0]].position.latitude, snapshot.data[1][snapshot.data[0]].position.longitude, mapWidth, mapHeight),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ObservationsMap(snapshot.data[0], snapshot.data[1]), settings: RouteSettings(name: 'ObservationsMap')),
                );
              },
            );
          }
          return result;
        }));

    _widgets.add(Card(
      child: FutureBuilder<List<DataSnapshot>>(
        future: Future.wait([_privateStatsF, _publicStatsF]),
        builder: (BuildContext context, AsyncSnapshot<List<DataSnapshot>> snapshot) {
          Widget result = Container(width: 0.0, height: 0.0);
          if (snapshot.connectionState == ConnectionState.done) {
            if (Purchases.isSubscribed()) {
              if (snapshot.data[0].value != null && snapshot.data[0].value['rank'] > 0) {
                result = ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.of(context).observation_rank),
                      Text(S.of(context).observation_observers),
                    ],
                  ),
                  leading: CircleAvatar(
                    child: Text(snapshot.data[0].value['rank'].toString()),
                  ),
                  trailing: CircleAvatar(
                    child: Text(snapshot.data[1].value['observers'].toString()),
                  ),
                );
              }
            } else {
              result = ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(S.of(context).subscription_info, textAlign: TextAlign.center, style: TextStyle(fontSize: 20,),),
                    FlatButton(
                      color: Colors.lightBlue,
                      child: Text(S.of(context).product_subscribe.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          )),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Subscription(), settings: RouteSettings(name: 'Subscription')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          }
          return result;
        },
      ),
    ));

    _widgets.add(Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.people),
            title: Text(
              S.of(context).observation_public,
              style: listTextStyle,
            ),
          ),
          FutureBuilder<DataSnapshot>(
              future: _publicStatsF,
              builder: (BuildContext context, AsyncSnapshot<DataSnapshot> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    return Container(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(S.of(context).observation_count),
                                Text(S.of(context).observation_distinct_flowers),
                              ],
                            ),
                            leading: CircleAvatar(
                              child: Text(snapshot.data.value['count'].toString()),
                            ),
                            trailing: CircleAvatar(
                              child: Text(snapshot.data.value['distinctFlowers'].toString()),
                            ),
                          ),
                          const Divider(
                            color: Colors.blue,
                            height: 20,
                            thickness: 2,
                            indent: 30,
                            endIndent: 30,
                          ),
                          Container(
                            child: Text(S.of(context).observation_first),
                            alignment: Alignment.center,
                          ),
                          ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snapshot.data.value['firstFlower']),
                                Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(snapshot.data.value['firstDate']))),
                              ],
                            ),
                            leading: Icon(Icons.local_florist),
                            onTap: () {
                              goToDetail(self, mainContext, widget.myLocale, snapshot.data.value['firstFlower'], widget.onChangeLanguage, {});
                            },
                          ),
                          const Divider(
                            color: Colors.blue,
                            height: 20,
                            thickness: 2,
                            indent: 30,
                            endIndent: 30,
                          ),
                          Container(
                            child: Text(S.of(context).observation_last),
                            alignment: Alignment.center,
                          ),
                          ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snapshot.data.value['lastFlower']),
                                Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(snapshot.data.value['lastDate']))),
                              ],
                            ),
                            leading: Icon(Icons.local_florist),
                            onTap: () {
                              goToDetail(self, mainContext, widget.myLocale, snapshot.data.value['lastFlower'], widget.onChangeLanguage, {});
                            },
                          ),
                          const Divider(
                            color: Colors.blue,
                            height: 20,
                            thickness: 2,
                            indent: 30,
                            endIndent: 30,
                          ),
                          Container(
                            child: Text(S.of(context).observation_most),
                            alignment: Alignment.center,
                          ),
                          ListTile(
                            title: Text(snapshot.data.value['mostObserved']),
                            leading: Icon(Icons.local_florist),
                            trailing: CircleAvatar(
                              child: Text(snapshot.data.value['mostObservedCount'].toString()),
                            ),
                            onTap: () {
                              goToDetail(self, mainContext, widget.myLocale, snapshot.data.value['mostObserved'], widget.onChangeLanguage, {});
                            },
                          ),
                        ],
                      ),
                    );
                  default:
                    return Container(width: 0.0, height: 0.0);
                }
              })
        ],
      ),
    ));

    _widgets.add(FutureBuilder<List<dynamic>>(
        future: publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).once().then((snapshot) {
          List<dynamic> result = [];
          Map<MarkerId, Marker> markers = {};
          MarkerId newestMarker;
          int order = 0;
          if (snapshot.value != null && snapshot.value.keys.length > 0) {
            for (Map<dynamic, dynamic> item in snapshot.value.values) {
              var markerId = MarkerId(item['id']);
              if (item['order'] != null && order > item['order']) {
                order = item['order'];
                newestMarker = markerId;
              }
              markers[markerId] = Marker(
                markerId: markerId,
                icon: item['id'].startsWith(widget.currentUser.uid) ? BitmapDescriptor.defaultMarker : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                position: LatLng(
                  item['latitude'] ?? 0.0,
                  item['longitude'] ?? 0.0,
                ),
              );
            }
            result.add(newestMarker);
            result.add(markers);
          }

          return result;
        }),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          Widget result = Container(width: 0.0, height: 0.0);
          if (snapshot.connectionState == ConnectionState.done && snapshot.data.isNotEmpty) {
            result = FlatButton(
              padding: EdgeInsets.all(5.0),
              child: CachedNetworkImage(
                fit: BoxFit.contain,
                width: mapWidth,
                height: mapHeight,
                placeholder: (context, url) => Container(
                  width: mapWidth,
                  height: mapHeight,
                ),
                imageUrl: getMapImageUrl(snapshot.data[1][snapshot.data[0]].position.latitude, snapshot.data[1][snapshot.data[0]].position.longitude, mapWidth, mapHeight),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ObservationsMap(snapshot.data[0], snapshot.data[1]), settings: RouteSettings(name: 'ObservationsMap')),
                );
              },
            );
          }
          return result;
        }));

    if (Purchases.isSubscribed()) {
      _widgets.add(Card(
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                S.of(context).observation_logs,
                style: listTextStyle,
              ),
              leading: Icon(
                Icons.cloud_upload,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5.0),
              height: uploadsHeight,
              child: MyFirebaseAnimatedList(
                  shrinkWrap: true,
                  defaultChild: Center(child: CircularProgressIndicator()),
                  query: logsObservationsReference.child(widget.currentUser.uid).orderByChild(firebaseAttributeTime),
                  itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                    return Card(
                      child: Column(children: [
                        ListTile(
                          title: Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.key)))),
                          leading: Icon(Icons.date_range),
                          onTap: () {},
                        ),
                        getItems(snapshot.value),
                      ]),
                    );
                  }),
            ),
          ],
        ),
      ));
    }

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).observation_stats),
      ),
      body: ListView(children: _widgets),
    );
  }
}
