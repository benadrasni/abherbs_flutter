import 'package:abherbs_flutter/key/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/key/habitat_page.dart';
import 'package:abherbs_flutter/key/petal_glyphs.dart';
import 'package:flutter/material.dart';

String guidePetalName(S strings, String id) {
  switch (id) {
    case '1':
      return strings.petal_4;
    case '2':
      return strings.petal_5;
    case '3':
      return strings.petal_many;
    case '4':
      return strings.petal_zygomorphic;
    default:
      return '';
  }
}

String guidePetalTrailLabel(S strings, String id) {
  final name = guideCap(guidePetalName(strings, id));
  if (id == '4') return name;
  return strings.guide_petal_trail(name);
}

class GuidePetalPage extends StatefulWidget {
  final String colorId;
  final String? habitatId;
  final Map<String, int>? counts;
  final Future<Map<String, int>> Function(String colorId, String? habitatId)
      loadCounts;
  final void Function(String petalId)? onContinue;

  const GuidePetalPage({
    super.key,
    required this.colorId,
    required this.habitatId,
    this.counts,
    this.loadCounts = loadPetalCounts,
    this.onContinue,
  });

  @override
  State<GuidePetalPage> createState() => _GuidePetalPageState();
}

class _GuidePetalPageState extends State<GuidePetalPage> {
  Map<String, int>? _counts;
  bool _failed = false;
  int _ticket = 0;

  @override
  void initState() {
    super.initState();
    _counts = widget.counts;
    if (_counts == null) _load();
  }

  @override
  void didUpdateWidget(GuidePetalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.counts != oldWidget.counts) {
      _counts = widget.counts;
      _failed = false;
    }
    if ((widget.colorId != oldWidget.colorId ||
            widget.habitatId != oldWidget.habitatId) &&
        widget.counts == null) {
      _counts = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final ticket = ++_ticket;
    try {
      final counts = await widget.loadCounts(widget.colorId, widget.habitatId);
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _counts = counts;
        _failed = false;
      });
    } catch (error) {
      debugPrint('guide petals: $error');
      if (!mounted || ticket != _ticket) return;
      setState(() => _failed = true);
    }
  }

  void _pick(String id) {
    final counts = _counts;
    if (counts == null && !_failed) return;
    final remaining = counts?[id];
    if (remaining != null && remaining <= 0) {
      guideNoFlowers(context);
      return;
    }
    widget.onContinue?.call(id);
  }

  void _backToFind() {
    popGuideKeyToFind(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final colorName = guideCap(
      getFilterColorValue(context, widget.colorId),
    );
    final habitatId = widget.habitatId;
    final habitatName =
        habitatId == null ? '' : guideCap(guideHabitatName(strings, habitatId));
    return GuideKeyScaffold(
      withTabs: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          GuideBackButton(label: guideCap(strings.filter_habitat)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                GuideFilterPill(
                  label: colorName,
                  leading: _ColorDot(colorId: widget.colorId),
                  onPressed: _backToFind,
                ),
                if (habitatName.isNotEmpty)
                  GuideFilterPill(
                    label: habitatName,
                    onPressed: () => Navigator.maybePop(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.guide_key_step_petal.toUpperCase(),
                  style: GuideType.eyebrow(colors),
                ),
                const SizedBox(height: 8),
                const GuideKeyStepper(filled: 3),
                const SizedBox(height: 12),
                Text(strings.guide_petal_question,
                    style: GuideType.question(colors)),
                const SizedBox(height: 6),
                Text(
                  strings.guide_petal_hint,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colors.ink3,
                  ),
                ),
                const SizedBox(height: 14),
                ..._petalTiles(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _petalTiles() {
    final perRow =
        GuideWindow.of(context).columns(phone: 2, tablet: 4, wide: 4);
    final tiles = <Widget>[];
    for (var i = 0; i < guidePetalIds.length; i += perRow) {
      if (tiles.isNotEmpty) tiles.add(const SizedBox(height: 10));
      final end = i + perRow > guidePetalIds.length
          ? guidePetalIds.length
          : i + perRow;
      tiles.add(
        _PetalRow(
          ids: guidePetalIds.sublist(i, end),
          counts: _counts,
          onPick: _pick,
        ),
      );
    }
    return tiles;
  }
}

class _ColorDot extends StatelessWidget {
  final String colorId;

  const _ColorDot({required this.colorId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: guideSwatchColor(colorId),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
    );
  }
}

class _PetalRow extends StatelessWidget {
  final List<String> ids;
  final Map<String, int>? counts;
  final ValueChanged<String> onPick;

  const _PetalRow({
    required this.ids,
    required this.counts,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < ids.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _tile(context, ids[i])),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String id) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final remaining = counts?[id];
    return Material(
      color: colors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onPick(id),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GuidePetalGlyph(
                    id: id,
                    size: GuideWindow.of(context).tablet ? 96 : 72,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    guideCap(guidePetalName(strings, id)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (remaining != null)
              PositionedDirectional(
                top: 10,
                end: 12,
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.ink3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
