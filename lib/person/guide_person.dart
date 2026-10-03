import 'dart:async';

import 'package:abherbs_flutter/offline/guide_offline.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/person/setting_utils.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter/widgets.dart';

enum GuideAccountProvider { google, apple, email, phone }

class GuidePersonAccount {
  final String? name;
  final String? email;
  final String? phone;
  final GuideAccountProvider? provider;

  const GuidePersonAccount({
    this.name,
    this.email,
    this.phone,
    this.provider,
  });
}

class GuideAccountLines {
  final String title;
  final String detail;
  final String initial;
  final bool phoneAvatar;

  const GuideAccountLines({
    required this.title,
    required this.detail,
    required this.initial,
    required this.phoneAvatar,
  });
}

enum GuideAllowanceKind { guest, month, credits, unlimited }

class GuideAllowance {
  final GuideAllowanceKind kind;
  final int includedUsed;
  final int extraUsed;
  final int namesLeft;
  final DateTime? resetsOn;

  /// A photo-storage plan or the lifetime purchase. The Field Guide row hides.
  final bool fieldGuide;
  final bool unlimitedNames;
  final bool noAds;
  final bool seenSynced;

  /// [free] is the guest account's one identification before sign-in.
  const GuideAllowance.guest({bool free = false})
      : kind = GuideAllowanceKind.guest,
        includedUsed = 0,
        extraUsed = 0,
        namesLeft = free ? 1 : 0,
        resetsOn = null,
        fieldGuide = false,
        unlimitedNames = false,
        noAds = false,
        seenSynced = false;

  const GuideAllowance.unlimited({
    required this.fieldGuide,
    required this.unlimitedNames,
    required this.noAds,
    required this.seenSynced,
  })  : kind = GuideAllowanceKind.unlimited,
        includedUsed = 0,
        extraUsed = 0,
        namesLeft = 0,
        resetsOn = null;

  /// [used] is names charged this month. [fromAds] is ad grants earned.
  /// A grant that has not been spent still counts as a name left.
  GuideAllowance.month({
    required int used,
    required int fromAds,
    required DateTime now,
  })  : kind = GuideAllowanceKind.month,
        includedUsed = _clampCount(used, 5),
        extraUsed = _clampCount(fromAds, 5),
        namesLeft = _namesRemaining(used, fromAds),
        resetsOn = DateTime(now.year, now.month + 1, 1),
        fieldGuide = false,
        unlimitedNames = false,
        noAds = false,
        seenSynced = false;

  GuideAllowance.credits(int credits)
      : kind = GuideAllowanceKind.credits,
        includedUsed = 0,
        extraUsed = 0,
        namesLeft = credits < 0 ? 0 : credits,
        resetsOn = null,
        fieldGuide = false,
        unlimitedNames = false,
        noAds = false,
        seenSynced = false;
}

int _clampCount(int value, int max) {
  if (value < 0) return 0;
  if (value > max) return max;
  return value;
}

/// Five included names, plus ad grants, minus names already charged.
int _namesRemaining(int used, int grants) {
  final spent = used < 0 ? 0 : used;
  final left = 5 + _clampCount(grants, 5) - spent;
  return left < 0 ? 0 : left;
}

/// `photo_quota/{uid}` for the signed-in month. Find, the camera, and Person
/// read this. The server is what actually allows the next name.
class GuideMonthCount {
  final int namesUsed;
  final int adGrants;

  const GuideMonthCount({this.namesUsed = 0, this.adGrants = 0});

  static const empty = GuideMonthCount();

  @override
  bool operator ==(Object other) =>
      other is GuideMonthCount &&
      other.namesUsed == namesUsed &&
      other.adGrants == adGrants;

  @override
  int get hashCode => Object.hash(namesUsed, adGrants);
}

final ValueNotifier<GuideMonthCount> guideMonthCount =
    ValueNotifier<GuideMonthCount>(GuideMonthCount.empty);

/// UTC `yyyy-mm`, matching `photo_quota.month`.
String guideQuotaMonth(DateTime now) {
  final utc = now.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  return '${utc.year}-$month';
}

