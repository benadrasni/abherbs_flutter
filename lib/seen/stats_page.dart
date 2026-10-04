import 'dart:async';
import 'dart:math' as math;

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/guide_stats.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/species/species_page.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Your finds, and Sightings. Indoor finds are left out of both.
class GuideStatsPage extends StatefulWidget {
  final List<GuideSeenFind>? finds;
  final bool sightings;
  final String backLabel;
  final Future<List<GuideSeenFind>> Function(String languageCode) loadFinds;
  final Future<GuideSightingsLoad> Function() loadSightings;
  final Future<GuideStatFace> Function(String name, String languageCode)
      loadCard;
  final void Function(BuildContext context, String name)? onOpenPlant;

  const GuideStatsPage({
    super.key,
    this.finds,
    this.sightings = false,
    required this.backLabel,
    this.loadFinds = loadGuideSeen,
    this.loadSightings = loadGuideSightings,
    this.loadCard = loadGuidePlantCard,
    this.onOpenPlant,
  });

  @override
  State<GuideStatsPage> createState() => _GuideStatsPageState();
}

class _GuideStatsPageState extends State<GuideStatsPage> {
  late bool _public;
  List<GuideSeenFind>? _finds;
  bool _findsLoading = false;
  bool _findsFailed = false;
  bool _findsStarted = false;
  GuideSightingsLoad? _sightings;
  bool _sightingsLoading = true;
  bool _sightingsFailed = false;
  String? _language;
  final Map<String, GuideStatFace> _cards = {};
  final Set<String> _pending = {};

  @override
  void initState() {
    super.initState();
    _public = widget.sightings;
    _finds = widget.finds;
    _findsLoading = widget.finds == null;
    unawaited(_loadSightings());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    final changed = _language != null && _language != code;
    _language = code;
    if (!_findsStarted && widget.finds == null) {
      _findsStarted = true;
      unawaited(_loadFinds());
    }
    if (changed) {
      _cards.clear();
      _pending.clear();
      _warm();
    }
  }

  Future<void> _loadFinds() async {
    final code = _language;
    if (code == null) return;
    try {
      final finds = await widget.loadFinds(code);
      if (!mounted) return;
      setState(() {
        _finds = finds;
        _findsLoading = false;
        _findsFailed = false;
      });
    } catch (error) {
      debugPrint('guide stats finds: $error');
      if (!mounted) return;
      setState(() {
        _findsLoading = false;
        _findsFailed = true;
      });
    }
  }

  Future<void> _loadSightings() async {
    try {
      final load = await widget.loadSightings();
      if (!mounted) return;
      setState(() {
        _sightings = load;
        _sightingsLoading = false;
        _sightingsFailed = false;
      });
      _warm();
    } catch (error) {
      debugPrint('guide stats sightings: $error');
      if (!mounted) return;
      setState(() {
        _sightingsLoading = false;
        _sightingsFailed = true;
      });
    }
  }

  void _retryFinds() {
    setState(() {
      _findsLoading = true;
      _findsFailed = false;
    });
    unawaited(_loadFinds());
  }

  void _retrySightings() {
    setState(() {
      _sightingsLoading = true;
      _sightingsFailed = false;
    });
    unawaited(_loadSightings());
  }

  void _warm() {
    final headline = _sightings?.headline;
    if (headline == null || _language == null) return;
    for (final name in [headline.firstName, headline.lastName, headline.mostName]) {
      _want(name);
    }
  }

  void _want(String name) {
    if (name.isEmpty || _cards.containsKey(name) || _pending.contains(name)) {
      return;
    }
    final code = _language;
    if (code == null) return;
    _pending.add(name);
    widget.loadCard(name, code).then((card) {
      if (!mounted) return;
      setState(() {
        _cards[name] = card;
        _pending.remove(name);
      });
    }).catchError((Object error) {
      debugPrint('guide stats plant $name: $error');
      if (!mounted) return;
      setState(() => _pending.remove(name));
    });
  }

