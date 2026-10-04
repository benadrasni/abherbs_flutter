import 'dart:ui';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/guide_stats.dart';
import 'package:abherbs_flutter/seen/observation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outdoor notebook counts skip indoors and unplaced finds', () {
    final stats = guideNotebookStats([
      _find('a', 'Galanthus nivalis', DateTime(2021, 3, 2), country: 'SK'),
      _find('b', 'Bellis perennis', DateTime(2026, 5, 1), country: 'si'),
      _find('c', 'Bellis perennis', DateTime(2026, 6, 1), indoors: true, country: 'si'),
      _find('d', 'Rosa canina', DateTime(2026, 7, 1), country: 'Middle Europe'),
      _find('e', 'Rosa canina', DateTime(2026, 8, 1)),
      _find(
        'f',
        'Taraxacum officinale',
        DateTime(2020, 4, 1),
        country: 'de',
        confirmed: false,
      ),
      _find(
        'g',
        'Achillea millefolium',
        DateTime(2026, 1, 1),
        country: 'sk',
        share: GuideSeenShare.shared,
      ),
    ]);

    expect(stats.finds, 6);
    expect(stats.plants, 5);
    expect(stats.shared, 1);
    expect(stats.unconfirmed, 1);
    expect(stats.unplaced, 2);
    expect(stats.first!.name, 'Taraxacum officinale');
    expect(stats.last!.name, 'Rosa canina');
    expect(stats.last!.when, DateTime(2026, 8, 1));
    expect(stats.years.map((year) => year.year), [2020, 2021, 2026]);
    expect(stats.years.last.count, 4);
    expect(stats.countries.map((row) => row.code), ['sk', 'de', 'si']);
    expect(stats.countries.first.count, 2);
    expect(stats.most.map((plant) => plant.name), ['Rosa canina']);
    expect(stats.most.single.count, 2);
  });

  test('each plant once means there is no most seen', () {
    final stats = guideNotebookStats([
      _find('a', 'Galanthus nivalis', DateTime(2021, 3, 2), country: 'sk'),
      _find('b', 'Bellis perennis', DateTime(2026, 5, 1), country: 'sk'),
    ]);
    expect(stats.most, isEmpty);
    expect(stats.plants, 2);
    expect(stats.countries.single.count, 2);
  });

  test('a tie above one lists every most-seen plant', () {
    final stats = guideNotebookStats([
      _find('a', 'Bellis perennis', DateTime(2026, 5, 1)),
      _find('b', 'Bellis perennis', DateTime(2026, 6, 1), label: 'daisy', inBook: true),
      _find('c', 'Rosa canina', DateTime(2026, 5, 2)),
      _find('d', 'Rosa canina', DateTime(2026, 6, 2)),
      _find('e', 'Urtica dioica', DateTime(2026, 7, 1)),
    ]);
    expect(stats.most.map((plant) => plant.name), ['Bellis perennis', 'Rosa canina']);
    expect(stats.most.first.label, 'daisy');
    expect(stats.most.first.inBook, isTrue);
    expect(stats.most.first.count, 2);
  });

  test('the same instant keeps the earlier id as first', () {
    final when = DateTime(2024, 1, 1);
    final stats = guideNotebookStats([
      _find('b', 'Rosa canina', when),
      _find('a', 'Bellis perennis', when),
    ]);
    expect(stats.first!.name, 'Bellis perennis');
    expect(stats.last!.name, 'Rosa canina');
  });

  test('catalog decoration keeps country and indoors', () {
    final row = readGuideSeenRow('key', {
      observationPlant: 'Bellis perennis',
      observationIndoors: 'true',
      observationCountry: ' SK ',
    });
    expect(row!.indoors, isTrue);
    expect(row.country, 'sk');
    final decorated = row.withCatalog(label: 'daisy', inBook: true);
    expect(decorated.indoors, isTrue);
    expect(decorated.country, 'sk');
    expect(decorated.label, 'daisy');
  });

  test('a place name is not a country code', () {
    expect(guideRowCountry('Middle Europe'), isNull);
    expect(guideRowCountry('gb'), 'gb');
    expect(guideRowIndoors(null), isFalse);
    expect(guideRowIndoors('yes'), isTrue);
  });

  test('public stats keep the stored headline and skip indoor years', () {
    final headline = guideSightingHeadline({
      'count': 1778,
      'distinctFlowers': 630,
      'observers': 56,
      'firstFlower': 'Primula veris',
      'firstDate': 1114966980000,
      'lastFlower': 'Dahlia pinnata',
      'lastDate': 0,
      'mostObserved': '',
      'mostObservedCount': 0,
      'countries': {'si': 10, 'sk': 20, 'nope': 4, 'de': 10},
    });
    expect(headline!.count, 1778);
    expect(headline.plants, 630);
    expect(headline.people, 56);
    expect(headline.firstName, 'Primula veris');
    expect(headline.firstWhen, DateTime.fromMillisecondsSinceEpoch(1114966980000));
    expect(headline.lastWhen, isNull);
    expect(headline.mostName, isEmpty);
    expect(headline.countries.map((row) => '${row.code}:${row.count}'), ['sk:20', 'de:10', 'si:10']);

    final years = guideSightingYears({
      'in': {
        observationPlant: 'Ficus elastica',
        observationIndoors: true,
        observationDate: {observationTime: DateTime(2024, 1, 1).millisecondsSinceEpoch},
      },
      'dated': {
        observationPlant: 'Bellis perennis',
        observationDate: {observationTime: DateTime(2020, 6, 1).millisecondsSinceEpoch},
      },
      'ordered': {
        observationPlant: 'Rosa canina',
        observationOrder: -DateTime(2021, 6, 1).millisecondsSinceEpoch,
      },
      'blank': {observationPlant: 'Urtica dioica'},
    });
    expect(years.map((year) => year.year), [2020, 2021]);
    expect(years.first.count, 1);
  });

  test('a missing public aggregate is counted from outdoor rows', () {
    expect(guideSightingHeadline(null), isNull);
    final headline = guideSightingHeadlineFromRows({
      'room': {
        observationId: 'ada_1',
        observationPlant: 'Ficus elastica',
        observationIndoors: true,
        observationDate: {observationTime: DateTime(2024, 1, 1).millisecondsSinceEpoch},
        observationCountry: 'sk',
      },
      'one': {
        observationId: 'ada_2',
        observationPlant: 'Bellis perennis',
        observationDate: {observationTime: DateTime(2020, 6, 1).millisecondsSinceEpoch},
        observationCountry: 'GB',
      },
      'two': {
        observationId: 'bea_1',
        observationPlant: 'Bellis perennis',
        observationOrder: -DateTime(2021, 6, 1).millisecondsSinceEpoch,
        observationCountry: 'gb',
      },
      'three': {
        observationId: 'ada_3',
        observationPlant: 'Rosa canina',
        observationDate: {observationTime: DateTime(2019, 5, 1).millisecondsSinceEpoch},
      },
    });
    expect(headline!.count, 3);
    expect(headline.plants, 2);
    expect(headline.people, 2);
    expect(headline.firstName, 'Rosa canina');
    expect(headline.lastName, 'Bellis perennis');
    expect(headline.mostName, 'Bellis perennis');
    expect(headline.mostCount, 2);
    expect(headline.countries.single.code, 'gb');
    expect(headline.countries.single.count, 2);
  });

  test('slovak statistics strings and plurals match expected forms', () async {
    final strings = await S.load(const Locale('sk', 'SK'));
    expect(strings.guide_stats_finds(1), 'Nález');
    expect(strings.guide_stats_finds(2), 'Nálezy');
    expect(strings.guide_stats_finds(4), 'Nálezy');
    expect(strings.guide_stats_finds(5), 'Nálezov');
    expect(strings.guide_stats_finds(0), 'Nálezov');

    expect(strings.guide_stats_plants(1), 'Rastlina');
    expect(strings.guide_stats_plants(3), 'Rastliny');
    expect(strings.guide_stats_plants(5), 'Rastlín');
    expect(strings.guide_stats_plants(0), 'Rastlín');

    expect(strings.guide_stats_shared(1), 'Zdieľaný');
    expect(strings.guide_stats_shared(2), 'Zdieľané');
    expect(strings.guide_stats_shared(5), 'Zdieľaných');
    expect(strings.guide_stats_shared(0), 'Zdieľaných');

    expect(
      strings.guide_stats_yours_note,
      'Záznamy v nálezoch. Pozorovania z interiéru sa nezapočítavajú.',
    );
    expect(
      strings.guide_stats_sightings_note,
      contains('Pozorovania z interiéru sa nezapočítavajú.'),
    );
    expect(
      strings.guide_stats_place('5', 1),
      contains('V nálezoch máš 1 zdieľaný nález'),
    );
    expect(
      strings.guide_stats_place('5', 3),
      contains('V nálezoch máš 3 zdieľané nálezy'),
    );
    expect(
      strings.guide_stats_place('5', 10),
      contains('V nálezoch máš 10 zdieľaných nálezov'),
    );
  });

  test('czech and english statistics strings and plurals match expected forms', () async {
    final cs = await S.load(const Locale('cs', 'CZ'));
    expect(cs.guide_stats_finds(1), 'Nález');
    expect(cs.guide_stats_finds(3), 'Nálezy');
    expect(cs.guide_stats_finds(5), 'Nálezů');
    expect(cs.guide_stats_plants(1), 'Rostlina');
    expect(cs.guide_stats_plants(3), 'Rostliny');
    expect(cs.guide_stats_plants(5), 'Rostlin');
    expect(cs.guide_stats_shared(1), 'Sdílený');
    expect(cs.guide_stats_shared(3), 'Sdílené');
    expect(cs.guide_stats_shared(5), 'Sdílených');

    final en = await S.load(const Locale('en'));
    expect(en.guide_stats_finds(1), 'Find');
    expect(en.guide_stats_finds(5), 'Finds');
    expect(en.guide_stats_plants(1), 'Plant');
    expect(en.guide_stats_plants(5), 'Plants');
    expect(en.guide_stats_shared(1), 'Shared');
    expect(en.guide_stats_shared(5), 'Shared');
  });
}

GuideSeenFind _find(
  String id,
  String name,
  DateTime when, {
  bool indoors = false,
  String? country,
  bool confirmed = true,
  GuideSeenShare share = GuideSeenShare.none,
  bool inBook = false,
  String? label,
}) {
  return GuideSeenFind(
    id: id,
    name: name,
    when: when,
    indoors: indoors,
    country: guideRowCountry(country),
    confirmed: confirmed,
    share: share,
    inBook: inBook,
    label: label,
  );
}
