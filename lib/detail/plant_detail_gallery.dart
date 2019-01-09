import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:flutter/material.dart';

const String sourceWikipedia = "wikipedia";
const String sourceWikimediaCommons = "commons.wikimedia.org";
const String sourceWikimediaCommonsTitle = "commons";
const String sourceWikimediaSpecies = "species.wikimedia.org";
const String sourceWikimediaSpeciesTitle = "species";
const String sourceWikimediaData = "wikidata.org";
const String sourceWikimediaDataTitle = "wikidata";
const String sourceLuontoportii = "luontoportti.com";
const String sourceBotany = "botany.cz";
const String sourceFloraNordica = "floranordica.org";
const String sourceEflora = "efloras.org";
const String sourceBerkeley = "berkeley.edu";
const String sourceHortipedia = "hortipedia.com";
const String sourceUsda = "plants.usda.gov";
const String sourceUsfs = "forestryimages.org";
const String sourceTelaBotanica = "tela-botanica.org";

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
                    child: FadeInImage.assetNetwork(
                      fit: BoxFit.scaleDown,
                      placeholder: 'res/images/placeholder.webp',
                      image: storageEndpoit + storagePhotos + snapshot.data.illustrationUrl,
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
                      child: FadeInImage.assetNetwork(
                        fit: BoxFit.scaleDown,
                        placeholder: 'res/images/placeholder.webp',
                        image: storageEndpoit + storagePhotos + url,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ));
            }

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _getSources(snapshot.data.sourceUrls),
                ),
              ),
            ));

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

List<Widget> _getSources(List<dynamic> sourceUrls) {
  var rows = <Widget>[];

  var sources = [];
  if (sourceUrls != null) {
    sources.addAll(sourceUrls);
  }
  if (sources != null) {
    rows.add(Text(
      'Sources',
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
