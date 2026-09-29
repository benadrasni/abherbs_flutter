import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_actions.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:flutter/material.dart';

class BookPage extends StatelessWidget {
  final List<GuideListCover>? lists;
  final VoidCallback onOpenFind;

  const BookPage({
    super.key,
    required this.lists,
    required this.onOpenFind,
  });

  @override
  Widget build(BuildContext context) {
    final flowerLists = lists;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GuideTitleBar(
          title: Text(S.of(context).guide_tab_book, style: GuideType.wordmark),
          actionLabel: S.of(context).guide_search,
          icon: Icons.search,
          onAction: () => openGuideSearch(
            context,
            fromBook: true,
            onShowFind: onOpenFind,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 14),
          child: Text(
            S.of(context).custom_lists,
            style: GuideType.section,
          ),
        ),
        if (flowerLists == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          for (final cover in flowerLists) _ListRow(cover: cover),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  final GuideListCover cover;

  const _ListRow({required this.cover});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openGuideList(context, cover),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 14),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: cover.isNew
                    ? Border.all(color: GuidePalette.gold, width: 2)
                    : null,
              ),
              child: GuidePhoto(path: cover.photoPath, width: 96, height: 72),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guideListTitle(context, cover),
                    style: const TextStyle(
                      fontFamily: GuideType.serif,
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guideListSubtitle(context, cover),
                    style:
                        const TextStyle(fontSize: 13, color: GuidePalette.ink3),
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