GuideMonthCount guideMonthCountFrom(Object? raw, DateTime now) {
  if (raw is! Map) return GuideMonthCount.empty;
  final month = raw['month'];
  if (month is! String || month != guideQuotaMonth(now)) {
    return GuideMonthCount.empty;
  }
  return GuideMonthCount(
    namesUsed: _quotaCount(raw['namesUsed']),
    adGrants: _quotaCount(raw['adGrants']),
  );
}

int _quotaCount(Object? value) {
  if (value is int) return value < 0 ? 0 : value;
  if (value is num) return value < 0 ? 0 : value.toInt();
  return 0;
}

Future<GuideMonthCount> loadGuideMonthCount() async {
  final user = Auth.appUser;
  if (user == null) return GuideMonthCount.empty;
  try {
    final event = await rootReference
        .child(firebasePhotoQuota)
        .child(user.uid)
        .get();
    return guideMonthCountFrom(event.value, DateTime.now());
  } catch (error) {
    debugPrint('guide month: $error');
    return guideMonthCount.value;
  }
}

/// AdMob calls `admobReward` a moment after the ad closes. The meter moves
/// when `adGrants` does.
Future<void> waitForNameGrant(int grantsBefore) async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(const Duration(seconds: 1));
    final next = await loadGuideMonthCount();
    if (next.adGrants != grantsBefore) {
      guideMonthCount.value = next;
      return;
    }
  }
}

/// Find and the camera listen so using the free name updates the card.
final ValueNotifier<bool> guideGuestFreeRemaining = ValueNotifier<bool>(false);

/// This install has not recorded that the guest used their one free name.
/// A signed-out install whose guest account is already gone has none.
bool guideGuestFreeRemembered() {
  if (Auth.appUser != null) return false;
  if (Prefs.getBool(keyGuestFreeUsed, false)) return false;
  if (Auth.guestUser == null &&
      Auth.firebaseAuth.currentUser == null &&
      Prefs.getBool(keyGuestCreated, false)) {
    return false;
  }
  return true;
}

/// Whether the guest still has its one free identification. `identifyPlant`
/// keeps that flag in `photo_quota/{uid}`; the install also remembers it.
Future<bool> guideGuestHasFreeName() async {
  if (!guideGuestFreeRemembered()) {
    _publishGuestFree(false);
    return false;
  }
  if (Auth.firebaseAuth.currentUser == null) await Auth.startGuest();
  final guest = Auth.guestUser;
  if (guest == null) {
    final free = !Prefs.getBool(keyGuestCreated, false);
    _publishGuestFree(free);
    return free;
  }
  try {
    final event = await rootReference
        .child(firebasePhotoQuota)
        .child(guest.uid)
        .child(firebaseAttributeAnonymousFreeUsed)
        .get();
    final free = event.value != true;
    if (!free) unawaited(Prefs.setBool(keyGuestFreeUsed, true));
    _publishGuestFree(free);
    return free;
  } catch (_) {
    _publishGuestFree(true);
    return true;
  }
}

void guideMarkGuestFreeUsed() {
  _publishGuestFree(false);
  unawaited(Prefs.setBool(keyGuestFreeUsed, true));
}

void _publishGuestFree(bool free) {
  if (guideGuestFreeRemaining.value == free) return;
  guideGuestFreeRemaining.value = free;
}

/// Shares of the allowance bar. A month is ten parts (five included, five
/// from ads). Credits fill up to five parts with the names still left.
({int included, int extra, int rest}) guideAllowanceBarShares(
  GuideAllowance allowance,
) {
  if (allowance.kind == GuideAllowanceKind.credits) {
    final filled = _clampCount(allowance.namesLeft, 5);
    return (included: filled, extra: 0, rest: 5 - filled);
  }
  if (allowance.kind == GuideAllowanceKind.month) {
    final rest = 10 - allowance.includedUsed - allowance.extraUsed;
    return (
      included: allowance.includedUsed,
      extra: allowance.extraUsed,
      rest: rest,
    );
  }
  if (allowance.kind == GuideAllowanceKind.guest && allowance.namesLeft > 0) {
    return (included: 1, extra: 0, rest: 0);
  }
  return (included: 0, extra: 0, rest: 1);
}

