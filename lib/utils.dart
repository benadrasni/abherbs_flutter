import 'package:url_launcher/url_launcher.dart';

const String keyPreferredLanguage = "pref_language";
const String keyMyRegion = "my_region";
const String keyAlwaysMyRegion = "always_my_region";

const String languageEnglish = "en";
const String languageSlovak = "sk";
const String languageGTSuffix = "-GT";

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

void launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
