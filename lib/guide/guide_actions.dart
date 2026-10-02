import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/camera_page.dart';
import 'package:abherbs_flutter/guide/field_guide_page.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_location.dart';
import 'package:abherbs_flutter/guide/guide_person.dart';
import 'package:abherbs_flutter/guide/guide_results.dart';
import 'package:abherbs_flutter/guide/habitat_page.dart';
import 'package:abherbs_flutter/guide/language_page.dart';
import 'package:abherbs_flutter/guide/list_page.dart';
import 'package:abherbs_flutter/guide/person_page.dart';
import 'package:abherbs_flutter/guide/petal_page.dart';
import 'package:abherbs_flutter/guide/results_page.dart';
import 'package:abherbs_flutter/guide/search_page.dart';
import 'package:abherbs_flutter/guide/sign_in_page.dart';
import 'package:abherbs_flutter/guide/species_page.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
export 'package:abherbs_flutter/guide/field_guide_page.dart'
    show openGuideFieldGuide;
export 'package:abherbs_flutter/guide/species_page.dart' show openGuidePlant;

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
        onOpenTaxon: (context, path) => openGuideTaxon(
          context,
          path,
          backLabel: S.of(context).guide_back_search,
        ),
        onOpenCamera: openGuideCamera,
      ),
      settings: const RouteSettings(name: guideSearchRouteName),
    ),
  );
}

void openGuideTaxon(
  BuildContext context,
  String listPath, {
  String? title,
  String? backLabel,
}) {
  openGuideTaxonList(
    context,
    listPath: listPath,
    title: title,
    backLabel: backLabel ?? S.of(context).guide_back,
    onOpenPlant: openGuidePlant,
    onTryPhoto: openGuideCamera,
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
  final saved = await Prefs.getStringF(keyPreferredLanguage);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guideLanguageRouteName),
      builder: (context) => GuideLanguagePage(
        selectedKey: saved,
        // The phone's language, not the language currently on screen.
        phoneName: guideLanguageName(languages, '', getDeviceLocale()),
        options: guideLanguageOptions(languages),
        onChoose: _storeGuideLanguage,
      ),
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

Future<void> _storeGuideLanguage(String key) async {
  if (key.isEmpty) {
    await Prefs.remove(keyPreferredLanguage);
    return;
  }
  await Prefs.setString(keyPreferredLanguage, key);
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

void openGuideList(
  BuildContext context,
  GuideListCover cover, {
  String? backLabel,
}) {
  final back = backLabel ?? S.of(context).guide_back;
  final language = Localizations.localeOf(context).languageCode;
  switch (guideCustomLayout(cover)) {
    case GuideCustomLayout.fresh:
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: guideCustomRouteName),
          builder: (context) => GuideNewPage(
            backLabel: back,
            loadDays: () => loadGuideNewDays(language),
            loadSeen: loadGuideSeenNames,
            onOpenPlant: openGuidePlant,
          ),
        ),
      );
    case GuideCustomLayout.years:
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: guideCustomRouteName),
          builder: (context) => GuideYearPage(
            title: cover.title,
            backLabel: back,
            loadList: () => loadGuideYearList(cover.path, language),
            loadSeen: loadGuideSeenNames,
            onOpenPlant: openGuidePlant,
          ),
        ),
      );
    case GuideCustomLayout.grid:
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: guideCustomRouteName),
          builder: (context) => GuideResultsPage(
            colorId: '',
            habitatId: null,
            petalId: '',
            listTitle: cover.title,
            listBackLabel: back,
            loadResults: (_) => loadGuideListedPlants(cover.path, language),
            loadPrefs: () async => const GuideResultPrefs(),
            savePrefs: (_) async {},
            loadSeen: loadGuideSeenNames,
            loadRegionCounts: () async => const {},
            locate: () async => null,
            onOpenPlant: openGuidePlant,
            onTryPhoto: openGuideCamera,
          ),
        ),
      );
  }
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
  _pushCamera(context);
}

void _pushCamera(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: guideCameraRouteName),
      builder: (context) => const GuideCameraPage(),
    ),
  );
}
