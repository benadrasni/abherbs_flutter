import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_location.dart';
import 'package:abherbs_flutter/guide/habitat_page.dart';
import 'package:abherbs_flutter/guide/person_page.dart';
import 'package:abherbs_flutter/guide/petal_page.dart';
import 'package:abherbs_flutter/guide/results_page.dart';
import 'package:abherbs_flutter/guide/search_page.dart';
import 'package:abherbs_flutter/guide/sign_in_page.dart';
import 'package:abherbs_flutter/guide/species_page.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/purchase/enhancements.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/search/search_photo.dart';
import 'package:abherbs_flutter/settings/setting_pref_language.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

void openGuideSearch(
  BuildContext context, {
  bool fromBook = false,
  VoidCallback? onShowFind,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GuideSearchPage(
        fromBook: fromBook,
        onShowFind: onShowFind,
        onOpenPlant: openGuidePlant,
        onOpenTaxon: openGuideTaxon,
        onOpenCamera: openGuideCamera,
      ),
      settings: const RouteSettings(name: 'GuideSearch'),
    ),
  );
}

void openGuideTaxon(BuildContext context, String listPath) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PlantList(
        const <String, String>{},
        '',
        rootReference.child(listPath),
      ),
      settings: const RouteSettings(name: 'PlantList'),
    ),
  );
}

void openGuideAccount(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guidePersonRouteName),
      builder: (context) => GuidePersonPage(
        onSignIn: openGuideSignIn,
        onSignOut: guideSignOut,
        onRestore: guideRestorePurchases,
        onLanguage: openGuideLanguage,
        onFieldGuide: openGuideFieldGuide,
        onOffline: openGuideOffline,
      ),
    ),
  );
}

Future<void> guideSignOut(BuildContext context) {
  return Auth.signOut();
}

Future<void> guideRestorePurchases(BuildContext context) async {
  final store = InAppPurchase.instance;
  final available = await store.isAvailable();
  if (!context.mounted) return;
  if (!available) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).product_purchase_failed)),
    );
    return;
  }
  Purchases.purchases = {};
  await store.restorePurchases();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(S.of(context).guide_person_restoring)),
  );
}

Future<void> openGuideLanguage(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SettingPrefLanguage(),
      settings: const RouteSettings(name: 'SettingPrefLanguage'),
    ),
  );
  if (!context.mounted) return;
  final language = await Prefs.getStringF(keyPreferredLanguage);
  if (!context.mounted) return;
  App.setLocale(context, language);
  await FirebaseAnalytics.instance.logEvent(
    name: 'setting',
    parameters: {
      'type': 'preferred_language',
      'language': language.isEmpty ? 'default' : language,
    },
  );
}

Future<void> openGuideFieldGuide(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EnhancementsScreen(const <String, String>{}),
      settings: const RouteSettings(name: 'Enhancements'),
    ),
  );
}

Future<void> openGuideOffline(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SettingsScreen(const <String, String>{}),
      settings: const RouteSettings(name: 'Settings'),
    ),
  );
}

void openGuideColor(BuildContext context, String colorId) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guideHabitatRouteName),
      builder: (context) => GuideHabitatPage(
        colorId: colorId,
        onContinue: (habitatId) => openGuidePetals(
          context,
          colorId: colorId,
          habitatId: habitatId,
        ),
      ),
    ),
  );
}

void openGuidePetals(
  BuildContext context, {
  required String colorId,
  String? habitatId,
}) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guidePetalRouteName),
      builder: (context) => GuidePetalPage(
        colorId: colorId,
        habitatId: habitatId,
        onContinue: (petalId) => openGuideResults(
          context,
          colorId: colorId,
          habitatId: habitatId,
          petalId: petalId,
        ),
      ),
    ),
  );
}

void openGuideResults(
  BuildContext context, {
  required String colorId,
  String? habitatId,
  required String petalId,
}) {
  final language = Localizations.localeOf(context).languageCode;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guideResultsRouteName),
      builder: (context) => GuideResultsPage(
        colorId: colorId,
        habitatId: habitatId,
        petalId: petalId,
        loadResults: (regionId) => loadGuideResults(
          colorId: colorId,
          habitatId: habitatId,
          petalId: petalId,
          regionId: regionId,
          languageCode: language,
        ),
        loadPrefs: loadGuideResultPrefs,
        savePrefs: saveGuideResultPrefs,
        loadSeen: loadGuideSeenNames,
        loadRegionCounts: () => loadGuideRegionCounts(
          colorId: colorId,
          habitatId: habitatId,
          petalId: petalId,
        ),
        locate: locateGuideRegion,
        onOpenPlant: openGuidePlant,
        onTryPhoto: openGuideCamera,
      ),
    ),
  );
}

void openGuideList(BuildContext context, GuideListCover cover) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PlantList(const <String, String>{}, '', cover.path),
      settings: const RouteSettings(name: 'PlantList'),
    ),
  );
}

void openGuidePlant(BuildContext context, String name) {
  unawaited(
    FirebaseAnalytics.instance
        .logSelectContent(contentType: 'plant', itemId: name)
        .catchError((Object error) => debugPrint('guide species: $error')),
  );
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guideSpeciesRouteName),
      builder: (context) => GuideSpeciesPage(
        name: name,
        load: (languageCode) => loadGuideSpecies(name, languageCode),
        onShowSeen: GuideTabs.showSeen,
      ),
    ),
  );
}

Future<void> openGuideCamera(BuildContext context) async {
  final result = await Connectivity().checkConnectivity();
  if (!context.mounted) return;
  if (result.contains(ConnectivityResult.none)) {
    infoDialog(
      context,
      S.of(context).no_connection_title,
      S.of(context).no_connection_content,
    );
    return;
  }
  if (Purchases.isPhotoSearch()) {
    _pushPhoto(context);
    return;
  }

  final duringPromotion = Purchases.isSearchByPhotoPromotion;
  final content = duringPromotion
      ? S.of(context).promotion_content(
            DateFormat.yMMMMd(Localizations.localeOf(context).toString())
                .format(Purchases.searchByPhotoPromotionTo),
          )
      : S.of(context).product_photo_search_description;
  final title = duringPromotion
      ? S.of(context).promotion_title
      : S.of(context).product_photo_search_title;
  final value = await infoBuyDialog(
    context,
    title,
    content,
    remoteConfigSearchByPhotoVideo,
    S.of(context).credit_use_photo_search,
  );
  if (!context.mounted || value != 2) {
    if (duringPromotion && value != 2 && context.mounted) {
      await FirebaseAnalytics.instance.logEvent(
        name: 'promotion',
        parameters: {'feature': 'search_by_photo'},
      );
      if (!context.mounted) return;
      _pushPhoto(context);
    }
    return;
  }
  _pushPhoto(context);
}

void _pushPhoto(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SearchPhoto(Localizations.localeOf(context)),
      settings: const RouteSettings(name: 'SearchPhoto'),
    ),
  );
}