  Future<void> _open(String name, {bool? inBook}) async {
    if (name.isEmpty) return;
    var known = inBook;
    if (known == null) {
      try {
        final ready = _cards[name];
        final card = ready ?? await widget.loadCard(name, _language ?? 'en');
        if (!mounted) return;
        setState(() => _cards[name] = card);
        known = card.inBook;
      } catch (error) {
        debugPrint('guide stats open $name: $error');
        return;
      }
    }
    if (!mounted) return;
    if (known != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).guide_stats_outside)),
      );
      return;
    }
    final custom = widget.onOpenPlant;
    if (custom != null) {
      custom(context, name);
      return;
    }
    await openGuidePlant(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final stats = _finds == null ? null : guideNotebookStats(_finds!);
    return GuideTheme(
      navigationColor: (colors) => colors.cream,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              GuideBackButton(label: widget.backLabel),
              _Intro(
                title: _public ? strings.guide_sightings : strings.guide_stats_yours,
                note: _note(strings, stats),
              ),
              _Segments(
                sightings: _public,
                onYours: () {
                  if (!_public) return;
                  setState(() => _public = false);
                },
                onSightings: () {
                  if (_public) return;
                  setState(() => _public = true);
                },
              ),
              if (_public)
                _sightingsBody(strings)
              else
                _findsBody(strings, stats),
            ],
          ),
        ),
      ),
    );
  }

  String _note(S strings, GuideNotebookStats? stats) {
    if (_public) return strings.guide_stats_sightings_note;
    final note = strings.guide_stats_yours_note;
    final waiting = stats?.unconfirmed ?? 0;
    if (waiting == 0) return note;
    return '$note ${strings.guide_stats_to_confirm(waiting)}';
  }

  Widget _findsBody(S strings, GuideNotebookStats? stats) {
    if (_findsLoading) return const _Wait();
    if (_findsFailed) {
      return _Failed(onRetry: _retryFinds);
    }
    if (stats == null || stats.finds == 0) {
      return _Hint(strings.guide_stats_empty);
    }
    final format = _format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Numbers(
          counts: [
            (format.format(stats.finds), strings.guide_stats_finds(stats.finds)),
            (format.format(stats.plants), strings.guide_stats_plants(stats.plants)),
            (format.format(stats.shared), strings.guide_stats_shared(stats.shared)),
          ],
        ),
        _Section(strings.guide_stats_span),
        if (stats.first != null)
          _PlantRow(
            role: strings.guide_stats_first,
            plant: stats.first!,
            detail: _day(stats.first!.when),
            onTap: () => _open(stats.first!.name, inBook: stats.first!.inBook),
          ),
        if (stats.last != null)
          _PlantRow(
            role: strings.guide_stats_last,
            plant: stats.last!,
            detail: _day(stats.last!.when),
            onTap: () => _open(stats.last!.name, inBook: stats.last!.inBook),
          ),
        if (stats.most.isEmpty)
          _Hint(strings.guide_stats_once)
        else
          for (final plant in stats.most)
            _PlantRow(
              role: strings.guide_stats_most,
              plant: plant,
              detail: strings.guide_stats_find_times(plant.count),
              onTap: () => _open(plant.name, inBook: plant.inBook),
            ),
        if (stats.years.isNotEmpty) ...[
          _Section(strings.guide_stats_by_year),
          _YearBars(years: stats.years),
        ],
        _Section(strings.guide_stats_by_country(format.format(stats.countries.length))),
        _Countries(countries: stats.countries),
        if (stats.unplaced > 0) _Hint(strings.guide_stats_no_place(stats.unplaced)),
      ],
    );
  }

  Widget _sightingsBody(S strings) {
    if (_sightingsLoading) return const _Wait();
    if (_sightingsFailed) return _Failed(onRetry: _retrySightings);
    final headline = _sightings?.headline;
    final years = _sightings?.years ?? const <GuideYearCount>[];
    if (headline == null || headline.count == 0) {
      return _Hint(strings.guide_sightings_empty);
    }
    final format = _format(context);
    final finds = _finds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Numbers(
          counts: [
            (format.format(headline.count), strings.guide_sightings),
            (format.format(headline.plants), strings.guide_stats_plants(headline.plants)),
            (format.format(headline.people), strings.guide_stats_people),
          ],
        ),
        _Section(strings.guide_stats_span_most),
        if (headline.firstName.isNotEmpty)
          _namedRow(
            strings.guide_stats_first,
            headline.firstName,
            headline.firstWhen == null ? null : _day(headline.firstWhen!),
          ),
        if (headline.lastName.isNotEmpty)
          _namedRow(
            strings.guide_stats_last,
            headline.lastName,
            headline.lastWhen == null ? null : _day(headline.lastWhen!),
          ),
        if (headline.mostName.isNotEmpty && headline.mostCount > 0)
          _namedRow(
            strings.guide_stats_most,
            headline.mostName,
            strings.guide_stats_sighting_times(headline.mostCount),
          ),
        if (years.isNotEmpty) ...[
          _Section(strings.guide_stats_by_year),
          _YearBars(years: years),
        ],
        if (headline.countries.isNotEmpty)
          _Section(
            strings.guide_stats_by_country(format.format(headline.countries.length)),
          ),
        _Countries(countries: headline.countries),
        if (finds != null)
          _Hint(
            strings.guide_stats_place(
              format.format(headline.people),
              guideNotebookStats(finds).shared,
            ),
          ),
      ],
    );
  }

  Widget _namedRow(String role, String name, String? detail) {
    final card = _cards[name];
    final label = card?.label;
    return _PlantRow(
      role: role,
      plant: GuideStatPlant(
        name: name,
        label: label,
        photoPath: card?.photoPath,
        inBook: card?.inBook ?? false,
        when: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      detail: detail,
      onTap: () => _open(name, inBook: card?.inBook),
    );
  }

  String _day(DateTime when) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(when);
  }
}

NumberFormat _format(BuildContext context) {
  return NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
}

class _Intro extends StatelessWidget {
  final String title;
  final String note;

