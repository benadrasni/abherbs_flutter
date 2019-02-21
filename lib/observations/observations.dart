import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Observations extends StatefulWidget {
  final FirebaseUser currentUser;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  Observations(this.currentUser, this.onChangeLanguage, this.onBuyProduct);

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
  Map<String, String> _translationCache;

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
    _isPublic = false;
    _key = _privateKey;
    _privateQuery = privateObservationsReference.child(widget.currentUser.uid).child(firebaseObservationsByDate).child(firebaseAttributeList).orderByChild('order');
    _publicQuery = publicObservationsReference.child(firebaseObservationsByDate).child(firebaseAttributeList).orderByChild('order');
    _query = _privateQuery;
    _translationCache = {};

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).observations),
            Row(children:[
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
              ],),
          ],
        ),
      ),
      body: FirebaseAnimatedList(
          key: _key,
          defaultChild: Center(child: CircularProgressIndicator()),
          query: _query,
          itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
            String name = snapshot.value['plant'];

            Locale myLocale = Localizations.localeOf(context);
            Future<String> nameF = _translationCache.containsKey(name)
                ? Future<String>(() {
                    return _translationCache[name];
                  })
                : translationsReference.child(getLanguageCode(myLocale.languageCode)).child(name).child('label').once().then((DataSnapshot snapshot) {
                    if (snapshot.value != null) {
                      _translationCache[name] = snapshot.value;
                      return snapshot.value;
                    } else {
                      return null;
                    }
                  });

            return Card(
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                FutureBuilder<String>(
                    future: nameF,
                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                      String labelLocal = name;
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.data != null) {
                          labelLocal = snapshot.data;
                        }
                      }
                      return ListTile(
                        title: Text(labelLocal),
                        subtitle: Text(labelLocal != name ? name : ''),
                        onTap: () {
                          //_onPressed(myLocale, name);
                        },
                      );
                    }),
              ]),
            );
          }),
    );
  }
}
