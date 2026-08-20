import 'dart:async';

import 'package:abherbs_flutter/detail/plant_detail_edit.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/entity/plant_translation.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/legend/flower.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

Widget getInfo(BuildContext context, Locale myLocale, Plant plant, Future<PlantTranslation> _plantTranslationF, double _fontSize, GlobalKey<ScaffoldState> key) {
  String language = Localizations.localeOf(context).languageCode;

  TextStyle _defaultTextStyle = TextStyle(
    fontSize: _fontSize,
    color: Colors.black,
  );

  TextStyle _highlightTextStyle = TextStyle(
    fontSize: _fontSize,
    fontWeight: FontWeight.bold,
    color: Colors.lightBlue,
  );

  return FutureBuilder<PlantTranslation>(
      future: _plantTranslationF,
      builder: (BuildContext context, AsyncSnapshot<PlantTranslation> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            List<Widget> cards = [];

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: _getNames(context, plant, snapshot.data, key),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Flexible(child: Text(
                              [S.of(context).plant_height_from, plant.heightFrom.toString(), S.of(context).plant_height_to, plant.heightTo.toString(), heightUnitOfMeasure].join(' '),
                              style: _defaultTextStyle,
                            )),
                          ]),
                          Row(children: [
                            Flexible(child: Text(
                              [S.of(context).plant_flowering_from, DateFormat.MMMM(myLocale.languageCode).format(DateTime(0, plant.floweringFrom)), S.of(context).plant_flowering_to,
                                DateFormat.MMMM(myLocale.languageCode).format(DateTime(0, plant.floweringTo))].join(' '),
                              style: _defaultTextStyle,
                            )),
                          ]),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetailEdit(plant.name, language, '', '', 'description', snapshot.data!.description!, _fontSize),
                                settings: RouteSettings(name: 'PlantDetailEdit')
                              )).then((value) {
                            if (value != null && value) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(S.of(context).snack_translation),
                              ));
                            }
                          });
                        },
                      ),
                    ),
                    _getRichText(snapshot.data!.description!, _defaultTextStyle),
                  ],
                ),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(
                      S.of(context).plant_inflorescence,
                      style: _defaultTextStyle,
                    ),
                    leading: Image(
                      image: AssetImage('res/images/ic_inflorescence_grey_24dp.png'),
                      width: 24.0,
                      height: 24.0,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_inflorescence_grey_24dp.png', S.of(context).plant_inflorescence, "inflorescence", snapshot.data!.inflorescence!, _fontSize),
                              settings: RouteSettings(name: 'PlantDetailEdit')
                            )).then((value) {
                          if (value != null && value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(S.of(context).snack_translation),
                            ));
                          }
                        });
                      },
                    ),
                  ),
                  _getRichText(snapshot.data!.inflorescence!, _defaultTextStyle),
                ]),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(
                      S.of(context).plant_flower,
                      style: _highlightTextStyle,
                    ),
                    leading: Image(
                      image: AssetImage('res/images/ic_flower_grey_24dp.png'),
                      width: 24.0,
                      height: 24.0,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_flower_grey_24dp.png', S.of(context).plant_flower, "flower", snapshot.data!.flower!, _fontSize),
                              settings: RouteSettings(name: 'PlantDetailEdit')
                            )).then((value) {
                          if (value != null && value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(S.of(context).snack_translation),
                            ));
                          }
                        });
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FlowerLegendScreen(), settings: RouteSettings(name: 'FlowerLegend')),
                      );
                    },
                  ),
                  _getRichText(snapshot.data!.flower!, _defaultTextStyle),
                ]),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(
                      S.of(context).plant_fruit,
                      style: _defaultTextStyle,
                    ),
                    leading: Image(
                      image: AssetImage('res/images/ic_fruit_grey_24dp.png'),
                      width: 24.0,
                      height: 24.0,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_fruit_grey_24dp.png', S.of(context).plant_fruit, "fruit", snapshot.data!.fruit!, _fontSize),
                              settings: RouteSettings(name: 'PlantDetailEdit')
                            )).then((value) {
                          if (value != null && value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(S.of(context).snack_translation),
                            ));
                          }
                        });
                      },
                    ),
                  ),
                  _getRichText(snapshot.data!.fruit!, _defaultTextStyle),
                ]),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(
                      S.of(context).plant_leaf,
                      style: _defaultTextStyle,
                    ),
                    leading: Image(
                      image: AssetImage('res/images/ic_leaf_grey_24dp.png'),
                      width: 24.0,
                      height: 24.0,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_leaf_grey_24dp.png', S.of(context).plant_leaf, "leaf", snapshot.data!.leaf!, _fontSize),
                              settings: RouteSettings(name: 'PlantDetailEdit')
                            )).then((value) {
                          if (value != null && value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(S.of(context).snack_translation),
                            ));
                          }
                        });
                      },
                    ),
                  ),
                  _getRichText(snapshot.data!.leaf!, _defaultTextStyle),
                ]),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(
                      S.of(context).plant_stem,
                      style: _defaultTextStyle,
                    ),
                    leading: Image(
                      image: AssetImage('res/images/ic_stem_grey_24dp.png'),
                      width: 24.0,
                      height: 24.0,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_stem_grey_24dp.png', S.of(context).plant_stem, "stem", snapshot.data!.stem!, _fontSize),
                              settings: RouteSettings(name: 'PlantDetailEdit')
                            )).then((value) {
                          if (value != null && value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(S.of(context).snack_translation),
                            ));
                          }
                        });
                      },
                    ),
                  ),
                  _getRichText(snapshot.data!.stem!, _defaultTextStyle),
                ]),
              ),
            ));

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    title: Text(
                      S.of(context).plant_habitat,
                      style: _defaultTextStyle,
                    ),
                    leading: Image(
                      image: AssetImage('res/images/ic_home_grey_24dp.png'),
                      width: 24.0,
                      height: 24.0,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_home_grey_24dp.png', S.of(context).plant_habitat, "habitat", snapshot.data!.habitat!, _fontSize),
                              settings: RouteSettings(name: 'PlantDetailEdit')
                            )).then((value) {
                          if (value != null && value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(S.of(context).snack_translation),
                            ));
                          }
                        });
                      },
                    ),
                  ),
                  _getRichText(snapshot.data!.habitat!, _defaultTextStyle),
                ]),
              ),
            ));

            // optional attributes
            if (snapshot.data!.toxicity != null) {
              cards.add(Card(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ListTile(
                      title: Text(
                        S.of(context).plant_toxicity,
                        style: _defaultTextStyle,
                      ),
                      leading: Image(
                        image: AssetImage('res/images/ic_toxicity_grey_24dp.png'),
                        width: 24.0,
                        height: 24.0,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_toxicity_grey_24dp.png', S.of(context).plant_toxicity, "toxicity", snapshot.data!.toxicity!, _fontSize),
                                settings: RouteSettings(name: 'PlantDetailEdit')
                              )).then((value) {
                            if (value != null && value) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(S.of(context).snack_translation),
                              ));
                            }
                          });
                        },
                      ),
                    ),
                    _getRichText(snapshot.data!.toxicity!, _defaultTextStyle),
                  ]),
                ),
              ));
            }

            if (snapshot.data!.herbalism != null) {
              cards.add(Card(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ListTile(
                      title: Text(
                        S.of(context).plant_herbalism,
                        style: _defaultTextStyle,
                      ),
                      leading: Image(
                        image: AssetImage('res/images/ic_local_pharmacy_grey_24dp.png'),
                        width: 24.0,
                        height: 24.0,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_local_pharmacy_grey_24dp.png', S.of(context).plant_herbalism, "herbalism", snapshot.data!.herbalism!, _fontSize),
                                settings: RouteSettings(name: 'PlantDetailEdit')
                              )).then((value) {
                            if (value != null && value) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(S.of(context).snack_translation),
                              ));
                            }
                          });
                        },
                      ),
                    ),
                    _getRichText(snapshot.data!.herbalism!, _defaultTextStyle),
                  ]),
                ),
              ));
            }

            if (snapshot.data!.trivia != null) {
              cards.add(Card(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0, bottom: 10.0, right: 10.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ListTile(
                      title: Text(
                        S.of(context).plant_trivia,
                        style: _defaultTextStyle,
                      ),
                      leading: Image(
                        image: AssetImage('res/images/ic_question_mark_grey_24dp.png'),
                        width: 24.0,
                        height: 24.0,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetailEdit(plant.name, language, 'res/images/ic_question_mark_grey_24dp.png', S.of(context).plant_trivia, "trivia", snapshot.data!.trivia!, _fontSize),
                                settings: RouteSettings(name: 'PlantDetailEdit')
                              )).then((value) {
                            if (value != null && value) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(S.of(context).snack_translation),
                              ));
                            }
                          });
                        },
                      ),
                    ),
                    _getRichText(snapshot.data!.trivia!, _defaultTextStyle),
                  ]),
                ),
              ));
            }

            cards.add(Card(
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: PlantSourcesSection([
                  if (snapshot.data!.wikipedia != null) snapshot.data!.wikipedia,
                  ...plant.wikiLinks.values,
                  ...snapshot.data!.sourceUrls,
                ]),
              ),
            ));

            return ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(5.0),
              children: cards,
            );
          default:
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(),
                CircularProgressIndicator(),
                Container(),
              ],
            );
        }
      });
}

