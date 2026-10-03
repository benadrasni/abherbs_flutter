import 'package:abherbs_flutter/generated/l10n.dart';

const String filterColor = 'filterColor';
const String filterHabitat = 'filterHabitat';
const String filterPetal = 'filterPetal';
const String filterDistribution = 'filterDistribution';

const filterAttributes = [filterColor, filterHabitat, filterPetal, filterDistribution];

String getFilterKey(Map<String, String> filter) {
  return filterAttributes.map((attribute) {
    return filter[attribute] ?? "";
  }).join("_");
}

String getFilterColorValue(context, filterValue) {
  switch (filterValue) {
    case '1':
      return S.of(context).color_white;
    case '2':
      return S.of(context).color_yellow;
    case '3':
      return S.of(context).color_red;
    case '4':
      return S.of(context).color_blue;
    case '5':
      return S.of(context).color_green;
    default:
      return "";
  }
}

String getFilterDistributionValue(context, filterValue) {
  switch (filterValue) {
    case '10':
      return S.of(context).northern_europe;
    case '11':
      return S.of(context).middle_europe;
    case '12':
      return S.of(context).southwestern_europe;
    case '13':
      return S.of(context).southeastern_europe;
    case '14':
      return S.of(context).eastern_europe;
    case '20':
      return S.of(context).northern_africa;
    case '21':
      return S.of(context).macaronesia;
    case '22':
      return S.of(context).west_tropical_africa;
    case '23':
      return S.of(context).west_central_tropical_africa;
    case '24':
      return S.of(context).northeast_tropical_africa;
    case '25':
      return S.of(context).east_tropical_africa;
    case '26':
      return S.of(context).south_tropical_africa;
    case '27':
      return S.of(context).southern_africa;
    case '28':
      return S.of(context).middle_atlantic_ocean;
    case '29':
      return S.of(context).western_indian_ocean;
    case '30':
      return S.of(context).siberia;
    case '31':
      return S.of(context).russian_far_east;
    case '32':
      return S.of(context).middle_asia;
    case '33':
      return S.of(context).caucasus;
    case '34':
      return S.of(context).western_asia;
    case '35':
      return S.of(context).arabian_peninsula;
    case '36':
      return S.of(context).china;
    case '37':
      return S.of(context).mongolia;
    case '38':
      return S.of(context).eastern_asia;
    case '40':
      return S.of(context).indian_subcontinent;
    case '41':
      return S.of(context).indochina;
    case '42':
      return S.of(context).malesia;
    case '43':
      return S.of(context).papuasia;
    case '50':
      return S.of(context).australia;
    case '51':
      return S.of(context).new_zealand;
    case '60':
      return S.of(context).southwestern_pacific;
    case '61':
      return S.of(context).south_central_pacific;
    case '62':
      return S.of(context).northwestern_pacific;
    case '63':
      return S.of(context).north_central_pacific;
    case '70':
      return S.of(context).subarctic_america;
    case '71':
      return S.of(context).western_canada;
    case '72':
      return S.of(context).eastern_canada;
    case '73':
      return S.of(context).northwestern_usa;
    case '74':
      return S.of(context).north_central_usa;
    case '75':
      return S.of(context).northeastern_usa;
    case '76':
      return S.of(context).southwestern_usa;
    case '77':
      return S.of(context).south_central_usa;
    case '78':
      return S.of(context).southeastern_usa;
    case '79':
      return S.of(context).mexico;
    case '80':
      return S.of(context).central_america;
    case '81':
      return S.of(context).caribbean;
    case '82':
      return S.of(context).northern_south_america;
    case '83':
      return S.of(context).western_south_america;
    case '84':
      return S.of(context).brazil;
    case '85':
      return S.of(context).southern_south_america;
    case '90':
      return S.of(context).subantarctic_islands;
    case '91':
      return S.of(context).antarctic_continent;

    default:
      return "";
  }
}
