import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/settings/settings_remote.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/firebase_animated_list.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class PlantSynonyms extends StatefulWidget {
  final Locale myLocale;
  final Plant plant;

  PlantSynonyms(this.myLocale, this.plant);

  @override
  _PlantSynonymsState createState() => _PlantSynonymsState();
}

class _PlantSynonymsState extends State<PlantSynonyms> {
  GlobalKey<ScaffoldState> _key;

  @override
  void initState() {
    super.initState();
    _key = new GlobalKey<ScaffoldState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).plant_synonyms),
      ),
      body: FutureBuilder<RemoteConfig>(
          future: RemoteConfiguration.setupRemoteConfig(),
          builder: (BuildContext context, AsyncSnapshot<RemoteConfig> remoteConfig) {
            if (remoteConfig.connectionState == ConnectionState.done) {
              return MyFirebaseAnimatedList(
                  shrinkWrap: true,
                  defaultChild: Center(child: CircularProgressIndicator()),
                  query: synonymsReference.child(widget.plant.name).child(firebaseAttributeIPNI).orderByChild(firebaseAttributeName),
                  itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                    return Card(
                      child: Column(children: [
                        ListTile(
                          leading: Icon(Icons.arrow_right),
                          trailing: Icon(Icons.insert_link),
                          title: Text([snapshot.value['name'], snapshot.value['suffix']].join(' ')),
                          subtitle: Text(snapshot.value['author']),
                          onTap: () {
                            launchURL(remoteConfig.data.getString(remoteConfigIPNIServer) + snapshot.value['href']);
                          },
                        ),
                      ]),
                    );
                  });
            } else {
              return Container();
            }
          }),
    );
  }
}
