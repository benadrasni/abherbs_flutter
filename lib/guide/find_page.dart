import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_actions.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';

class FindPage extends StatelessWidget {
  final Map<String, int>? colorCounts;
  final List<GuideListCover>? lists;
  final List<GuideFind>? finds;
  final int credits;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenSeen;

  const FindPage({
    super.key,
    required this.colorCounts,
    required this.lists,
    required this.finds,
    required this.credits,
    required this.onOpenBook,
    required this.onOpenSeen,
  });

  @override
  Widget build(BuildContext context) {
    final recent = (finds ?? const <GuideFind>[]).take(5).toList();
    final flowerLists = lists;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        GuideTitleBar(
          title: const GuideWordmark(),
          actionLabel: S.of(context).guide_account,
          icon: Icons.person_outline,
          onAction: () => openGuideAccount(context),
        ),
        const _SearchButton(),
        _CameraCard(credits: credits),
        _KeyCard(colorCounts: colorCounts),
        if (recent.isNotEmpty) ...[
          GuideSectionHeader(
            title: S.of(context).guide_seen_lately,
            action: S.of(context).guide_all_finds,
            onAction: onOpenSeen,
          ),
          _FindStrip(finds: recent),
        ],
        GuideSectionHeader(
          title: S.of(context).custom_lists,
          action: S.of(context).guide_all_lists,
          onAction: onOpenBook,
        ),
        if (flowerLists == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (flowerLists.isNotEmpty)
          _ListStrip(lists: flowerLists),
        AppBannerAd(),
      ],
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
      child: Material(
        color: GuidePalette.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: GuidePalette.rule),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openGuideSearch(context),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, size: 20, color: GuidePalette.ink3),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S.of(context).guide_search,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 15, color: GuidePalette.ink3),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final int credits;

  const _CameraCard({required this.credits});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 0),
      child: Material(
        color: GuidePalette.moss,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openGuideCamera(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).guide_camera_title,
                        style: const TextStyle(
                          fontFamily: GuideType.serif,
                          fontWeight: FontWeight.w500,
                          fontSize: 21,
                          height: 1.1,
                          color: GuidePalette.paper,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context).guide_camera_body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: GuidePalette.paper.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Meter(credits: credits),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: GuidePalette.paper,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(Icons.photo_camera_outlined,
                        color: GuidePalette.moss, size: 28),
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

class _Meter extends StatelessWidget {
  final int credits;

  const _Meter({required this.credits});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      height: 1.2,
      color: GuidePalette.paper.withValues(alpha: 0.9),
    );
    if (Purchases.isPhotoSearch()) {
      return Text(S.of(context).guide_meter_unlimited, style: style);
    }
    if (Auth.appUser == null) {
      return Text(S.of(context).guide_meter_sign_in, style: style);
    }
    final left = credits;
    final filled = left.clamp(0, 5);
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _Dot(filled: i < filled),
        ],
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            S.of(context).guide_meter_left(left),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool filled;

  const _Dot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? GuidePalette.paper : Colors.transparent,
        border: Border.all(color: GuidePalette.paper, width: 1.5),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final Map<String, int>? colorCounts;

  const _KeyCard({required this.colorCounts});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final swatches = [
      ('1', s.color_white),
      ('2', s.color_yellow),
      ('3', s.color_red),
      ('4', s.color_blue),
      ('5', s.color_green),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.guide_key_step.toUpperCase(), style: GuideType.eyebrow),
              const Spacer(),
              Text(
                s.guide_always_free.toUpperCase(),
                style: GuideType.eyebrow.copyWith(color: GuidePalette.moss),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const GuideKeyStepper(filled: 1),
          const SizedBox(height: 12),
          Text(s.guide_color_question, style: GuideType.question),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final swatch in swatches)
                Expanded(
                  child: _Swatch(
                    id: swatch.$1,
                    label: guideCap(swatch.$2),
                    color: guideSwatchColor(swatch.$1),
                    count: colorCounts == null ? null : colorCounts![swatch.$1],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.guide_key_hint,
            style: const TextStyle(
                fontSize: 13, height: 1.4, color: GuidePalette.ink3),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final String id;
  final String label;
  final Color color;
  final int? count;

  const _Swatch({
    required this.id,
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openGuideColor(context, id),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x1F000000)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.15),
                    ),
                  ],
                ),
              ),
              if (count != null)
                PositionedDirectional(
                  top: 4,
                  end: 6,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      color: GuidePalette.ink3,
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

class _FindStrip extends StatelessWidget {
  final List<GuideFind> finds;

  const _FindStrip({required this.finds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: finds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final find = finds[index];
          return SizedBox(
            width: 118,
            child: InkWell(
              onTap: () => openGuidePlant(context, find.name),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GuidePhoto(path: find.photoPath, width: 118, height: 118),
                  const SizedBox(height: 6),
                  GuideName(label: find.label, latinName: find.name),
                  const SizedBox(height: 2),
                  Text(
                    guideWhen(context, find.when),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11, color: GuidePalette.ink3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListStrip extends StatelessWidget {
  final List<GuideListCover> lists;

  const _ListStrip({required this.lists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: lists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cover = lists[index];
          final title = guideListTitle(context, cover);
          return SizedBox(
            width: 150,
            child: InkWell(
              onTap: () => openGuideList(context, cover),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: cover.isNew
                          ? Border.all(color: GuidePalette.gold, width: 2)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 150,
                        height: 96,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GuidePhoto(
                              path: cover.photoPath,
                              width: 150,
                              height: 96,
                              radius: 0,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x99000000)
                                  ],
                                  stops: [0.45, 1],
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              start: 9,
                              end: 9,
                              bottom: 7,
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: GuideType.serif,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    guideListSubtitle(context, cover),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, height: 1.25, color: GuidePalette.ink3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
