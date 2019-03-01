import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/observations/observation_edit.dart';
import 'package:abherbs_flutter/observations/observation_plant_view.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';

class ObservationsPlant extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final bool isPublic;
  final String plantName;
  ObservationsPlant(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct, this.isPublic, this.plantName);

  @override
  _ObservationsPlantState createState() => _ObservationsPlantState();
}

const Key _publicKey = Key('public');
const Key _privateKey = Key('private');

class _ObservationsPlantState extends State<ObservationsPlant> {
  Key _key;
  Query _privateQuery;
  Query _publicQuery;
  Query _query;

  @override
  void initState() {
    super.initState();
    _key = _privateKey;
    initializeDateFormatting();
    _privateQuery = privateObservationsReference
        .child(widget.currentUser.uid)
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
              Observation observation = Observation.fromJson(snapshot.key, snapshot.value);
              return ObservationPlantView(widget.currentUser, myLocale, widget.onChangeLanguage, widget.onBuyProduct, observation);
            }),
        Positioned(
          bottom: 20.0,
          right: 20.0,
          child: FloatingActionButton(
            onPressed: () {
              var observation = Observation(widget.plantName);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ObservationEdit(widget.currentUser, myLocale, widget.onChangeLanguage, widget.onBuyProduct, observation)),
              ).then((_) {
                setState(() {});
              });
            },
            child: Icon(Icons.add),
          ),),
      ],
    );
  }
}