/// A signed-in free account has five names a month, plus ad grants.
/// [usedThisMonth] and [extraFromAds] come from `photo_quota`.
GuideAllowance guideLiveAllowance({
  required bool signedIn,
  required bool subscribed,
  required bool unlimitedNames,
  required bool noAds,
  required bool seenSynced,
  int usedThisMonth = 0,
  int extraFromAds = 0,
  bool guestFree = false,
  required DateTime now,
}) {
  if (subscribed || unlimitedNames) {
    return GuideAllowance.unlimited(
      fieldGuide: subscribed,
      unlimitedNames: unlimitedNames,
      noAds: noAds,
      seenSynced: seenSynced,
    );
  }
  if (!signedIn) return GuideAllowance.guest(free: guestFree);
  return GuideAllowance.month(
    used: usedThisMonth,
    fromAds: extraFromAds,
    now: now,
  );
}

String guideFieldGuideDetail({
  required bool unlimitedNames,
  required bool noAds,
  required bool seenSynced,
  required String unlimited,
  required String noAdsLabel,
  required String seenSyncedLabel,
}) {
  final parts = <String>[
    if (unlimitedNames) unlimited,
    if (noAds) noAdsLabel,
    if (seenSynced) seenSyncedLabel,
  ];
  if (parts.isEmpty) return '';
  return parts.join(' · ');
}

