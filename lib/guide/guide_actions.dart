import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/habitat_page.dart';
import 'package:abherbs_flutter/guide/petal_page.dart';
import 'package:abherbs_flutter/guide/search_page.dart';
import 'package:abherbs_flutter/plant_list.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/search/search_photo.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/utils/dialogs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
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
  final state = context.findAncestorStateOfType<State>();
  if (state == null) return;
  goToDetail(state, context, Localizations.localeOf(context), name, const {});
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
