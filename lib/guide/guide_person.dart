import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/utils/utils.dart';
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

  const GuideAllowance.guest()
      : kind = GuideAllowanceKind.guest,
        includedUsed = 0,
        extraUsed = 0,
        namesLeft = 0,
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

  GuideAllowance.month({
    required int used,
    required int fromAds,
    required DateTime now,
  })  : kind = GuideAllowanceKind.month,
        includedUsed = _clampCount(used, 5),
        extraUsed = _clampCount(fromAds, 5),
        namesLeft = 0,
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
  return (included: 0, extra: 0, rest: 1);
}

/// The monthly counter is not stored yet. A signed-in account shows the
/// names it can still use. Pass [usedThisMonth] once that counter exists.
GuideAllowance guideLiveAllowance({
  required bool signedIn,
  required bool subscribed,
  required bool unlimitedNames,
  required bool noAds,
  required bool seenSynced,
  required int credits,
  int? usedThisMonth,
  int extraFromAds = 0,
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
  if (!signedIn) return const GuideAllowance.guest();
  if (usedThisMonth != null) {
    return GuideAllowance.month(
      used: usedThisMonth,
      fromAds: extraFromAds,
      now: now,
    );
  }
  return GuideAllowance.credits(credits);
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

  const GuidePersonView({
    required this.account,
    required this.allowance,
    required this.languageName,
    required this.appearance,
    required this.showFieldGuide,
    required this.showOffline,
    required this.offlineOn,
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
  final subscribed = Purchases.isSubscribed();
  final unlimitedNames = Purchases.isPhotoSearch();
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
      subscribed: subscribed,
      unlimitedNames: unlimitedNames,
      noAds: Purchases.isNoAds(),
      seenSynced: subscribed,
      credits: Auth.credits,
      now: DateTime.now(),
    ),
    languageName: guideLanguageName(languages, pref, locale),
    appearance: storedGuideAppearance(),
    showFieldGuide: !subscribed,
    showOffline: offlineOwned,
    offlineOn: offlineOn,
  );
}
