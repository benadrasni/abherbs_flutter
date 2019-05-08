import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/detail/plant_detail.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/keys.dart';
import 'package:abherbs_flutter/observations/observations.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/purchase/enhancements.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/search/search.dart';
import 'package:abherbs_flutter/search/search_photo.dart';
import 'package:abherbs_flutter/settings/offline.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:exif/exif.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const String productNoAdsAndroid = "no_ads";
const String productNoAdsIOS = "NoAds";
const String productSearch = "search";
const String productCustomFilter = "custom_filter";
const String productOffline = "offline";
const String productObservations = "observations";
const String productPhotoSearch = "search_by_photo";
const String subscriptionMonthly = "store_photos_monthly";
const String subscriptionYearly = "store_photos_yearly";

const String keyLanguageAndCountry = "language_country";
const String keyPreferredLanguage = "pref_language";
const String keyMyRegion = "my_region";
const String keyAlwaysMyRegion = "always_my_region";
const String keyOffline = "offline";
const String keyScaleDownPhotos = "scale_down_photos";
const String keyOfflinePlant = "offline_plant";
const String keyOfflineFamily = "offline_family";
const String keyOfflineDB = "offline_db";
const String keyRateState = "rate_state";
const String keyRateCount = "rate_count";
const String keyMyFilter = "my_filter";
const String keyPurchases = "purchases";
const String keyToken = "token";
const int rateCountInitial = 5;
const String rateStateInitial = "";
const String rateStateNever = "never";
const String rateStateShould = "should";
const String rateStateDid = "did";

const int timer = 300;

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
const String termsOfUseUrl = "https://storage.googleapis.com/abherbs-resources/misc/TermsOfServiceofWhatsthatflower.htm";
const String privacyPolicyUrl = "https://storage.googleapis.com/abherbs-resources/misc/PrivacyPolicyofWhatsthatflower.htm";
const String googleTranslateEndpoint = "https://translation.googleapis.com/language/translate/v2";
const String googleMapsEndpoint = "https://maps.googleapis.com/maps/api/staticmap?";

const String storageBucket = "gs://abherbs-resources";
const String storageEndpoint = "https://storage.googleapis.com/abherbs-resources/";
const String storageFamilies = "families/";
const String storagePhotos = "photos/";
const String storageObservations = "observations/";
const String defaultExtension = ".webp";
const String defaultPhotoExtension = ".jpg";
const String thumbnailsDir = "/.thumbnails";
const double imageSize = 512;

const int firebaseCacheSize = 1024 * 1024 * 20;
const String firebaseCounts = 'counts_4_v2';
const String firebaseLists = 'lists_4_v2';
const String firebasePlants = 'plants_v2';
const String firebaseSearch = 'search_v3';
const String firebaseAPGIV = 'APG IV_v3';
const String firebasePlantHeaders = 'plants_headers';
const String firebaseTranslations = 'translations';
const String firebaseTranslationsTaxonomy = 'translations_taxonomy';
const String firebasePlantsToUpdate = "plants_to_update";
const String firebaseFamiliesToUpdate = "families_to_update";
const String firebaseVersions = "versions";
const String firebaseUsers = "users";
const String firebaseUsersPhotoSearch = "users_photo_search";
const String firebasePromotions = "promotions";
const String firebaseSearchPhoto = 'search_photo';
const String firebaseSettingsGenericEntities = "settings/generic_entities";
const String firebaseObservationsPublic = "observations/public";
const String firebaseObservationsPrivate = "observations/by users";
const String firebaseObservationsByDate = "by date";
const String firebaseObservationsByPlant = "by plant";

const String firebaseRootTaxon = 'Eukaryota';
const String firebaseAPGType = "type";
const String firebaseAttributeFreebase = "freebase";
const String firebaseAttributeList = "list";
const String firebaseAttributeCount = "count";
const String firebaseAttributeIOS = "ios";
const String firebaseAttributeAndroid = "android";
const String firebaseAttributeLastUpdate = "db_update";
const String firebaseAttributeName = "name";
const String firebaseAttributeFamily = "family";
const String firebaseAttributeUrl = "url";
const String firebaseAttributeLabel = "label";
const String firebaseAttributeOrder = "order";
const String firebaseAttributeStatus = "status";
const String firebaseAttributeOldVersion = "old version";
const String firebaseAttributeLifetimeSubscription = "lifetime subscription";
const String firebaseAttributeToken = "token";
const String firebaseAttributePurchases = "purchases";
const String firebaseAttributeSearch = "search";
const String firebaseAttributeSearchByPhoto = "search_by_photo";
const String firebaseAttributeObservations = "observations";
const String firebaseAttributeFrom = "from";
const String firebaseAttributeTo = "to";
const String firebaseAttributeFavorite = "favorites";
const String firebaseAttributeEntity = "m";
const String firebaseAttributeAnonymous = "anonymous";
const String firebaseAttributeIsLabel = "is_label";

