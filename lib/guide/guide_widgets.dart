import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';

class GuideTitleBar extends StatelessWidget {
  final Widget title;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onAction;

  const GuideTitleBar({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.icon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 12),
      child: Row(
        children: [
          Expanded(child: title),
          const SizedBox(width: 12),
          Tooltip(
            message: actionLabel,
            child: Material(
              color: colors.cream,
              shape: CircleBorder(
                side: BorderSide(color: colors.rule),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onAction,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(icon, size: 20, color: colors.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuideWordmark extends StatelessWidget {
  const GuideWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Text.rich(
      TextSpan(
        style: GuideType.wordmark(colors),
        children: [
          TextSpan(text: S.of(context).guide_brand_lead),
          TextSpan(
            text: S.of(context).guide_brand_name,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: colors.madder,
            ),
          ),
        ],
      ),
    );
  }
}

class GuideSectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const GuideSectionHeader({
    super.key,
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 12, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: GuideType.section(colors))),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: colors.moss,
              textStyle: const TextStyle(
                fontFamily: GuideType.sans,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class GuidePhoto extends StatelessWidget {
  final String? path;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;
  final Color? background;

  const GuidePhoto({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: background ?? GuideColors.of(context).paper2,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: path == null
            ? placeholder
            : getImage(
                path!,
                placeholder,
                width: width,
                height: height,
                fit: fit,
              ),
      ),
    );
  }
}

String guideListTitle(BuildContext context, GuideListCover cover) {
  return cover.isNew ? S.of(context).guide_new_in_book : cover.title;
}

String guideListSubtitle(BuildContext context, GuideListCover cover) {
  if (cover.isNew) {
    final latest = cover.latest;
    if (latest == null) return '';
    return S.of(context).guide_latest(
          MaterialLocalizations.of(context).formatMediumDate(latest),
        );
  }
  if (cover.year != null) {
    return S.of(context).guide_years(cover.count, cover.year!);
  }
  return S.of(context).guide_plants(cover.count);
}

String guideWhen(BuildContext context, DateTime when) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(when);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(when));
  return '$date, $time';
}

class GuideName extends StatelessWidget {
  final String? label;
  final String latinName;
  final double size;
  final int maxLines;

  const GuideName({
    super.key,
    required this.label,
    required this.latinName,
    this.size = 13,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final named = label != null && label!.isNotEmpty;
    return Text(
      named ? guideCap(label!) : latinName,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: named
          ? TextStyle(
              fontFamily: GuideType.sans,
              fontWeight: FontWeight.w600,
              fontSize: size,
              height: 1.2,
              color: colors.ink,
            )
          : GuideType.latin(colors).copyWith(fontSize: size, height: 1.2),
    );
  }
}

class GuideKeyScaffold extends StatelessWidget {
  final Widget child;

  /// Habitat and petal keep the Find, Book, and Seen bar, with the banner
  /// pinned above it. The result list does not.
  final bool withTabs;

  const GuideKeyScaffold({
    super.key,
    required this.child,
    this.withTabs = false,
  });

  @override
  Widget build(BuildContext context) {
    return GuideTheme(
      navigationColor: (colors) => withTabs ? colors.cream : colors.paper,
      child: Scaffold(
        body: SafeArea(bottom: !withTabs, child: child),
        bottomNavigationBar: withTabs
            ? GuideBottomBar(
                index: 0,
                showAd: true,
                onSelect: (index) => leaveGuideKeyForTab(context, index),
              )
            : null,
      ),
    );
  }
}

/// Find, Book, and Seen. [showAd] pins the free-account banner above the tabs.
class GuideBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final bool showAd;

  const GuideBottomBar({
    super.key,
    required this.index,
    required this.onSelect,
    this.showAd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAd) const AppBannerAd(pinned: true),
        GuideTabBar(index: index, onSelect: onSelect),
      ],
    );
  }
}

class GuideTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const GuideTabBar({super.key, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final items = [
      (S.of(context).guide_tab_find, Icons.center_focus_weak),
      (S.of(context).guide_tab_book, Icons.menu_book_outlined),
      (S.of(context).guide_tab_seen, Icons.article_outlined),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cream,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$2,
                          size: 24,
                          color: i == index ? colors.moss : colors.ink3,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                i == index ? FontWeight.w600 : FontWeight.w400,
                            color: i == index ? colors.moss : colors.ink3,
                          ),
                        ),
                      ],
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

class GuideBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GuideBackButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: colors.moss, size: 20),
                child: BackButtonIcon(),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.moss,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuideKeyStepper extends StatelessWidget {
  final int filled;

  const GuideKeyStepper({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i < filled ? colors.madderFill : colors.rule,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(height: 3),
            ),
          ),
        ],
      ],
    );
  }
}

class GuideFilterPill extends StatelessWidget {
  final Widget? leading;
  final String label;
  final VoidCallback onPressed;

  const GuideFilterPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Material(
      color: colors.mossFill,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.close, size: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void guideNoFlowers(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(S.of(context).snack_no_flowers)),
  );
}
