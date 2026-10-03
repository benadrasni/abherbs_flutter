import 'dart:math' as math;

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/species/guide_species.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:flutter/material.dart';

const guideFlowerSchemaRouteName = 'GuideFlowerSchema';
const guideInflorescenceRouteName = 'GuideInflorescence';

const guideFlowerSchemaAsset = 'res/images/Mature_flower_schema.webp';
const guideFlowerSchemaDarkAsset = 'res/images/Mature_flower_schema_dark.webp';

const guideFlowerPlateKey = Key('guide-flower-plate');
const guideFlowerWellKey = Key('guide-flower-well');
const guideSchemaFlowerKey = Key('guide-schema-flower');
const guideSchemaInflorescenceKey = Key('guide-schema-inflorescence');

Key guideFlowerPartKey(int number) => ValueKey('guide-flower-part-$number');

Key guideInflorescenceCellKey(String type) => ValueKey('guide-inflo-$type');

/// Moss heading with a dotted underline. Flower and Inflorescence open
/// the diagrams; the other section titles stay plain.
class GuideSchemaLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const GuideSchemaLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          foregroundPainter: _DottedUnderline(color: colors.moss),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: GuideType.serif,
                    fontWeight: FontWeight.w500,
                    fontSize: 19,
                    height: 1.2,
                    color: colors.moss,
                  ),
                ),
                const SizedBox(width: 1),
                ExcludeSemantics(
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 16,
                    color: colors.moss,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideFlowerSchemaPage extends StatelessWidget {
  final String backLabel;

  const GuideFlowerSchemaPage({super.key, required this.backLabel});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return _SchemaScaffold(
      backLabel: backLabel,
      eyebrow: strings.plant_flower.toUpperCase(),
      title: strings.guide_flower_parts,
      note: strings.guide_flower_parts_note,
      mark: false,
      body: const _FlowerBody(),
    );
  }
}

class GuideInflorescencePage extends StatelessWidget {
  final String backLabel;
  final List<String> types;

  const GuideInflorescencePage({
    super.key,
    required this.backLabel,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final labels = [
      for (final key in types) _inflorescenceLabel(strings, key),
    ];
    final name = backLabel;
    final note = labels.isEmpty
        ? strings.guide_inflorescence_solitary(name)
        : labels.length == 1
            ? strings.guide_inflorescence_marked(name, labels.first)
            : strings.guide_inflorescence_also(
                name,
                labels.first,
                labels.skip(1).join(', '),
              );
    return _SchemaScaffold(
      backLabel: backLabel,
      eyebrow: strings.plant_inflorescence.toUpperCase(),
      title: strings.guide_inflorescence_types,
      note: note,
      mark: true,
      body: _InflorescenceBody(types: types),
    );
  }
}

class _SchemaScaffold extends StatelessWidget {
  final String backLabel;
  final String eyebrow;
  final String title;
  final String note;
  final bool mark;
  final Widget body;

