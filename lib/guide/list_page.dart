import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_results.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Day heading for New in the book: Today, Yesterday, or the date with the year.
///
/// [date] keeps the calendar day of a date-only `lists_custom/new` key.
String guideNewDayLabel(
  String locale,
  DateTime date, {
  DateTime? now,
  String todayLabel = 'Today',
  String yesterdayLabel = 'Yesterday',
}) {
  final clock = now ?? DateTime.now();
  if (_sameCalendarDay(date, clock)) return todayLabel;
  final yesterday = DateTime(clock.year, clock.month, clock.day - 1);
  if (_sameCalendarDay(date, yesterday)) return yesterdayLabel;
  return DateFormat.yMMMMd(locale).format(
    DateTime(date.year, date.month, date.day),
  );
}

bool _sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const _plateGround = Color(0xFFF1E8D6);

/// New in the book: the last 15 to 25 plants, grouped by the day they were added.
class GuideNewPage extends StatefulWidget {
  final String backLabel;
  final List<GuideNewDay>? initialDays;
  final Set<String>? initialSeen;
  final bool? showAd;
  final Future<List<GuideNewDay>> Function() loadDays;
  final Future<Set<String>> Function() loadSeen;
  final void Function(BuildContext context, String name) onOpenPlant;

  const GuideNewPage({
    super.key,
    required this.backLabel,
    required this.loadDays,
    required this.loadSeen,
    required this.onOpenPlant,
    this.initialDays,
    this.initialSeen,
    this.showAd,
  });

  @override
  State<GuideNewPage> createState() => _GuideNewPageState();
}

class _GuideNewPageState extends State<GuideNewPage> {
  List<GuideNewDay>? _days;
  Set<String> _seen = {};
  bool _plates = false;
  bool _loading = false;
  bool _failed = false;
  int _ticket = 0;

  @override
  void initState() {
    super.initState();
    final days = widget.initialDays;
    if (days != null) {
      _days = days;
      _seen = widget.initialSeen ?? {};
    } else {
      _load();
    }
  }

  bool get _showAd => widget.showAd ?? Purchases.showsAds();

  int get _count {
    final days = _days;
    if (days == null) return 0;
    var count = 0;
    for (final day in days) {
      count += day.plants.length;
    }
    return count;
  }

