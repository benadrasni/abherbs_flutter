import 'dart:async';

import 'package:abherbs_flutter/enhancements.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/search/search.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String productNoAdsAndroid = "no_ads";
const String productNoAdsIOS = "NoAds";
const String productSearch = "search";

const String keyPreferredLanguage = "pref_language";
const String keyMyRegion = "my_region";
const String keyAlwaysMyRegion = "always_my_region";
const String keyRateState = "rate_state";
const String keyRateCount = "rate_count";
const int rateCountInitial = 5;
const String rateStateInitial = "";
const String rateStateNever = "never";
const String rateStateShould = "should";
const String rateStateDid = "did";

const String playStore = "market://details?id=sk.ab.herbs";
const String playStorePlus = "market://details?id=sk.ab.herbsplus";
const String appStore = "https://itunes.apple.com/us/app/whats-that-flower/id1449982118?mt=8&action=write-review";

const String languageLatin = "la";
const String languageEnglish = "en";
const String languageSlovak = "sk";
const String languageCzech = "cs";
const String languageGTSuffix = "-GT";
const String heightUnitOfMeasure = "cm";

const String webUrl = "https://whatsthatflower.com/";
const String googleTranslateEndpoint = "https://translation.googleapis.com/language/translate/v2";

const String storageEndpoit = "https://storage.googleapis.com/abherbs-resources/";
const String storageFamilies = "families/";
const String storagePhotos = "photos/";
const String defaultExtension = ".webp";
const String thumbnailsDir = "/.thumbnails";

const String firebaseCounts = 'counts_4_v2';
const String firebaseLists = 'lists_4_v2';
const String firebasePlants = 'plants_v2';
const String firebaseSearch = 'search_v2';
const String firebaseAPGIV = 'APG IV_v2';
const String firebasePlantHeaders = 'plants_headers';
const String firebaseTranslations = 'translations';
const String firebaseTranslationsTaxonomy = 'translations_taxonomy';

const String firebaseRootTaxon = 'Eukaryota';
const String firebaseAPGType = "type";
const String firebaseAPGList = "list";
const String firebaseAPGCount = "count";

const int adsFrequency = -1;

void launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

Future<void> launchURLF(String url) {
  return canLaunch(url).then((value) {
    if (value) {
      return launch(url);
    } else {
      throw 'Could not launch $url';
    }
  });
}

String getTaxonLabel(BuildContext context, String taxon) {
  switch (taxon) {
    case 'Superregnum':
      return S.of(context).taxonomy_superregnum;
    case 'Regnum':
      return S.of(context).taxonomy_regnum;
    case 'Cladus':
      return S.of(context).taxonomy_cladus;
    case 'Ordo':
      return S.of(context).taxonomy_ordo;
    case 'Familia':
      return S.of(context).taxonomy_familia;
    case 'Subfamilia':
      return S.of(context).taxonomy_subfamilia;
    case 'Tribus':
      return S.of(context).taxonomy_tribus;
    case 'Subtribus':
      return S.of(context).taxonomy_subtribus;
    case 'Genus':
      return S.of(context).taxonomy_genus;
    case 'Subgenus':
      return S.of(context).taxonomy_subgenus;
    case 'Supersectio':
      return S.of(context).taxonomy_supersectio;
    case 'Sectio':
      return S.of(context).taxonomy_sectio;
    case 'Subsectio':
      return S.of(context).taxonomy_subsectio;
    case 'Serie':
      return S.of(context).taxonomy_serie;
    case 'Subserie':
      return S.of(context).taxonomy_subserie;
    default:
      return S.of(context).taxonomy_unknown;
  }
}

String getProductTitle(BuildContext context, String productId, String defaultTitle) {
  switch (productId) {
    case productNoAdsAndroid:
    case productNoAdsIOS:
      return S.of(context).product_no_ads_title;
    case productSearch:
      return S.of(context).product_search_title;
    default:
      return defaultTitle;
  }
}

String getProductDescription(BuildContext context, String productId, String defaultDescription) {
  switch (productId) {
    case productNoAdsAndroid:
    case productNoAdsIOS:
      return S.of(context).product_no_ads_description;
    case productSearch:
      return S.of(context).product_search_description;
    default:
      return defaultDescription;
  }
}

Icon getIcon(String productId) {
  switch (productId) {
    case productSearch:
      return Icon(Icons.search);
  }
}

List<Widget> getActions(BuildContext context, Function(String) onChangeLanguage, Function() onBuyProduct) {
  var _actions = <Widget>[];
  _actions.add(IconButton(
    icon: getIcon(productSearch),
    onPressed: () {
      if (Purchases.isSearch()) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Search(Localizations.localeOf(context), onChangeLanguage, onBuyProduct)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnhacementsScreen(onChangeLanguage, onBuyProduct)),
        );
      }
    },
  ));

  return _actions;
}

Widget getAdMobBanner() {
  return Container(
    height: getFABPadding(),
  );
}

String getLanguageCode(String code) {
  return code == 'nb' ? 'no' : code;
}

double getFABPadding() {
  return Purchases.isNoAds() ? 0.0 : 50.0;
}