  const _SchemaScaffold({
    required this.backLabel,
    required this.eyebrow,
    required this.title,
    required this.note,
    required this.mark,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return GuideTheme(
      child: Builder(
        builder: (context) {
          final colors = GuideColors.of(context);
          final noteStyle = mark
              ? TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: colors.moss,
                )
              : TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colors.ink3,
                );
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(
                    color: colors.paper,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GuideBackButton(label: backLabel),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eyebrow, style: GuideType.eyebrow(colors)),
                              const SizedBox(height: 4),
                              Text(title, style: GuideType.question(colors)),
                              const SizedBox(height: 8),
                              Text(note, style: noteStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlowerBody extends StatelessWidget {
  const _FlowerBody();

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final dark = colors.brightness == Brightness.dark;
    final strings = S.of(context);
    final labels = [
      strings.legend_flower_1,
      strings.legend_flower_2,
      strings.legend_flower_3,
      strings.legend_flower_4,
      strings.legend_flower_5,
      strings.legend_flower_6,
      strings.legend_flower_7,
      strings.legend_flower_8,
      strings.legend_flower_9,
      strings.legend_flower_10,
      strings.legend_flower_11,
      strings.legend_flower_12,
      strings.legend_flower_13,
      strings.legend_flower_14,
      strings.legend_flower_15,
      strings.legend_flower_16,
      strings.legend_flower_17,
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: 28 + bottom),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: DecoratedBox(
            key: guideFlowerWellKey,
            decoration: BoxDecoration(
              color: dark ? Colors.transparent : GuidePalette.paper,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: Image.asset(
                  dark ? guideFlowerSchemaDarkAsset : guideFlowerSchemaAsset,
                  key: guideFlowerPlateKey,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              for (var row = 0; row < 9; row++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child:
                              _FlowerPart(number: row + 1, label: labels[row])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: row + 9 < labels.length
                            ? _FlowerPart(
                                number: row + 10,
                                label: labels[row + 9],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowerPart extends StatelessWidget {
  final int number;
  final String label;

  const _FlowerPart({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return DecoratedBox(
      key: guideFlowerPartKey(number),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: colors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.25,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InflorescenceBody extends StatelessWidget {
  final List<String> types;

  const _InflorescenceBody({required this.types});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final primary = types.isEmpty ? '' : types.first;
    final matched = types.toSet();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 28 + bottom),
      children: [
        for (var row = 0; row < guideInflorescenceKeys.length; row += 3) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: 8),
                Expanded(
                  child: row + column < guideInflorescenceKeys.length
                      ? _InflorescenceCell(
                          type: guideInflorescenceKeys[row + column],
                          label: _inflorescenceLabel(
                            strings,
                            guideInflorescenceKeys[row + column],
                          ),
                          matched: matched.contains(
                            guideInflorescenceKeys[row + column],
                          ),
                          primary:
                              guideInflorescenceKeys[row + column] == primary,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _InflorescenceCell extends StatelessWidget {
  final String type;
  final String label;
  final bool matched;
  final bool primary;

  const _InflorescenceCell({
    required this.type,
    required this.label,
    required this.matched,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final border = matched ? const Color(0xFF3E5344) : const Color(0xFFE6E0D4);
    return DecoratedBox(
      key: guideInflorescenceCellKey(type),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
          width: primary
              ? 3
              : matched
                  ? 2
                  : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 7),
        child: Column(
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: Image.asset(
                'res/images/inflorescence_$type.webp',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28.8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: matched ? FontWeight.w600 : FontWeight.w400,
                  color: matched
                      ? const Color(0xFF3E5344)
                      : const Color(0xFF1A1612),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _inflorescenceLabel(S strings, String key) {
  switch (key) {
    case 'raceme':
      return strings.legend_inflorescence_raceme;
    case 'spike':
      return strings.legend_inflorescence_spike;
    case 'spadix':
      return strings.legend_inflorescence_spadix;
    case 'corymb':
      return strings.legend_inflorescence_corymb;
    case 'umbel':
      return strings.legend_inflorescence_umbel;
    case 'compound_umbel':
      return strings.legend_inflorescence_compound_umbel;
    case 'capitulum':
      return strings.legend_inflorescence_capitulum;
    case 'head':
      return strings.legend_inflorescence_head;
    case 'panicle':
      return strings.legend_inflorescence_panicle;
    case 'compound_spike':
      return strings.legend_inflorescence_compound_spike;
    case 'cyme':
      return strings.legend_inflorescence_cyme;
    case 'helicoid':
      return strings.legend_inflorescence_helicoid;
    case 'rhipidium':
      return strings.legend_inflorescence_rhipidium;
    case 'scorpioid':
      return strings.legend_inflorescence_scorpioid;
    case 'scorpioid_thyrse':
      return strings.legend_inflorescence_scorpioid_thyrse;
    case 'dichasial_thyrse':
      return strings.legend_inflorescence_dichasial_thyrse;
    case 'double_scorpioid_thyrse':
      return strings.legend_inflorescence_double_scorpioid_thyrse;
    default:
      return key;
  }
}

class _DottedUnderline extends CustomPainter {
  final Color color;

  const _DottedUnderline({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const gap = 3.0;
    const dot = 1.0;
    var x = 0.0;
    final y = size.height - 0.5;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dot, size.width), y),
        paint,
      );
      x += dot + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedUnderline oldDelegate) {
    return oldDelegate.color != color;
  }
}
