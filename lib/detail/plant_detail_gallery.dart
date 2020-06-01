import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/fullscreen.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

import '../ads.dart';

Widget _getImageButton(BuildContext context, String url) {
  var placeholder = Stack(alignment: Alignment.center, children: [
    CircularProgressIndicator(),
    Image(
      image: AssetImage('res/images/placeholder.webp'),
    ),
  ]);
  return GestureDetector(
    child: Container(
      padding: EdgeInsets.all(10.0),
      child: getImage(url, placeholder),
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FullScreenPage(url), settings: RouteSettings(name: 'FullScreen')),
      );
    },
  );
}

Widget getGallery(BuildContext context, Plant plant) {
  List<Widget> cards = [];

  cards.add(Card(
    child: _getImageButton(context, storagePhotos + plant.illustrationUrl),
  ));

  cards.addAll(plant.photoUrls.map((url) {
    return Card(
      child: _getImageButton(context, storagePhotos + url),
    );
  }));

  cards.add(Ads.getAdMobBigBanner());

  if (plant.sourceUrls != null) {
    cards.add(Card(
      child: Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _getSources(context, plant.sourceUrls),
        ),
      ),
    ));
  }

  return ListView(
    shrinkWrap: true,
    padding: EdgeInsets.all(5.0),
    children: cards,
  );
}

List<Widget> _getSources(BuildContext context, List<dynamic> sourceUrls) {
  var rows = <Widget>[];

  var sources = [];
  if (sourceUrls != null) {
    sources.addAll(sourceUrls);
  }
  if (sources != null) {
    rows.add(Text(
      S.of(context).plant_sources,
      style: TextStyle(
        fontSize: 22.0,
      ),
      textAlign: TextAlign.center,
    ));

    for (int i = 0; i < sources.length; i += 3) {
      var sourceButtons = <Widget>[];
      for (int j = 0; j < 3; j++) {
        if (i + j < sources.length) {
          sourceButtons.add(getSourceButton(sources[i + j]));
        }
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sourceButtons,
      ));
    }
  }
  return rows;
}