  Future<void> _load() async {
    final ticket = ++_ticket;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final days = await widget.loadDays();
      final seen = await widget.loadSeen();
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _days = days;
        _seen = seen;
        _loading = false;
      });
    } catch (error) {
      debugPrint('guide new list: $error');
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _loading = false;
        _failed = _days == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final days = _days;
    final seenCount = days == null
        ? 0
        : guideSeenInList(
            [for (final day in days) ...day.plants],
            _seen,
          );
    return _ListChrome(
      backLabel: widget.backLabel,
      title: strings.guide_new_in_book,
      meta: days == null ? '' : strings.guide_new_added(_count),
      seenCount: days == null ? 0 : seenCount,
      plates: _plates,
      showSwitch: days != null,
      onPhotos: () => setState(() => _plates = false),
      onPlates: () => setState(() => _plates = true),
      showAd: _showAd && days != null,
      body: _body(days),
    );
  }

  List<Widget> _body(List<GuideNewDay>? days) {
    if (days == null && _loading) return const [_Waiting()];
    if (days == null && _failed) return [_Retry(onRetry: _load)];
    if (days == null) return const [];
    final rows = <Widget>[];
    GuideResultPlant? pending;
    void flush() {
      final left = pending;
      if (left == null) return;
      rows.add(_pair(left, null));
      pending = null;
    }

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      if (day.plants.isEmpty) continue;
      flush();
      rows.add(_DateHeader(day: day, first: rows.isEmpty));
      for (final plant in day.plants) {
        if (pending == null) {
          pending = plant;
        } else {
          rows.add(_pair(pending!, plant));
          pending = null;
        }
      }
    }
    flush();
    return rows;
  }

  Widget _pair(GuideResultPlant left, GuideResultPlant? right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _cell(left)),
          const SizedBox(width: 12),
          Expanded(child: right == null ? const SizedBox() : _cell(right)),
        ],
      ),
    );
  }

  Widget _cell(GuideResultPlant plant) {
    final colors = GuideColors.of(context);
    final label = plant.label;
    final named = label != null && label.isNotEmpty;
    final path = _plates ? plant.platePath : plant.photoPath;
    return InkWell(
      onTap: () => widget.onOpenPlant(context, plant.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: _plates ? 2 / 3 : 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GuidePhoto(
                  path: path,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  radius: 10,
                  fit: _plates ? BoxFit.contain : BoxFit.cover,
                  background: _plates ? _plateGround : colors.paper2,
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Text(
            named ? guideCap(label) : plant.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: named
                ? TextStyle(
                    fontFamily: GuideType.serif,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.15,
                    color: colors.ink,
                  )
                : GuideType.latin(colors).copyWith(fontSize: 16, height: 1.15),
          ),
          if (named)
            Text(
              plant.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GuideType.latin(colors).copyWith(
                fontSize: 13,
                height: 1.2,
                color: colors.ink3,
              ),
            ),
          if (_seen.contains(plant.name))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                S.of(context).guide_seen_mark,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.moss,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A year campaign, newest year first, with the source linked.
class GuideYearPage extends StatefulWidget {
  final String title;
  final String backLabel;
  final String? sourceUrl;
  final List<GuideYearEntry>? initialEntries;
  final Set<String>? initialSeen;
  final bool? showAd;
  final DateTime Function() now;
  final Future<GuideYearList> Function() loadList;
  final Future<Set<String>> Function() loadSeen;
  final void Function(BuildContext context, String name) onOpenPlant;

  const GuideYearPage({
    super.key,
    required this.title,
    required this.backLabel,
    required this.loadList,
    required this.loadSeen,
    required this.onOpenPlant,
    this.sourceUrl,
    this.initialEntries,
    this.initialSeen,
    this.showAd,
    this.now = DateTime.now,
  });

  @override
  State<GuideYearPage> createState() => _GuideYearPageState();
}

class _GuideYearPageState extends State<GuideYearPage> {
  List<GuideYearEntry>? _entries;
  String? _sourceUrl;
  Set<String> _seen = {};
  bool _plates = false;
  bool _loading = false;
  bool _failed = false;
  int _ticket = 0;

  @override
  void initState() {
    super.initState();
    final entries = widget.initialEntries;
    if (entries != null) {
      _entries = entries;
      _sourceUrl = widget.sourceUrl;
      _seen = widget.initialSeen ?? {};
    } else {
      _load();
    }
  }

  bool get _showAd => widget.showAd ?? Purchases.showsAds();

  Future<void> _load() async {
    final ticket = ++_ticket;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final list = await widget.loadList();
      final seen = await widget.loadSeen();
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _entries = list.entries;
        _sourceUrl = list.sourceUrl;
        _seen = seen;
        _loading = false;
      });
    } catch (error) {
      debugPrint('guide year list: $error');
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _loading = false;
        _failed = _entries == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final entries = _entries;
    final seenCount = entries == null
        ? 0
        : guideSeenInList(entries.map((entry) => entry.plant), _seen);
    return _ListChrome(
      backLabel: widget.backLabel,
      title: widget.title,
      meta: entries == null ? '' : strings.guide_years_newest(entries.length),
      sourceUrl: _sourceUrl,
      seenCount: seenCount,
      plates: _plates,
      showSwitch: entries != null,
      onPhotos: () => setState(() => _plates = false),
      onPlates: () => setState(() => _plates = true),
      showAd: _showAd && entries != null,
      padded: false,
      body: _body(entries),
    );
  }

  List<Widget> _body(List<GuideYearEntry>? entries) {
    if (entries == null && _loading) return const [_Waiting()];
    if (entries == null && _failed) return [_Retry(onRetry: _load)];
    if (entries == null) return const [];
    final year = widget.now().year;
    return [
      for (final entry in entries)
        _YearRow(
          entry: entry,
          plates: _plates,
          seen: _seen.contains(entry.plant.name),
          thisYear: entry.year == year,
          onTap: () => widget.onOpenPlant(context, entry.plant.name),
        ),
    ];
  }
}

class _ListChrome extends StatelessWidget {
  final String backLabel;
  final String title;
  final String meta;
  final String? sourceUrl;
  final int seenCount;
  final bool plates;
  final bool showSwitch;
  final VoidCallback onPhotos;
  final VoidCallback onPlates;
  final bool showAd;
  final bool padded;
  final List<Widget> body;

  const _ListChrome({
    required this.backLabel,
    required this.title,
    required this.meta,
    required this.seenCount,
    required this.plates,
    required this.showSwitch,
    required this.onPhotos,
    required this.onPlates,
    required this.showAd,
    required this.body,
    this.sourceUrl,
    this.padded = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final host = sourceUrl == null || sourceUrl!.isEmpty
        ? null
        : guideSourceHost(sourceUrl!);
    return GuideKeyScaffold(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GuideBackButton(label: backLabel),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.custom_lists.toUpperCase(),
                        style: GuideType.eyebrow(colors),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: GuideType.serif,
                          fontWeight: FontWeight.w500,
                          fontSize: 30,
                          height: 1.05,
                          letterSpacing: -0.4,
                          color: colors.ink,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: colors.ink3,
                            ),
                            children: [
                              TextSpan(text: meta),
                              if (host != null) ...[
                                const TextSpan(text: ' · '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () => launchURL(sourceUrl!),
                                    child: Text(
                                      '$host ↗',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                        color: colors.moss,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (seenCount > 0)
                                TextSpan(
                                  text:
                                      ' · ${strings.guide_you_have_seen(seenCount)}',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showSwitch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GuideViewSwitch(
                    photos: strings.guide_photos,
                    plates: strings.guide_plates,
                    platesOn: plates,
                    onPhotos: onPhotos,
                    onPlates: onPlates,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padded ? 20 : 0, 8, padded ? 20 : 0, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate(body),
            ),
          ),
          if (showAd) const SliverToBoxAdapter(child: AppBannerAd()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final GuideNewDay day;
  final bool first;

  const _DateHeader({required this.day, required this.first});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final date = day.date;
    final label = date == null
        ? day.dateKey
        : guideNewDayLabel(
            Localizations.localeOf(context).toString(),
            date,
            todayLabel: strings.guide_new_today,
            yesterdayLabel: strings.guide_new_yesterday,
          );
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 10, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: colors.ink3,
        ),
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  final GuideYearEntry entry;
  final bool plates;
  final bool seen;
  final bool thisYear;
  final VoidCallback onTap;

  const _YearRow({
    required this.entry,
    required this.plates,
    required this.seen,
    required this.thisYear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final plant = entry.plant;
    final label = plant.label;
    final named = label != null && label.isNotEmpty;
    final path = plates ? plant.platePath : plant.photoPath;
    final side = plates ? 96.0 : 64.0;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.year}',
                      style: TextStyle(
                        fontFamily: GuideType.serif,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 1.1,
                        color: colors.madder,
                      ),
                    ),
                    if (thisYear)
                      Text(
                        strings.guide_this_year.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                          color: colors.madder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GuidePhoto(
                path: path,
                width: 64,
                height: side,
                radius: 10,
                fit: plates ? BoxFit.contain : BoxFit.cover,
                background: plates ? _plateGround : colors.paper2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      named ? guideCap(label) : plant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: named
                          ? TextStyle(
                              fontFamily: GuideType.serif,
                              fontWeight: FontWeight.w500,
                              fontSize: 17,
                              height: 1.15,
                              color: colors.ink,
                            )
                          : GuideType.latin(colors).copyWith(
                              fontSize: 17,
                              height: 1.15,
                            ),
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
                    if (seen)
                      Text(
                        strings.guide_seen_mark,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.moss,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: CircularProgressIndicator(
          color: GuideColors.of(context).moss,
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;

  const _Retry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            strings.guide_results_failed,
            style: TextStyle(color: colors.ink2),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(strings.guide_results_retry),
          ),
        ],
      ),
    );
  }
}