const String firebaseValuePrivate = "private";
const String firebaseValueReview = "review";
const String firebaseValuePublic = "public";

const String mapModeView = "view";
const String mapModeEdit = "edit";

const String notificationAttributeData = "data";

final DatabaseReference rootReference = FirebaseDatabase.instance.reference();
final DatabaseReference countsReference = rootReference.child(firebaseCounts);
final DatabaseReference listsReference = rootReference.child(firebasePlantHeaders);
final DatabaseReference keysReference = rootReference.child(firebaseLists);
final DatabaseReference translationsReference = rootReference.child(firebaseTranslations);
final DatabaseReference translationsTaxonomyReference = rootReference.child(firebaseTranslationsTaxonomy);
final DatabaseReference plantsReference = rootReference.child(firebasePlants);
final DatabaseReference searchReference = rootReference.child(firebaseSearch);
final DatabaseReference apgIVReference = rootReference.child(firebaseAPGIV);
final DatabaseReference publicObservationsReference = rootReference.child(firebaseObservationsPublic);
final DatabaseReference privateObservationsReference = rootReference.child(firebaseObservationsPrivate);
final DatabaseReference usersReference = rootReference.child(firebaseUsers);

Map<String, String> translationCache = {};

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}

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

Future<void> _logPromotionEvent(event) async {
  await FirebaseAnalytics().logEvent(name: 'promotion', parameters: {
    'feature': event
  });
}

String getMapImageUrl(double latitude, double longitude, double width, double height) {
  String url = googleMapsEndpoint;
  url += 'zoom=11';
  url += '&size=' + width.round().toString() + 'x' + height.round().toString();
  url += '&markers=color:red|' + latitude.toString() + ',' + longitude.toString();
  url += '&key=' + mapsAPIKey;
  return url;
}

double getLatitudeFromExif(IfdTag latitudeRef, IfdTag latitude) {
  if (latitudeRef == null || latitude == null) return null;
  double latDegrees = latitude.values[0].numerator / latitude.values[0].denominator;
  double latMinutes = latitude.values[1].numerator / latitude.values[1].denominator;
  double latSeconds = latitude.values[2].numerator / latitude.values[2].denominator;

  int northSouth = latitudeRef.toString() == 'N' ? 1 : -1;
  return northSouth * (latDegrees + latMinutes / 60 + latSeconds / 60 / 60);
}

double getLongitudeFromExif(IfdTag longitudeRef, IfdTag longitude) {
  if (longitudeRef == null || longitude == null) return null;
  double longDegrees = longitude.values[0].numerator / longitude.values[0].denominator;
  double longMinutes = longitude.values[1].numerator / longitude.values[1].denominator;
  double longSeconds = longitude.values[2].numerator / longitude.values[2].denominator;

  int eastWest = longitudeRef.toString() == 'E' ? 1 : -1;
  return eastWest * (longDegrees + longMinutes / 60 + longSeconds / 60 / 60);
}

DateTime getDateTimeFromExif(IfdTag dateTime) {
  if (dateTime == null) return null;
  var dateParts = dateTime.toString().split(' ');
  var datePart = dateParts[0].split(':');
  var timePart = dateParts[1].split(':');
  return DateTime(
      int.parse(datePart[0]), int.parse(datePart[1]), int.parse(datePart[2]), int.parse(timePart[0]), int.parse(timePart[1]), int.parse(timePart[2]));
}