Widget _getNames(BuildContext context, Plant plant, PlantTranslation? plantTranslation, GlobalKey<ScaffoldState> key) {
  var names = <Widget>[];
  var label = plantTranslation?.label ?? plant.name;
  names.add(GestureDetector(
    child: Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22.0,
      ),
      textAlign: TextAlign.center,
    ),
    onLongPress: () {
      Clipboard.setData(new ClipboardData(text: label));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).snack_copy),
      ));
    },
  ));
  if (plantTranslation?.names != null) {
    names.add(GestureDetector(
      child: Text(
        plantTranslation!.names.take(3).join(', '),
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 14.0,
        ),
        textAlign: TextAlign.center,
      ),
      onLongPress: () {
        Clipboard.setData(new ClipboardData(text: label));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).snack_copy),
        ));
      },
    ));
  }

  Widget result;
  if (plant.toxicityClass > 0) {
    result = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Image(
            image: AssetImage(plant.toxicityClass == 1 ? 'res/images/toxicity1.png' : 'res/images/toxicity2.png'),
            width: 50.0,
            height: 50.0,
          ),
          flex: 1,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: names,
          ),
          flex: 4,
        )
      ],
    );
  } else {
    result = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: names,
    );
  }

  return result;
}

const int collapsedSourceCount = 6;

