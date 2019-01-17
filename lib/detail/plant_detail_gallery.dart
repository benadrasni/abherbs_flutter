import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget getGallery(BuildContext context, Future<Plant> _plantF) {
  return FutureBuilder<Plant>(
      future: _plantF,
      builder: (BuildContext context, AsyncSnapshot<Plant> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            List<Widget> cards = [];

            cards.add(Card(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  FlatButton(
                    padding: EdgeInsets.all(10.0),
                    child: CachedNetworkImage(
                      fit: BoxFit.scaleDown,
                      placeholder: Image(image: AssetImage('res/images/placeholder.webp'),),
                      imageUrl: storageEndpoit + storagePhotos + snapshot.data.illustrationUrl,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ));

            for (String url in snapshot.data.photoUrls) {
              cards.add(Card(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    FlatButton(
                      padding: EdgeInsets.all(10.0),
                      child: CachedNetworkImage(
                        fit: BoxFit.scaleDown,
                        placeholder: Image(image: AssetImage('res/images/placeholder.webp'),),
                        imageUrl: storageEndpoit + storagePhotos + url,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ));
            }

            if (snapshot.data.sourceUrls != null) {
              cards.add(Card(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _getSources(context, snapshot.data.sourceUrls),
                  ),
                ),
              ));
            }

            cards.add(getAdMobBanner());

            return ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(5.0),
              children: cards,
            );
          default:
            return Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator()]);
        }
      });
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