  const _Intro({required this.title, required this.note});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).observation_stats.toUpperCase(),
            style: GuideType.eyebrow(colors),
          ),
          const SizedBox(height: 6),
          Text(title, style: GuideType.question(colors)),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(fontSize: 13, height: 1.35, color: colors.ink3),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  final bool sightings;
  final VoidCallback onYours;
  final VoidCallback onSightings;

  const _Segments({
    required this.sightings,
    required this.onYours,
    required this.onSightings,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.rule),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Row(
            children: [
              Expanded(
                child: _Segment(
                  label: strings.guide_stats_yours,
                  selected: !sightings,
                  onTap: onYours,
                ),
              ),
              Expanded(
                child: _Segment(
                  label: strings.guide_sightings,
                  selected: sightings,
                  onTap: onSightings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Material(
      color: selected ? colors.ink : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? colors.onInk : colors.ink3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Numbers extends StatelessWidget {
  final List<(String, String)> counts;

  const _Numbers({required this.counts});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 0),
      child: Row(
        children: [
          for (final count in counts)
            Expanded(
              child: Column(
                children: [
                  Text(
                    count.$1,
                    style: TextStyle(
                      fontFamily: GuideType.serif,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.$2,
                    style: TextStyle(fontSize: 13, color: colors.ink3),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;

  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.96,
          fontWeight: FontWeight.w600,
          color: colors.ink3,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: GuideColors.of(context).ink3,
        ),
      ),
    );
  }
}

class _Wait extends StatelessWidget {
  const _Wait();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;

  const _Failed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            S.of(context).guide_stats_failed,
            style: TextStyle(color: colors.ink2),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(S.of(context).guide_results_retry),
          ),
        ],
      ),
    );
  }
}

class _PlantRow extends StatelessWidget {
  final String role;
  final GuideStatPlant plant;
  final String? detail;
  final VoidCallback onTap;

  const _PlantRow({
    required this.role,
    required this.plant,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final label = plant.label?.trim();
    final named = label != null && label.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 8),
        child: Row(
          children: [
            GuidePhoto(
              path: plant.photoPath,
              width: 44,
              height: 44,
              radius: 8,
              background: colors.cream,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: colors.ink3,
                    ),
                  ),
                  Text(
                    named ? label : plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: named
                        ? const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.2,
                          )
                        : GuideType.latin(colors).copyWith(fontSize: 16, height: 1.2),
                  ),
                  if (named)
                    Text(
                      plant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GuideType.latin(colors).copyWith(
                        fontSize: 13,
                        height: 1.2,
                        color: colors.ink3,
                      ),
                    ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: TextStyle(fontSize: 13, height: 1.2, color: colors.ink3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearBars extends StatefulWidget {
  final List<GuideYearCount> years;

  const _YearBars({required this.years});

  @override
  State<_YearBars> createState() => _YearBarsState();
}

class _YearBarsState extends State<_YearBars> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _pinEnd();
  }

  @override
  void didUpdateWidget(covariant _YearBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.years.length != widget.years.length) _pinEnd();
  }

  void _pinEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final format = _format(context);
    var maxCount = 0;
    for (final year in widget.years) {
      if (year.count > maxCount) maxCount = year.count;
    }
    return SizedBox(
      height: 132,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.years.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final year = widget.years[index];
          final bar = maxCount == 0 ? 4.0 : math.max(4.0, year.count / maxCount * 72);
          return SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  format.format(year.count),
                  style: TextStyle(fontSize: 11, color: colors.ink3),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: bar,
                  decoration: BoxDecoration(
                    color: colors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${year.year}',
                  style: TextStyle(fontSize: 11, color: colors.ink3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Countries extends StatelessWidget {
  final List<GuideCountryTally> countries;

  const _Countries({required this.countries});

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) return const SizedBox.shrink();
    final colors = GuideColors.of(context);
    final format = _format(context);
    final rows = [...countries];
    rows.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return _countryName(context, a.code).compareTo(_countryName(context, b.code));
    });
    var maxCount = 0;
    for (final row in rows) {
      if (row.count > maxCount) maxCount = row.count;
    }
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 8),
            child: Row(
              children: [
                _Flag(code: row.code),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _countryName(context, row.code),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _Bar(
                        factor: maxCount == 0 ? 0.04 : math.max(0.04, row.count / maxCount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  format.format(row.count),
                  style: TextStyle(fontSize: 13, color: colors.ink3),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double factor;

  const _Bar({required this.factor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: constraints.maxWidth * factor,
            height: 3,
            decoration: BoxDecoration(
              color: GuideColors.of(context).gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

class _Flag extends StatelessWidget {
  final String code;

  const _Flag({required this.code});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Container(
      width: 22,
      height: 15,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: colors.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'icons/flags/png100px/${code.toLowerCase()}.png',
        package: 'country_icons',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}

String _countryName(BuildContext context, String code) {
  try {
    final country = Country.parse(code.toUpperCase());
    final translated = country.getTranslatedName(context)?.trim();
    if (translated != null && translated.isNotEmpty) return translated;
    final name = country.name.trim();
    if (name.isNotEmpty) return name;
  } catch (_) {}
  return code.toUpperCase();
}