String? _filled(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String guideAccountInitial({String? name, String? email, String? phone}) {
  final source = _filled(name) ?? _filled(email) ?? _filled(phone) ?? '';
  if (source.isEmpty) return '';
  return String.fromCharCode(source.runes.first).toUpperCase();
}

/// Apple’s private relay, or no address at all. A real Apple email is shown.
bool guideAppleHidesEmail(String? email) {
  final mail = email?.trim().toLowerCase() ?? '';
  return mail.isEmpty || mail.endsWith('@privaterelay.appleid.com');
}

/// First line is the display name, then the email, then the phone number.
/// The second line says how they signed in.
GuideAccountLines guideAccountLines({
  String? name,
  String? email,
  String? phone,
  GuideAccountProvider? provider,
  required String yourAccount,
  required String signedIn,
  required String google,
  required String apple,
  required String emailPassword,
  required String phoneLabel,
  required String appleHidden,
}) {
  final named = _filled(name);
  final mail = _filled(email);
  final number = _filled(phone);
  final hidden =
      provider == GuideAccountProvider.apple && guideAppleHidesEmail(mail);
  final visibleMail = hidden ? null : mail;

  final String title;
  if (named != null) {
    title = named;
  } else if (visibleMail != null) {
    title = visibleMail;
  } else if (number != null) {
    title = number;
  } else {
    title = yourAccount;
  }

  final phoneAvatar = number != null && title == number;
  final initial = phoneAvatar || title == yourAccount
      ? ''
      : String.fromCharCode(title.runes.first).toUpperCase();

  final String detail;
  if (hidden) {
    detail = number != null && number != title
        ? '$appleHidden · $number'
        : appleHidden;
  } else {
    final method = switch (provider) {
      GuideAccountProvider.google => google,
      GuideAccountProvider.apple => apple,
      GuideAccountProvider.email => emailPassword,
      GuideAccountProvider.phone => phoneLabel,
      null => null,
    };
    final parts = <String>[
      if (visibleMail != null && visibleMail != title) visibleMail,
      if (number != null && number != title) number,
      if (method != null) method,
    ];
    detail = parts.isEmpty ? signedIn : parts.join(' · ');
  }

  return GuideAccountLines(
    title: title,
    detail: detail,
    initial: initial,
    phoneAvatar: phoneAvatar,
  );
}

GuideAccountProvider? guideAccountProvider(Iterable<String> providerIds) {
  if (providerIds.contains('google.com')) return GuideAccountProvider.google;
  if (providerIds.contains('apple.com')) return GuideAccountProvider.apple;
  if (providerIds.contains('password')) return GuideAccountProvider.email;
  if (providerIds.contains('phone')) return GuideAccountProvider.phone;
  return null;
}

GuidePersonAccount? guideAccountFrom({
  required bool signedIn,
  String? displayName,
  String? email,
  String? phone,
  Iterable<String> providerIds = const [],
}) {
  if (!signedIn) return null;
  return GuidePersonAccount(
    name: _filled(displayName),
    email: _filled(email),
    phone: _filled(phone),
    provider: guideAccountProvider(providerIds),
  );
}

String? guideProfileValue(String? direct, Iterable<String?> provided) {
  final first = _filled(direct);
  if (first != null) return first;
  for (final value in provided) {
    final next = _filled(value);
    if (next != null) return next;
  }
  return null;
}

String guideLanguageName(
    Map<String, String> names, String pref, Locale locale) {
  if (pref.isNotEmpty) {
    final saved = names[pref];
    if (saved != null && saved.isNotEmpty) return saved;
  }
  final code = locale.languageCode;
  if (code == 'no' || code == 'nn') {
    final norsk = names['nb_NO'];
    if (norsk != null) return norsk;
  }
  final country = locale.countryCode;
  if (country != null && country.isNotEmpty) {
    final exact = names['${code}_$country'];
    if (exact != null) return exact;
  }
  for (final entry in names.entries) {
    if (entry.key.startsWith('${code}_')) return entry.value;
  }
  return code;
}

String guideThemeDetail({
  required GuideAppearance appearance,
  required Brightness platform,
  required String alwaysLight,
  required String alwaysDark,
  required String likePhoneLight,
  required String likePhoneDark,
}) {
  switch (appearance) {
    case GuideAppearance.light:
      return alwaysLight;
    case GuideAppearance.dark:
      return alwaysDark;
    case GuideAppearance.system:
      return platform == Brightness.dark ? likePhoneDark : likePhoneLight;
  }
}

class GuidePersonView {
  final GuidePersonAccount? account;
  final GuideAllowance allowance;
  final String languageName;
  final GuideAppearance appearance;
  final bool showFieldGuide;
  final bool showOffline;
  final bool offlineOn;
  final GuideOfflineHold? offlineHold;

  const GuidePersonView({
    required this.account,
    required this.allowance,
    required this.languageName,
    required this.appearance,
    required this.showFieldGuide,
    required this.showOffline,
    required this.offlineOn,
    this.offlineHold,
  });
}

Future<GuidePersonView> loadGuidePerson(Locale locale) async {
  final user = Auth.appUser;
  final signedIn = user != null;
  final profiles = user?.providerData;
  final pref = await Prefs.getStringF(keyPreferredLanguage);
  final offlineOwned = Purchases.isOffline();
  final offlineOn =
      offlineOwned ? await Prefs.getBoolF(keyOffline, false) : false;
  final fieldGuide = Purchases.hasFieldGuide();
  final unlimitedNames =
      Purchases.isPhotoSearch() || Purchases.hasLifetimeSubscription;
  final count = signedIn ? await loadGuideMonthCount() : GuideMonthCount.empty;
  if (signedIn && guideMonthCount.value != count) {
    guideMonthCount.value = count;
  }
  return GuidePersonView(
    account: guideAccountFrom(
      signedIn: signedIn,
      displayName: guideProfileValue(
        user?.displayName,
        profiles?.map((info) => info.displayName) ?? const [],
      ),
      email: guideProfileValue(
        user?.email,
        profiles?.map((info) => info.email) ?? const [],
      ),
      phone: guideProfileValue(
        user?.phoneNumber,
        profiles?.map((info) => info.phoneNumber) ?? const [],
      ),
      providerIds: profiles?.map((info) => info.providerId) ?? const [],
    ),
    allowance: guideLiveAllowance(
      signedIn: signedIn,
      subscribed: fieldGuide,
      unlimitedNames: unlimitedNames,
      noAds: Purchases.isNoAds() || fieldGuide,
      seenSynced: Purchases.syncsSeenPhotos(),
      usedThisMonth: count.namesUsed,
      extraFromAds: count.adGrants,
      guestFree: signedIn ? false : await guideGuestHasFreeName(),
      now: DateTime.now(),
    ),
    languageName: guideLanguageName(languages, pref, locale),
    appearance: storedGuideAppearance(),
    showFieldGuide: !fieldGuide,
    showOffline: true,
    offlineOn: offlineOn,
    offlineHold: await loadGuideOfflineHold(),
  );
}
