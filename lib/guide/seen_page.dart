import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_actions.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:flutter/material.dart';

class SeenPage extends StatelessWidget {
  final List<GuideFind>? finds;

  const SeenPage({super.key, required this.finds});

  @override
  Widget build(BuildContext context) {
    final saved = finds;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GuideTitleBar(
          title: Text(S.of(context).guide_tab_seen, style: GuideType.wordmark),
          actionLabel: S.of(context).guide_camera_title,
          icon: Icons.photo_camera_outlined,
          onAction: () => openGuideCamera(context),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
          child: saved == null
              ? const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Text(
                  saved.isEmpty ? S.of(context).guide_seen_empty : '',
                  style:
                      const TextStyle(fontSize: 13, color: GuidePalette.ink3),
                ),
        ),
        if (saved != null)
          for (final find in saved)
            InkWell(
              onTap: () => openGuidePlant(context, find.name),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                child: Row(
                  children: [
                    GuidePhoto(
                        path: find.photoPath,
                        width: 74,
                        height: 74,
                        radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GuideName(
                              label: find.label,
                              latinName: find.name,
                              size: 17,
                              maxLines: 2),
                          if (find.label != null && find.label!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              find.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GuideType.latin.copyWith(
                                  fontSize: 13, color: GuidePalette.ink3),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            guideWhen(context, find.when),
                            style: const TextStyle(
                                fontSize: 12, color: GuidePalette.ink3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
