import 'package:abherbs_flutter/data/utils.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum GuideFieldGuidePlan { yearly, monthly }

/// Oxeye daisy plate on the Field Guide page.
const guideFieldGuidePlatePath =
    'photos/Asterales/Asteraceae/Leucanthemum_vulgare/Leucanthemum_vulgare@1600.webp';

String guideFieldGuideProductId(GuideFieldGuidePlan plan) {
  return plan == GuideFieldGuidePlan.yearly
      ? fieldGuideYearly
      : fieldGuideMonthly;
}

class GuideFieldGuideOffer {
  final GuideFieldGuidePlan plan;
  final String productId;
  final String? price;
  final bool owned;

  const GuideFieldGuideOffer({
    required this.plan,
    required this.productId,
    required this.price,
    required this.owned,
  });
}

class GuideFieldGuideCatalog {
  final GuideFieldGuideOffer yearly;
  final GuideFieldGuideOffer monthly;
  final bool storeAvailable;

  /// An active photo-storage plan. It already is Field Guide.
  final bool photoStorage;
  final String? error;

  const GuideFieldGuideCatalog({
    required this.yearly,
    required this.monthly,
    required this.storeAvailable,
    required this.photoStorage,
    this.error,
  });

  bool get coveredByOlderPlan =>
      photoStorage && !yearly.owned && !monthly.owned;

  GuideFieldGuidePlan get initialPlan {
    if (monthly.owned && !yearly.owned) return GuideFieldGuidePlan.monthly;
    return GuideFieldGuidePlan.yearly;
  }

  GuideFieldGuideOffer offer(GuideFieldGuidePlan plan) {
    return plan == GuideFieldGuidePlan.yearly ? yearly : monthly;
  }

  GuideFieldGuideCatalog withOwnership(Set<String> owned) {
    return guideFieldGuideCatalog(
      storeAvailable: storeAvailable,
      yearlyPrice: yearly.price,
      monthlyPrice: monthly.price,
      owned: owned,
      error: error,
    );
  }
}

class GuideFieldGuideLoaded {
  final GuideFieldGuideCatalog catalog;
  final Map<String, ProductDetails> products;

  const GuideFieldGuideLoaded({
    required this.catalog,
    this.products = const {},
  });
}

GuideFieldGuideCatalog guideFieldGuideCatalog({
  required bool storeAvailable,
  required String? yearlyPrice,
  required String? monthlyPrice,
  required Set<String> owned,
  String? error,
}) {
  return GuideFieldGuideCatalog(
    yearly: GuideFieldGuideOffer(
      plan: GuideFieldGuidePlan.yearly,
      productId: fieldGuideYearly,
      price: _price(yearlyPrice),
      owned: owned.contains(fieldGuideYearly),
    ),
    monthly: GuideFieldGuideOffer(
      plan: GuideFieldGuidePlan.monthly,
      productId: fieldGuideMonthly,
      price: _price(monthlyPrice),
      owned: owned.contains(fieldGuideMonthly),
    ),
    storeAvailable: storeAvailable,
    photoStorage: owned.contains(subscriptionMonthly) ||
        owned.contains(subscriptionYearly),
    error: error,
  );
}

String? _price(String? price) {
  final trimmed = price?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class GuideFieldGuideChoice {
  final int buyIndex;
  final String displayPrice;

  const GuideFieldGuideChoice({
    required this.buyIndex,
    required this.displayPrice,
  });
}

/// Store rows for one product id.
///
/// A free introductory phase is the one to buy when a paid phase is also
/// present. The price on the row is the paid phase.
GuideFieldGuideChoice? guideFieldGuideOfferChoice(
  List<({String price, double rawPrice})> offers,
) {
  if (offers.isEmpty) return null;
  var paid = -1;
  var free = -1;
  for (var i = 0; i < offers.length; i++) {
    final raw = offers[i].rawPrice;
    if (raw > 0) {
      if (paid < 0 || raw > offers[paid].rawPrice) paid = i;
    } else if (free < 0 && offers[i].price.trim().isNotEmpty) {
      free = i;
    }
  }
  if (paid < 0 && free < 0) return null;
  if (paid < 0) {
    return GuideFieldGuideChoice(
      buyIndex: free,
      displayPrice: offers[free].price,
    );
  }
  return GuideFieldGuideChoice(
    buyIndex: free >= 0 ? free : paid,
    displayPrice: offers[paid].price,
  );
}

/// Whether this phone may replace monthly with yearly, or the screen is only
/// a summary. A plan that arrived from the account cannot be changed here.
class GuideFieldGuideAccess {
  final bool upgrade;
  final bool locked;

  const GuideFieldGuideAccess({required this.upgrade, required this.locked});
}

GuideFieldGuideAccess guideFieldGuideAccess({
  required GuideFieldGuideCatalog catalog,
  required bool monthlyOnThisStore,
  required bool fromAccountOnly,
}) {
  final upgrade = monthlyOnThisStore &&
      !fromAccountOnly &&
      catalog.monthly.owned &&
      !catalog.yearly.owned &&
      !catalog.coveredByOlderPlan &&
      catalog.yearly.price != null;
  final hasPlan = catalog.monthly.owned ||
      catalog.yearly.owned ||
      catalog.coveredByOlderPlan ||
      fromAccountOnly;
  return GuideFieldGuideAccess(upgrade: upgrade, locked: hasPlan && !upgrade);
}

/// The other Field Guide product, when that product is already owned.
/// Photo-storage plans are a separate subscription and are not replaced.
String? guideFieldGuideReplaces(
  GuideFieldGuidePlan buying,
  Set<String> owned,
) {
  final other = buying == GuideFieldGuidePlan.yearly
      ? fieldGuideMonthly
      : fieldGuideYearly;
  return owned.contains(other) ? other : null;
}

GuideFieldGuideLoaded guideFieldGuideFromStore({
  required bool storeAvailable,
  required List<ProductDetails> products,
  required Set<String> owned,
  String? error,
}) {
  final yearly = _picked(products, fieldGuideYearly);
  final monthly = _picked(products, fieldGuideMonthly);
  return GuideFieldGuideLoaded(
    catalog: guideFieldGuideCatalog(
      storeAvailable: storeAvailable,
      yearlyPrice: yearly?.displayPrice,
      monthlyPrice: monthly?.displayPrice,
      owned: owned,
      error: error,
    ),
    products: {
      if (yearly != null) fieldGuideYearly: yearly.product,
      if (monthly != null) fieldGuideMonthly: monthly.product,
    },
  );
}

({ProductDetails product, String displayPrice})? _picked(
  List<ProductDetails> products,
  String id,
) {
  final matches = products.where((product) => product.id == id).toList();
  final choice = guideFieldGuideOfferChoice([
    for (final product in matches)
      (price: product.price, rawPrice: product.rawPrice),
  ]);
  if (choice == null) return null;
  return (
    product: matches[choice.buyIndex],
    displayPrice: choice.displayPrice,
  );
}