String sourceHost(String url) {
  final uri = Uri.tryParse(url);
  var host = uri != null && uri.host.isNotEmpty ? uri.host : url;
  host = host.toLowerCase();
  if (host.startsWith('www.')) {
    host = host.substring(4);
  }
  return host;
}

List<String> uniqueSourceUrls(Iterable<dynamic> urls) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in urls) {
    if (raw == null) {
      continue;
    }
    final url = raw.toString().trim();
    if (url.isEmpty) {
      continue;
    }
    if (!seen.add(sourceHost(url))) {
      continue;
    }
    out.add(url);
  }
  return out;
}

class PlantSourcesSection extends StatefulWidget {
  final Iterable<dynamic> urls;

  const PlantSourcesSection(this.urls, {super.key});

  @override
  State<PlantSourcesSection> createState() => _PlantSourcesSectionState();
}

class _PlantSourcesSectionState extends State<PlantSourcesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sources = uniqueSourceUrls(widget.urls);
    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }
    final hidden = sources.length - collapsedSourceCount;
    final visible = _expanded || hidden <= 0 ? sources : sources.take(collapsedSourceCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          S.of(context).plant_sources,
          style: const TextStyle(fontSize: 22.0),
          textAlign: TextAlign.center,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) => getSourceButton(visible[index]),
        ),
        if (hidden > 0)
          TextButton(
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                if (!_expanded) Text('+$hidden'),
              ],
            ),
          ),
      ],
    );
  }
}

TextButton getSourceButton(String url) {
  String imageSource = 'res/images/internet.png';
  String textSource = sourceHost(url);

  if (url.contains(sourceWikipedia)) {
    imageSource = 'res/images/wikipedia.png';
    textSource = sourceWikipedia;
  } else if (url.contains(sourceWikimediaCommons)) {
    imageSource = 'res/images/commons.png';
    textSource = sourceWikimediaCommonsTitle;
  } else if (url.contains(sourceWikimediaData)) {
    imageSource = 'res/images/wikidata.png';
    textSource = sourceWikimediaDataTitle;
  } else if (url.contains(sourceWikimediaSpecies)) {
    imageSource = 'res/images/species.png';
    textSource = sourceWikimediaSpeciesTitle;
  } else if (url.contains(sourceLuontoportii)) {
    imageSource = 'res/images/luontoportti.png';
    textSource = sourceLuontoportii;
  } else if (url.contains(sourceBotany)) {
    imageSource = 'res/images/botany.png';
    textSource = sourceBotany;
  } else if (url.contains(sourceFloraNordica)) {
    imageSource = 'res/images/floranordica.png';
    textSource = sourceFloraNordica;
  } else if (url.contains(sourceEflora)) {
    imageSource = 'res/images/eflora.png';
    textSource = sourceEflora;
  } else if (url.contains(sourceBerkeley)) {
    imageSource = 'res/images/berkeley.png';
    textSource = sourceBerkeley;
  } else if (url.contains(sourceHortipedia)) {
    imageSource = 'res/images/hortipedia.png';
    textSource = sourceHortipedia;
  } else if (url.contains(sourceUsda)) {
    imageSource = 'res/images/usda.png';
    textSource = sourceUsda;
  } else if (url.contains(sourceUsfs)) {
    imageSource = 'res/images/usfs.png';
    textSource = sourceUsfs;
  } else if (url.contains(sourceTelaBotanica)) {
    imageSource = 'res/images/tela_botanica.png';
    textSource = sourceTelaBotanica;
  }

  return TextButton(
    style: ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)),
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: () {
      launchURL(url);
    },
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image(
        image: AssetImage(imageSource),
        width: 50.0,
        height: 50.0,
      ),
      Text(
        textSource,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.0),
      ),
    ]),
  );
}

RichText _getRichText(String text, TextStyle textStyle) {
  var sections = <TextSpan>[];
  for (String part in text.split('<b>')) {
    if (part.isNotEmpty) {
      var subParts = part.split('</b>');
      if (subParts.length == 1) {
        sections.add(TextSpan(text: subParts[0]));
      } else {
        sections.add(TextSpan(text: subParts[0], style: new TextStyle(fontWeight: FontWeight.bold)));
        sections.add(TextSpan(text: subParts[1]));
      }
    }
  }

  return RichText(
    text: TextSpan(
      style: textStyle,
      children: sections,
    ),
  );
}
