import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

const String languageEnglish = "en";
const String languageSlovak = "sk";
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
const String firebasePlantHeaders = 'plants_headers';
const String firebaseTranslations = 'translations';
const String firebaseTranslationsTaxonomy = 'translations_taxonomy';

const int adsFrequency = 2;

void launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

String getTaxonLabel(BuildContext context, String taxon) {
  switch (taxon) {
    case 'Superregnum': return S.of(context).taxonomy_superregnum;
    case 'Regnum': return S.of(context).taxonomy_regnum;
    case 'Cladus': return S.of(context).taxonomy_cladus;
    case 'Ordo': return S.of(context).taxonomy_ordo;
    case 'Familia': return S.of(context).taxonomy_familia;
    case 'Subfamilia': return S.of(context).taxonomy_subfamilia;
    case 'Tribus': return S.of(context).taxonomy_tribus;
    case 'Subtribus': return S.of(context).taxonomy_subtribus;
    case 'Genus': return S.of(context).taxonomy_genus;
    case 'Subgenus': return S.of(context).taxonomy_subgenus;
    case 'Supersectio': return S.of(context).taxonomy_supersectio;
    case 'Sectio': return S.of(context).taxonomy_sectio;
    case 'Subsectio': return S.of(context).taxonomy_subsectio;
    case 'Serie': return S.of(context).taxonomy_serie;
    case 'Subserie': return S.of(context).taxonomy_subserie;
    default: return S.of(context).taxonomy_unknown;
  }
}

Widget getAdMobBanner({AdmobBannerSize bannerSize = AdmobBannerSize.BANNER}) {
  return Container(
    padding: EdgeInsets.all(5.0),
    child: AdmobBanner(adUnitId: bannerAdUnitId, adSize: bannerSize, listener: (AdmobAdEvent event, Map<String, dynamic> args) {}),
  );
}
