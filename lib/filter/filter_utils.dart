import 'package:abherbs_flutter/filter/color.dart';
import 'package:abherbs_flutter/filter/habitat.dart';
import 'package:abherbs_flutter/filter/petal.dart';

const String filterColor = 'filterColor';
const String filterHabitat = 'filterHabitat';
const String filterPetal = 'filterPetal';
const String filterDistribution = 'filterDistribution';

const String firebaseCounts = 'counts_4_v2';

const filterAttributes = [filterColor, filterHabitat, filterPetal, filterDistribution];

String getFilterKey(Map<String, String> filter) {
  return filterAttributes.map((attribute) {
    return filter[attribute] ?? "";
  }).join("_");
}

getNextFilter(void Function(String) onChangeLanguage, Map<String, String> filter) {
  switch (_getNextFilterAttribute(filter)) {
    case filterColor:
      return Color(onChangeLanguage, filter);
    case filterHabitat:
      return Habitat(onChangeLanguage, filter);
    case filterPetal:
      return Petal(onChangeLanguage, filter);
    default:
      return null;
  }
}

String _getNextFilterAttribute(Map<String, String> filter) {
  return filterAttributes.firstWhere((attribute) => filter[attribute] == null, orElse: () => null);
}