import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/observations/observation_plant_view.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

class ObservationsPlant extends StatefulWidget {
  final Locale myLocale;
  final bool isPublic;
  final String plantName;
  final GlobalKey<ScaffoldState> parentKey;
  ObservationsPlant(this.myLocale, this.isPublic, this.plantName, this.parentKey);

  @override
  _ObservationsPlantState createState() => _ObservationsPlantState();
}

const Key _publicKey = Key('public');
const Key _privateKey = Key('private');

class _ObservationsPlantState extends State<ObservationsPlant> {
  Key _key = _privateKey;
  late Query _privateQuery;
  late Query _publicQuery;
  late Query _query;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _privateQuery = privateObservationsReference
        .child(Auth.appUser!.uid)
        .child(firebaseObservationsByPlant)
        .child(widget.plantName)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeOrder);
    _publicQuery = publicObservationsReference
        .child(firebaseObservationsByPlant)
        .child(widget.plantName)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeOrder);
  }

  @override
  Widget build(BuildContext context) {
    var myLocale = Localizations.localeOf(context);

    _key = widget.isPublic ? _publicKey : _privateKey;
    _query = widget.isPublic ? _publicQuery : _privateQuery;

    return Stack(
      children: [
        MyFirebaseAnimatedList(
            key: _key,
            defaultChild: Center(child: CircularProgressIndicator()),
            emptyChild: Container(
              padding: EdgeInsets.all(5.0),
              alignment: Alignment.center,
              child: Text(S.of(context).observation_empty, style: TextStyle(fontSize: 20.0)),
            ),
            query: _query,
            itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
              if (snapshot.value == null) {
                return Container();
              }
              Observation observation = Observation.fromJson(snapshot.key, snapshot.value as Map);
              return ObservationPlantView(myLocale, observation, widget.parentKey);
            }),
      ],
    );
  }
}
