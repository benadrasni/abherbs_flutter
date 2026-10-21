import 'package:abherbs_flutter/data/utils.dart';

/// Hosts that share a species page. www is a different site.
const Set<String> sharedLinkHosts = {
  'whatsthatflower.com',
  'abherbs-backend.web.app',
};

/// Latin name from a shared encyclopedia URL, or null when the URL is not
/// a species page.
///
/// English is `/plant/Bellis%20perennis/`. An indexed language is
/// `/de/plant/Bellis%20perennis/`. `?lang=` does not change the name.
String? plantNameFromSharedUrl(Uri uri) {
  if (uri.scheme != 'https') return null;
  if (!sharedLinkHosts.contains(uri.host.toLowerCase())) return null;
  final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  final String raw;
  if (parts.length == 2 && parts[0] == 'plant') {
    raw = parts[1];
  } else if (parts.length == 3 &&
      parts[1] == 'plant' &&
      _sharedLinkLanguage(parts[0])) {
    raw = parts[2];
  } else {
    return null;
  }
  final name = raw.trim();
  if (name.isEmpty || name.length > 200) return null;
  if (name.contains('/') || name.contains('\\') || name.contains('#')) {
    return null;
  }
  return name;
}

bool _sharedLinkLanguage(String code) {
  return code == languageEnglish || webPathLanguages.contains(code);
}
