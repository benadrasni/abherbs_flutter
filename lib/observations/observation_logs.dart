import 'dart:async';
import 'dart:collection';

import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/purchase/subscription.dart';
import 'package:abherbs_flutter/settings/settings_remote.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;

import '../main.dart';
import 'observation_edit.dart';
import 'observations_map.dart';

class ObservationsSum {
  final DateTime date;
  final int count;

  ObservationsSum(this.date, this.count);
}

class ObservationLogs extends StatefulWidget {
  final Locale myLocale;
  final currentIndex;
  ObservationLogs(this.myLocale, this.currentIndex);

  @override
  _ObservationLogsState createState() => _ObservationLogsState();
}

class _ObservationLogsState extends State<ObservationLogs> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late DateFormat _dateFormat;
  late Future<DatabaseEvent> _privateStatsF;
  late Future<DatabaseEvent> _publicStatsF;
  ScrollController _scrollControllerPrivate = ScrollController();
  ScrollController _scrollControllerPublic = ScrollController();
  late int _currentIndex;

  _scrollToEnd() async {
    switch (_currentIndex) {
      case 0:
        Timer(Duration(milliseconds: 500), () {
          if (mounted) {
            _scrollControllerPrivate.animateTo(_scrollControllerPrivate.position.maxScrollExtent, duration: Duration(milliseconds: 400), curve: Curves.ease);
          }
        });
        break;
      case 1:
        Timer(Duration(milliseconds: 500), () {
          if (mounted) {
            _scrollControllerPublic.animateTo(_scrollControllerPublic.position.maxScrollExtent, duration: Duration(milliseconds: 400), curve: Curves.ease);
          }
        });
        break;
    }
  }

  _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat.yMMMMEEEEd(widget.myLocale.toString()).add_jm();
    _currentIndex = widget.currentIndex;

    _privateStatsF = privateObservationsReference.child(Auth.appUser!.uid).child(firebaseObservationsStats).once();
    _publicStatsF = publicObservationsReference.child(firebaseObservationsStats).once();
  }

  Widget getItems(Map<dynamic, dynamic> observations) {
    var items = observations.keys.where((x) => x != firebaseAttributeTime).map((id) {
      return FutureBuilder<Observation>(
          future: privateObservationsReference.child(Auth.appUser!.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).child(id.toString()).once().then((event) {
            var observation = Observation.fromJson(event.snapshot.key, event.snapshot.value as Map);
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
                          Text(snapshot.data!.plant),
                          Text(_dateFormat.format(snapshot.data!.date)),
                        ],
                      ),
                      trailing: snapshot.data!.uploadStatus == firebaseValueSuccess ? Icon(Icons.done) : snapshot.data!.uploadStatus == firebaseValueRejection ? Icon(Icons.close) : Icon(Icons.error),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ObservationEdit(Localizations.localeOf(context), snapshot.data!),
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

  Widget getCountries(Future<DatabaseEvent> databaseEventF, TextStyle listTextStyle, double countriesHeight) {
    return Card(
        child: FutureBuilder<DatabaseEvent>(
            future: databaseEventF,
            builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> event) {
              Widget result = Container(width: 0.0, height: 0.0);
              if (event.connectionState == ConnectionState.done && event.data!.snapshot.value != null) {
                var countries = (event.data!.snapshot.value as Map)['countries'];
                List<String> sortedKeys = [];
                if (countries != null) {
                  for (var key in countries.keys) {
                    sortedKeys.add(key.toString());
                  }
                }
                sortedKeys.sort((k1, k2) => countries[k1].compareTo(countries[k2]) * -1);
                LinkedHashMap sortedMap = LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => countries[k]);
                var widgets = <Widget>[];
                for (var entry in sortedMap.entries) {
                  widgets.add(ListTile(
                      leading: Image(
                        image: AssetImage('icons/flags/png/' + entry.key + '.png', package: 'country_icons'),
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.fitWidth,
                      ),
                      title: Text(CountryLocalizations.of(context)?.countryName(countryCode: entry.key.toUpperCase()) ?? ''),
                      trailing: CircleAvatar(
                        child: Text(entry.value.toString()),
                      )));
                }
                result = Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.people),
                      title: Text(
                        S.of(context).observation_countries,
                        style: listTextStyle,
                      ),
                    ),
                    Container(
                      height: countriesHeight,
                      child: ListView(
                        children: widgets,
                      ),
                    ),
                  ],
                );
              }
              return result;
            }));
  }

  @override
  Widget build(BuildContext context) {
    App.currentContext = context;
    var self = this;
    var mainContext = context;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    TextStyle listTextStyle = TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
    double uploadsHeight = MediaQuery.of(context).size.height;
    double countriesHeight = MediaQuery.of(context).size.height / 2;
    double mapWidth = MediaQuery.of(context).size.width;
    double mapHeight = 100.0;

    Widget button = Container();
    String value = RemoteConfiguration.remoteConfig.getString(remoteConfigObservationsVideo);
    if (value.isNotEmpty) {
      button = TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
        ),
        child: Text(S
            .of(mainContext)
            .video,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            )),
        onPressed: () {
          launchURL(value);
        },
      );
    }

    var _widgets = <Widget>[];
    if (_currentIndex == 0) {
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
            FutureBuilder<DatabaseEvent>(
                future: _privateStatsF,
                builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> event) {
                  switch (event.connectionState) {
                    case ConnectionState.done:
                      if (event.data!.snapshot.value == null) {
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
                                child: Text((event.data!.snapshot.value as Map)['count'].toString()),
                              ),
                              trailing: CircleAvatar(
                                child: Text((event.data!.snapshot.value as Map)['distinctFlowers'].toString()),
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
                                  Text((event.data!.snapshot.value as Map)['firstFlower']),
                                  Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch((event.data!.snapshot.value as Map)['firstDate']))),
                                ],
                              ),
                              leading: Icon(Icons.local_florist),
                              onTap: () {
                                goToDetail(self, mainContext, widget.myLocale, (event.data!.snapshot.value as Map)['firstFlower'], {});
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
                                  Text((event.data!.snapshot.value as Map)['lastFlower']),
                                  Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch((event.data!.snapshot.value as Map)['lastDate']))),
                                ],
                              ),
                              leading: Icon(Icons.local_florist),
                              onTap: () {
                                goToDetail(self, mainContext, widget.myLocale, (event.data!.snapshot.value as Map)['lastFlower'], {});
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
                              title: Text((event.data!.snapshot.value as Map)['mostObserved']),
                              leading: Icon(Icons.local_florist),
                              trailing: CircleAvatar(
                                child: Text((event.data!.snapshot.value as Map)['mostObservedCount'].toString()),
                              ),
                              onTap: () {
                                goToDetail(self, mainContext, widget.myLocale, (event.data!.snapshot.value as Map)['mostObserved'], {});
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
          future: privateObservationsReference.child(Auth.appUser!.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).once().then((event) {
            List<dynamic> result = [];
            Map<MarkerId, Marker> markers = {};
            MarkerId? newestMarker;
            List<ObservationsSum> data = [];
            int order = 0;
            if (event.snapshot.value != null && (event.snapshot.value as Map).keys.length > 0) {
              for (String item in (event.snapshot.value as Map).keys) {
                Observation observation = Observation.fromJson(item, (event.snapshot.value as Map)[item]);
                var markerId = MarkerId(observation.id);
                if (order > observation.order) {
                  order = observation.order;
                  newestMarker = markerId;
                }
                markers[markerId] = Marker(
                  markerId: markerId,
                  //draggable: true,
                  position: LatLng(
                    observation.latitude,
                    observation.longitude,
                  ),
                );
                data.add(ObservationsSum(observation.date, 1));
              }
              if (newestMarker != null) {
                result.add(newestMarker);
              }
              result.add(markers);
              result.add([
                charts.Series<ObservationsSum, DateTime>(
                  id: 'Observations',
                  colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                  domainFn: (ObservationsSum item, _) => item.date,
                  measureFn: (ObservationsSum item, _) => item.count,
                  data: data,
                )
              ]);
            }

            return result;
          }),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            Widget result = Container(width: 0.0, height: 0.0);
            if (snapshot.connectionState == ConnectionState.done && snapshot.data!.isNotEmpty) {
              result = Column(
                children: [
                  TextButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                          EdgeInsets.all(5.0)),
                    ),
                    child: CachedNetworkImage(
                      fit: BoxFit.contain,
                      width: mapWidth,
                      height: mapHeight,
                      placeholder: (context, url) => Container(
                        width: mapWidth,
                        height: mapHeight,
                      ),
                      imageUrl: getMapImageUrl(snapshot.data![1][snapshot.data![0]].position.latitude, snapshot.data![1][snapshot.data![0]].position.longitude, mapWidth, mapHeight),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ObservationsMap(snapshot.data![0], snapshot.data![1]), settings: RouteSettings(name: 'ObservationsMap')),
                      );
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(5.0),
                    child: SingleChildScrollView(
                      controller: _scrollControllerPrivate,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: mapWidth * (snapshot.data![2][0].data.length ~/ 100 + 1),
                        height: mapHeight,
                        child: charts.TimeSeriesChart(
                          snapshot.data![2],
                          animate: true,
                          defaultRenderer: charts.BarRendererConfig<DateTime>(),
                          defaultInteractions: false,
                          primaryMeasureAxis: charts.NumericAxisSpec(renderSpec: charts.NoneRenderSpec()),
                          behaviors: [
                            charts.SlidingViewport(),
                            charts.PanAndZoomBehavior(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return result;
          }));

      _widgets.add(getCountries(_privateStatsF, listTextStyle, countriesHeight));
    }

    if (_currentIndex == 1) {
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
            Card(
              child: FutureBuilder<List<DatabaseEvent>>(
                future: Future.wait([_privateStatsF, _publicStatsF]),
                builder: (BuildContext context, AsyncSnapshot<List<DatabaseEvent>> events) {
                  Widget result = Container(width: 0.0, height: 0.0);
                  if (events.connectionState == ConnectionState.done) {
                    if (Purchases.isSubscribed()) {
                      if (events.data![0].snapshot.value != null && (events.data![0].snapshot.value as Map)['rank'] > 0) {
                        result = ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.of(context).observation_rank),
                              Text(S.of(context).observation_observers),
                            ],
                          ),
                          leading: CircleAvatar(
                            child: Text((events.data![0].snapshot.value as Map)['rank'].toString()),
                          ),
                          trailing: CircleAvatar(
                            child: Text((events.data![1].snapshot.value as Map)['observers'].toString()),
                          ),
                        );
                      }
                    } else {
                      result = ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              S.of(context).subscription_info,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            button,
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                              ),
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
            ),
            FutureBuilder<DatabaseEvent>(
                future: _publicStatsF,
                builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> event) {
                  switch (event.connectionState) {
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
                                child: Text((event.data!.snapshot.value as Map)['count'].toString()),
                              ),
                              trailing: CircleAvatar(
                                child: Text((event.data!.snapshot.value as Map)['distinctFlowers'].toString()),
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
                                  Text((event.data!.snapshot.value as Map)['firstFlower']),
                                  Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch((event.data!.snapshot.value as Map)['firstDate']))),
                                ],
                              ),
                              leading: Icon(Icons.local_florist),
                              onTap: () {
                                goToDetail(self, mainContext, widget.myLocale, (event.data!.snapshot.value as Map)['firstFlower'], {});
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
                                  Text((event.data!.snapshot.value as Map)['lastFlower']),
                                  Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch((event.data!.snapshot.value as Map)['lastDate']))),
                                ],
                              ),
                              leading: Icon(Icons.local_florist),
                              onTap: () {
                                goToDetail(self, mainContext, widget.myLocale, (event.data!.snapshot.value as Map)['lastFlower'], {});
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
                              title: Text((event.data!.snapshot.value as Map)['mostObserved']),
                              leading: Icon(Icons.local_florist),
                              trailing: CircleAvatar(
                                child: Text((event.data!.snapshot.value as Map)['mostObservedCount'].toString()),
                              ),
                              onTap: () {
                                goToDetail(self, mainContext, widget.myLocale, (event.data!.snapshot.value as Map)['mostObserved'], {});
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
          future: publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).once().then((event) {
            List<dynamic> result = [];
            Map<MarkerId, Marker> markers = {};
            MarkerId? newestMarker;
            List<ObservationsSum> data = [];
            int order = 0;
            if (event.snapshot.value != null && (event.snapshot.value as Map).keys.length > 0) {
              for (String item in (event.snapshot.value as Map).keys) {
                Observation observation = Observation.fromJson(item, (event.snapshot.value as Map)[item]);
                var markerId = MarkerId(observation.id);
                if (order > observation.order) {
                  order = observation.order;
                  newestMarker = markerId;
                }
                markers[markerId] = Marker(
                  markerId: markerId,
                  icon: observation.id.startsWith(Auth.appUser!.uid) ? BitmapDescriptor.defaultMarker : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  position: LatLng(
                    observation.latitude,
                    observation.longitude,
                  ),
                );
                data.add(ObservationsSum(observation.date, 1));
              }
              if (newestMarker != null) {
                result.add(newestMarker);
              }
              result.add(markers);
              result.add([
                charts.Series<ObservationsSum, DateTime>(
                  id: 'Observations',
                  colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                  domainFn: (ObservationsSum item, _) => item.date,
                  measureFn: (ObservationsSum item, _) => item.count,
                  data: data,
                )
              ]);
            }

            return result;
          }),
          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            Widget result = Container(width: 0.0, height: 0.0);
            if (snapshot.connectionState == ConnectionState.done && snapshot.data!.isNotEmpty) {
              result = Column(
                children: [
                  TextButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                          EdgeInsets.all(5.0)),
                    ),
                    child: CachedNetworkImage(
                      fit: BoxFit.contain,
                      width: mapWidth,
                      height: mapHeight,
                      placeholder: (context, url) => Container(
                        width: mapWidth,
                        height: mapHeight,
                      ),
                      imageUrl: getMapImageUrl(snapshot.data![1][snapshot.data![0]].position.latitude, snapshot.data![1][snapshot.data![0]].position.longitude, mapWidth, mapHeight),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ObservationsMap(snapshot.data![0], snapshot.data![1]), settings: RouteSettings(name: 'ObservationsMap')),
                      );
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(5.0),
                    child: SingleChildScrollView(
                      controller: _scrollControllerPublic,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: mapWidth * 2,
                        height: mapHeight,
                        child: charts.TimeSeriesChart(
                          snapshot.data![2],
                          animate: true,
                          defaultRenderer: charts.BarRendererConfig<DateTime>(),
                          defaultInteractions: false,
                          primaryMeasureAxis: charts.NumericAxisSpec(renderSpec: charts.NoneRenderSpec()),
                          behaviors: [
                            charts.SlidingViewport(),
                            charts.PanAndZoomBehavior(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return result;
          }));

      _widgets.add(getCountries(_publicStatsF, listTextStyle, countriesHeight));
    }

    if (_currentIndex == 2) {
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
                  query: logsObservationsReference.child(Auth.appUser!.uid).orderByChild(firebaseAttributeTime),
                  itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                    return Card(
                      child: Column(children: [
                        ListTile(
                          title: Text(_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.key!)))),
                          leading: Icon(Icons.date_range),
                          onTap: () {},
                        ),
                        getItems(snapshot.value as Map),
                      ]),
                    );
                  }),
            ),
          ],
        ),
      ));
    }

    List<BottomNavigationBarItem> bottomNav = [];
    bottomNav.add(BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: S.of(context).observation_private,
    ));
    bottomNav.add(BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: S.of(context).observation_public,
    ));
    if (Purchases.isSubscribed()) {
      bottomNav.add(BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: S.of(context).observation_logs));
    }

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).observation_stats),
      ),
      body: ListView(children: _widgets),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: bottomNav,
      ),
    );
  }
}