Widget getImage(String url, Widget placeholder, {double width, double height, BoxFit fit}) {
  return FutureBuilder<File>(
      future: Offline.getLocalFile(url),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            return Image.file(snapshot.data, fit: fit ?? BoxFit.contain, width: width, height: height);
          }

          return CachedNetworkImage(
            fit: fit ?? BoxFit.contain,
            width: width,
            height: height,
            placeholder: (context, url) => placeholder,
            errorWidget: (context, url, error) => Icon(Icons.error, color: Theme.of(context).buttonColor, size: 80.0),
            imageUrl: storageEndpoint + url,
          );
        } else {
          return placeholder;
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

Widget getProductIcon(BuildContext context, String productId) {
  switch (productId) {
    case productNoAdsAndroid:
    case productNoAdsIOS:
      return Icon(Icons.remove_shopping_cart);
    case productSearch:
      return Icon(Icons.search);
    case productCustomFilter:
      return Icon(Icons.search);
    case productOffline:
      return Icon(Icons.signal_wifi_off);
    case productObservations:
      return Icon(Icons.remove_red_eye);
    case productPhotoSearch:
      return Icon(Icons.photo_camera);
    case subscriptionMonthly:
      return Icon(Icons.calendar_today);
    case subscriptionYearly:
      return Icon(Icons.calendar_today);
    default:
      return null;
  }
}

String getProductTitle(BuildContext context, String productId, String defaultTitle) {
  switch (productId) {
    case productNoAdsAndroid:
    case productNoAdsIOS:
      return S.of(context).product_no_ads_title;
    case productSearch:
      return S.of(context).product_search_title;
    case productCustomFilter:
      return S.of(context).product_custom_filter_title;
    case productOffline:
      return S.of(context).product_offline_title;
    case productObservations:
      return S.of(context).product_observations_title;
    case productPhotoSearch:
      return S.of(context).product_photo_search_title;
    case subscriptionMonthly:
      return S.of(context).subscription_monthly_title;
    case subscriptionYearly:
      return S.of(context).subscription_yearly_title;
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
    case productCustomFilter:
      return S.of(context).product_custom_filter_description;
    case productOffline:
      return S.of(context).product_offline_description;
    case productObservations:
      return S.of(context).product_observations_description;
    case productPhotoSearch:
      return S.of(context).product_photo_search_description;
    case subscriptionMonthly:
      return S.of(context).subscription_monthly_description;
    case subscriptionYearly:
      return S.of(context).subscription_yearly_description;
    default:
      return defaultDescription;
  }
}

String getProductPeriod(BuildContext context, String productId) {
  switch (productId) {
    case 'P1M':
    case 'MONTH':
      return S.of(context).subscription_period_month;
    case 'P1Y':
    case 'YEAR':
      return S.of(context).subscription_period_year;
    default:
      return '';
  }
}

Icon getIcon(String productId) {
  switch (productId) {
    case productSearch:
      return Icon(Icons.search);
    case productObservations:
      return Icon(Icons.remove_red_eye);
    case productPhotoSearch:
      return Icon(Icons.photo_camera);
    default:
      return Icon(Icons.mood_bad);
  }
}

List<Widget> getActions(BuildContext mainContext, GlobalKey<ScaffoldState> key, FirebaseUser currentUser, Function(String) onChangeLanguage,
    Map<String, String> filter) {
  DateFormat dateFormat = new DateFormat.yMMMMd(Localizations.localeOf(mainContext).toString());
  var _actions = <Widget>[];

  // search by photo
  _actions.add(IconButton(
    icon: getIcon(productPhotoSearch),
    onPressed: () {
      Connectivity().checkConnectivity().then((result) {
        if (result == ConnectivityResult.none) {
          infoDialog(mainContext, S.of(mainContext).no_connection_title, S.of(mainContext).no_connection_content);
        } else {
          if (Purchases.isPhotoSearch()) {
            if (currentUser != null) {
              Navigator.push(
                mainContext,
                MaterialPageRoute(builder: (context) => SearchPhoto(currentUser, Localizations.localeOf(context), onChangeLanguage)),
              );
            } else {
              photoSearchDialog(mainContext, key);
            }
          } else if (Purchases.isSearchByPhotoPromotion != null && Purchases.isSearchByPhotoPromotion) {
            infoBuyDialog(mainContext, S.of(mainContext).promotion_title,
                    S.of(mainContext).promotion_content(dateFormat.format(Purchases.searchByPhotoPromotionTo)))
                .then((value) {
                  if (value != null && value) {
                    Navigator.push(
                      mainContext,
                      MaterialPageRoute(builder: (context) => EnhancementsScreen(onChangeLanguage, filter)),
                    );
                  } else {
                    _logPromotionEvent('search_by_photo');
                    Navigator.push(
                      mainContext,
                      MaterialPageRoute(
                          builder: (context) => SearchPhoto(currentUser, Localizations.localeOf(context), onChangeLanguage)),
                    );
                  }
            });
          } else {
            infoBuyDialog(mainContext, S.of(mainContext).product_photo_search_title,
                S.of(mainContext).product_photo_search_description)
                .then((value) {
              if (value != null && value) {
                Navigator.push(
                  mainContext,
                  MaterialPageRoute(builder: (context) => EnhancementsScreen(onChangeLanguage, filter)),
                );
              }
            });
          }
        }
      });
    },
  ));

  // observations
  _actions.add(IconButton(
    icon: getIcon(productObservations),
    onPressed: () {
      Connectivity().checkConnectivity().then((result) {
        if (result == ConnectivityResult.none) {
          infoDialog(mainContext, S.of(mainContext).no_connection_title, S.of(mainContext).no_connection_content);
        } else {
          if (Purchases.isObservations()) {
            if (currentUser != null) {
              Navigator.push(
                mainContext,
                MaterialPageRoute(
                    builder: (context) => Observations(currentUser, Localizations.localeOf(context), onChangeLanguage, false)),
              );
            } else {
              observationDialog(mainContext, key);
            }
          } else if (Purchases.isObservationPromotion != null && Purchases.isObservationPromotion) {
            infoBuyDialog(mainContext, S.of(mainContext).promotion_title,
                    S.of(mainContext).promotion_content(dateFormat.format(Purchases.observationPromotionTo)))
                .then((value) {
                  if (value != null && value) {
                    Navigator.push(
                      mainContext,
                        MaterialPageRoute(builder: (context) => EnhancementsScreen(onChangeLanguage, filter)),
                    );
                  } else {
                    _logPromotionEvent('observation');
                    Navigator.push(
                      mainContext,
                      MaterialPageRoute(
                          builder: (context) => Observations(currentUser, Localizations.localeOf(context), onChangeLanguage, true)),
                    );
                  }
            });
          } else {
            infoBuyDialog(mainContext, S.of(mainContext).product_observations_title,
                S.of(mainContext).product_observations_description)
                .then((value) {
              if (value != null && value) {
                Navigator.push(
                  mainContext,
                  MaterialPageRoute(builder: (context) => EnhancementsScreen(onChangeLanguage, filter)),
                );
              }
            });
          }
        }
      });
    },
  ));

  // search by name or taxonomy
  _actions.add(IconButton(
    icon: getIcon(productSearch),
    onPressed: () {
      if (Purchases.isSearch()) {
        Navigator.push(
          mainContext,
          MaterialPageRoute(builder: (context) => Search(Localizations.localeOf(context), onChangeLanguage)),
        );
      } else if (Purchases.isSearchPromotion != null && Purchases.isSearchPromotion) {
        infoBuyDialog(
                mainContext, S.of(mainContext).promotion_title, S.of(mainContext).promotion_content(dateFormat.format(Purchases.searchPromotionTo)))
            .then((value) {
          if (value != null && value) {
            Navigator.push(
              mainContext,
              MaterialPageRoute(builder: (context) => EnhancementsScreen(onChangeLanguage, filter)),
            );
          } else {
            _logPromotionEvent('search');
            Navigator.push(
              mainContext,
              MaterialPageRoute(builder: (context) => Search(Localizations.localeOf(context), onChangeLanguage)),
            );
          }
        });
      } else {
        infoBuyDialog(mainContext, S.of(mainContext).product_search_title,
            S.of(mainContext).product_search_description)
            .then((value) {
          if (value != null && value) {
            Navigator.push(
              mainContext,
              MaterialPageRoute(builder: (context) => EnhancementsScreen(onChangeLanguage, filter)),
            );
          }
        });
      }
    },
  ));

  // favorites
  _actions.add(FutureBuilder<int>(future: Future<int>(() {
    if (currentUser != null) {
      return usersReference.child(currentUser.uid).child(firebaseAttributeFavorite).once().then((snapshot) {
        if (snapshot.value != null) {
          if (snapshot.value is List) {
            int i = 0;
            snapshot.value.forEach((value) {
              if (value != null) {
                i++;
              }
            });
            return i;
          } else {
            return snapshot.value.length;
          }
        }
        return 0;
      });
    }
    return 0;
  }), builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
    return IconButton(
      icon: Icon(Icons.favorite),
      onPressed: () {
        if (snapshot.connectionState == ConnectionState.done) {
          if (currentUser != null) {
            String path = '/' + firebaseUsers + '/' + currentUser.uid + '/' + firebaseAttributeFavorite;
            Navigator.push(
              mainContext,
              MaterialPageRoute(builder: (context) => PlantList(onChangeLanguage, {}, S.of(mainContext).favorite_empty, snapshot.data.toString(), path)),
            );
          } else {
            favoriteDialog(mainContext, key);
          }
        }
      },
    );
  }));

  return _actions;
}

void goToDetail(State state, BuildContext context, Locale myLocale, String name, Function(String) onChangeLanguage,
    Map<String, String> filter) {
  plantsReference.child(name).once().then((DataSnapshot snapshot) {
    if (snapshot.value != null && snapshot.value['id'] != null) {
      if (state.mounted && context != null) {
        Plant plant = Plant.fromJson(snapshot.key, snapshot.value);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlantDetail(myLocale, onChangeLanguage, filter, plant)),
        );
      }
    } else {
      plantsReference.child(name).keepSynced(true);
      translationsReference.child(myLocale.languageCode).child(name).keepSynced(true);
      if (myLocale.languageCode != languageEnglish) {
        translationsReference.child(languageEnglish).child(name).keepSynced(true);
        translationsReference.child(myLocale.languageCode + languageGTSuffix).child(name).keepSynced(true);
      }
    }
  });
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

Future<bool> verifyPurchase(PurchaseDetails purchaseDetails) {
  return Future<bool>.value(true);
}
