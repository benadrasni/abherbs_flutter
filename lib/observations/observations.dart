import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/entity/observation.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/observations/observation_view.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';

class Observations extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  Observations(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct);

  @override
  _ObservationsState createState() => _ObservationsState();
}

const Key _publicKey = Key('public');
const Key _privateKey = Key('private');

class _ObservationsState extends State<Observations> {
  Key _key;
  bool _isPublic;
  Query _privateQuery;
  Query _publicQuery;
  Query _query;

  void _setIsPublic(bool isPublic) {
    setState(() {
      _isPublic = isPublic;
      _key = _isPublic ? _publicKey : _privateKey;
      _query = _isPublic ? _publicQuery : _privateQuery;
    });
  }

  @override
  void initState() {
    super.initState();
    _key = _privateKey;
    initializeDateFormatting();
    _isPublic = false;
    _privateQuery = privateObservationsReference
        .child(widget.currentUser.uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .orderByChild(firebaseAttributeOrder);
    _publicQuery = publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).orderByChild(firebaseAttributeOrder);
    _query = _privateQuery;

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    var myLocale = Localizations.localeOf(context);

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).observations),
            Row(
              children: [
                Icon(Icons.person),
                Switch(
                  value: _isPublic,
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  onChanged: (bool value) {
                    _setIsPublic(value);
                  },
                ),
                Icon(Icons.people),
              ],
            ),
          ],
        ),
      ),
      body: MyFirebaseAnimatedList(
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
            return ObservationView(widget.currentUser, myLocale, widget.onChangeLanguage, widget.onBuyProduct, observation);
          }),
    );
  }
}
