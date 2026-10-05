import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/shell/guide_actions.dart';
import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/seen/guide_seen_store.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/camera/outside_page.dart';
import 'package:abherbs_flutter/person/sign_in_page.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class SeenPage extends StatefulWidget {
  final List<GuideSeenFind>? finds;
  final bool signedIn;
  final bool fieldGuide;
  final Future<void> Function(GuideSeenFind find)? onConfirm;
  final Future<void> Function(GuideSeenFind find)? onDelete;
  final Future<void> Function(GuideSeenFind find, String plant)? onRetarget;
  final Future<bool> Function(GuideSeenFind find)? onShare;
  final Future<bool> Function(GuideSeenFind find)? onWithdraw;
  final void Function(BuildContext context, GuideSeenFind find)? onOpen;
  final void Function(BuildContext context, GuideSeenFind find)? onOpenOutside;
  final void Function(BuildContext context)? onCamera;
  final void Function(BuildContext context)? onFieldGuide;
  final void Function(BuildContext context)? onSearch;
  final Future<void> Function(BuildContext context)? onSignIn;

  /// Overrides the phone preference when set.
  final bool? hideShared;

  const SeenPage({
    super.key,
    required this.finds,
    this.signedIn = false,
    this.fieldGuide = false,
    this.onConfirm,
    this.onDelete,
    this.onRetarget,
    this.onShare,
    this.onWithdraw,
    this.onOpen,
    this.onOpenOutside,
    this.onCamera,
    this.onFieldGuide,
    this.onSearch,
    this.onSignIn,
    this.hideShared,
  });

  @override
  State<SeenPage> createState() => _SeenPageState();
}

class _SeenPageState extends State<SeenPage> {
  final Set<String> _busy = {};
  bool? _hideShared;

  bool get _hidingShared {
    final chosen = _hideShared;
    if (chosen != null) return chosen;
    final given = widget.hideShared;
    if (given != null) return given;
    if (!Prefs.ready()) return false;
    return Prefs.getBool(keyGuideSeenHideShared, false);
  }

  void _toggleHideShared() {
    final next = !_hidingShared;
    setState(() => _hideShared = next);
    if (Prefs.ready()) {
      Prefs.setBool(keyGuideSeenHideShared, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final finds = widget.finds;
    final sharedCount = finds == null ? 0 : guideSeenSharedCount(finds);
    final hiding = _hidingShared && sharedCount > 0;
    final visible = finds == null
        ? null
        : (hiding ? guideSeenHidingShared(finds).toList() : finds);
    final notebook = visible == null ? null : arrangeGuideSeen(visible);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GuideTitleBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.guide_tab_seen, style: GuideType.wordmark(colors)),
              if (finds != null) ...[
                const SizedBox(height: 2),
                Text(
                  _subtitle(
                    strings,
                    visible!.length,
                    hiding ? sharedCount : 0,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: colors.ink3,
                  ),
                ),
              ],
            ],
          ),
          leadingLabel: strings.observation_stats,
          leadingIcon: Icons.bar_chart_outlined,
          onLeading: () {
            openGuideStatistics(
              context,
              finds: finds,
              backLabel: strings.guide_tab_seen,
            );
          },
          actionLabel: strings.guide_camera_title,
          icon: Icons.photo_camera_outlined,
          onAction: () {
            final open = widget.onCamera;
            if (open != null) {
              open(context);
            } else {
              openGuideCamera(context);
            }
          },
        ),
        if (notebook == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          if (finds != null && finds.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              child: Text(
                strings.guide_seen_empty,
                style: TextStyle(fontSize: 13, color: colors.ink3),
              ),
            ),
          if (notebook.unconfirmed.isNotEmpty) ...[
            _MonthLabel(
              text: strings
                  .guide_seen_to_confirm(notebook.unconfirmed.length)
                  .toUpperCase(),
              color: colors.madder,
            ),
            for (final find in notebook.unconfirmed)
              _ConfirmCard(
                find: find,
                busy: _busy.contains(find.id),
                onOpen: () => _open(find),
                onConfirm: () => _confirm(find),
                onAnother: () => _another(find),
                onDelete: () => _delete(find),
              ),
          ],
          if (sharedCount > 0)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _Pill(
                  key: const Key('guide-seen-hide-shared'),
                  label: hiding
                      ? strings.guide_seen_shared_hidden(sharedCount)
                      : strings.guide_seen_hide_shared(sharedCount),
                  onPressed: _toggleHideShared,
                  foreground: hiding ? Colors.white : colors.ink,
                  background: hiding ? colors.mossFill : colors.cream,
                  border: hiding ? null : colors.rule,
                ),
              ),
            ),
          if (hiding && visible!.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 8),
              child: Text(
                strings.guide_seen_only_shared,
                style: TextStyle(fontSize: 13, color: colors.ink3),
              ),
            ),
          for (final month in notebook.months) ...[
            _MonthLabel(
              text: DateFormat.yMMMM(
                Localizations.localeOf(context).toString(),
              ).format(month.month).toUpperCase(),
            ),
            for (final find in month.finds)
              _FindRow(
                find: find,
                busy: _busy.contains(find.id),
                onOpen: () => _open(find),
                onShare: () => _share(find),
                onWithdraw: () => _withdraw(find),
                onDelete: () => _askDelete(find),
              ),
          ],
          if (!widget.fieldGuide)
            _Upsell(
              onPressed: () {
                final open = widget.onFieldGuide;
                if (open != null) {
                  open(context);
                } else {
                  openGuideFieldGuide(context);
                }
              },
            ),
        ],
      ],
    );
  }

  String _subtitle(S strings, int count, int hidden) {
    final where = widget.signedIn
        ? (widget.fieldGuide
            ? strings.guide_seen_on_devices
            : strings.guide_seen_on_account)
        : strings.guide_seen_on_phone;
    final finds = strings.guide_seen_finds(count);
    if (hidden > 0) {
      return '$finds · ${strings.guide_seen_shared_hidden_count(hidden)} · $where';
    }
    return '$finds · $where';
  }

  void _open(GuideSeenFind find) {
    if (!find.inBook) {
      final outside = widget.onOpenOutside;
      if (outside != null) {
        outside(context, find);
        return;
      }
      unawaited(_openOutside(find));
      return;
    }
    final open = widget.onOpen;
    if (open != null) {
      open(context, find);
    } else {
      openGuidePlant(context, find.name);
    }
  }

  Future<void> _openOutside(GuideSeenFind find) async {
    final place = find.place?.trim() ?? '';
    final result = await Navigator.push<GuideOutsideResult>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: guideOutsideRouteName),
        builder: (routeContext) => GuideOutsidePage(
          outcome: GuideCameraOutcome.outside(
            GuideCameraHit(
              latin: find.name,
              vernacular: find.label,
              probability: find.probability,
            ),
            [
              for (final other in find.others)
                GuideCameraHit(
                  latin: other.latin,
                  vernacular: other.vernacular,
                  probability: other.probability,
                  path: other.path,
                ),
            ],
          ),
          photoPath: find.photoPath,
          when: find.when,
          place: place.isEmpty ? S.of(context).guide_outside_no_place : place,
          observationId: find.id,
          confirmed: find.confirmed,
          onConfirm: (id) => setGuideCameraConfirmed(
            id: id,
            plant: find.name,
            confirmed: true,
          ),
          onDelete: (id) => deleteGuideCameraFind(id: id, plant: find.name),
          onRetarget: (id, from, to) => retargetGuideCameraFind(
            id: id,
            from: from,
            to: to,
          ),
          onOpenSpecies: (name) => openGuidePlant(context, name),
          onSearch: () {
            final search = widget.onSearch;
            if (search != null) {
              search(context);
            } else {
              openGuideSearch(context);
            }
          },
        ),
      ),
    );
    if (!mounted || result == null || result.find) return;
    final message = result.message;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    GuideTabs.refreshSeen?.call();
    final species = result.openSpecies;
    if (species == null) return;
    await openGuidePlant(context, species);
  }

  Future<void> _confirm(GuideSeenFind find) async {
    if (!_busy.add(find.id)) return;
    setState(() {});
    try {
      final action = widget.onConfirm;
      if (action != null) {
        await action(find);
      } else {
        await setGuideCameraConfirmed(
          id: find.id,
          plant: find.name,
          confirmed: true,
        );
        GuideTabs.refreshSeen?.call();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).guide_camera_confirmed)),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(find.id));
    }
  }

  Future<void> _askDelete(GuideSeenFind find) async {
    if (_busy.contains(find.id)) return;
    final strings = S.of(context);
    final String body;
    switch (find.share) {
      case GuideSeenShare.shared:
        body = strings.guide_seen_delete_shared_body;
        break;
      case GuideSeenShare.review:
      case GuideSeenShare.rejected:
        body = strings.guide_seen_delete_sent_body;
        break;
      case GuideSeenShare.none:
        body = strings.guide_seen_delete_body;
        break;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GuideTheme(
          child: _DeleteSheet(
            title: strings.guide_seen_delete_title,
            body: body,
            onDelete: () {
              Navigator.pop(sheetContext);
              unawaited(_delete(find));
            },
          ),
        );
      },
    );
  }

  Future<void> _delete(GuideSeenFind find) async {
    if (!_busy.add(find.id)) return;
    setState(() {});
    try {
      final action = widget.onDelete;
      var ok = true;
      if (action != null) {
        await action(find);
      } else {
        ok = await deleteGuideSeenFind(
          id: find.id,
          plant: find.name,
          share: find.share,
        );
        if (ok) GuideTabs.refreshSeen?.call();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? S.of(context).guide_outside_deleted
                : S.of(context).guide_seen_delete_failed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(find.id));
    }
  }

  Future<void> _another(GuideSeenFind find) async {
    if (_busy.contains(find.id)) return;
    final chosen = await showGuideOtherNames(
      context: context,
      candidates: [
        for (final other in find.others)
          GuideCameraHit(
            latin: other.latin,
            vernacular: other.vernacular,
            probability: other.probability,
            path: other.path,
          ),
      ],
      onSearch: () {
        if (!mounted) return;
        final search = widget.onSearch;
        if (search != null) {
          search(context);
        } else {
          openGuideSearch(context);
        }
      },
    );
    if (!mounted || chosen == null) return;
    final name = guideCameraSpeciesName(chosen);
    if (name == null) return;
    if (!_busy.add(find.id)) return;
    setState(() {});
    try {
      final action = widget.onRetarget;
      if (action != null) {
        await action(find, name);
      } else {
        await retargetGuideCameraFind(id: find.id, from: find.name, to: name);
        GuideTabs.refreshSeen?.call();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).guide_outside_changed)),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(find.id));
    }
  }

  Future<void> _share(GuideSeenFind find) async {
    if (!find.ownPhoto || !find.photoAttached) return;
    if (!widget.signedIn) {
      final signIn = widget.onSignIn;
      if (signIn != null) {
        await signIn(context);
      } else {
        await openGuideSignIn(context);
      }
      return;
    }
    final title = find.label != null && find.label!.trim().isNotEmpty
        ? find.label!.trim()
        : find.name;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return GuideTheme(
          child: _ShareSheet(
            find: find,
            title: title,
            detail: _detailOf(context, find),
            onSend: () => _sendShare(sheetContext, find),
          ),
        );
      },
    );
  }

  Future<void> _sendShare(BuildContext sheetContext, GuideSeenFind find) async {
    Navigator.pop(sheetContext);
    final action = widget.onShare;
    final ok =
        action != null ? await action(find) : await shareGuideFind(find.id);
    if (!mounted) return;
    if (ok) GuideTabs.refreshSeen?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? S.of(context).guide_seen_share_sent
              : S.of(context).guide_seen_share_failed,
        ),
      ),
    );
  }

  Future<void> _withdraw(GuideSeenFind find) async {
    final title = find.label != null && find.label!.trim().isNotEmpty
        ? find.label!.trim()
        : find.name;
    final review = find.share == GuideSeenShare.review;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GuideTheme(
          child: _WithdrawSheet(
            title: review
                ? S.of(context).guide_seen_withdraw_review_title
                : S.of(context).guide_seen_is_sighting(title),
            body: review
                ? S.of(context).guide_seen_withdraw_review_body
                : S.of(context).guide_seen_withdraw_body,
            onWithdraw: () => _sendWithdraw(sheetContext, find),
          ),
        );
      },
    );
  }

  Future<void> _sendWithdraw(
    BuildContext sheetContext,
    GuideSeenFind find,
  ) async {
    Navigator.pop(sheetContext);
    final action = widget.onWithdraw;
    final ok = action != null
        ? await action(find)
        : await withdrawGuideFind(id: find.id, plant: find.name);
    if (!mounted) return;
    if (ok) GuideTabs.refreshSeen?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? S.of(context).guide_seen_withdrawn
              : S.of(context).guide_seen_share_failed,
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const _MonthLabel({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.96,
          fontWeight: FontWeight.w600,
          color: color ?? colors.ink3,
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final GuideSeenFind find;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onConfirm;
  final VoidCallback onAnother;
  final VoidCallback onDelete;

  const _ConfirmCard({
    required this.find,
    required this.busy,
    required this.onOpen,
    required this.onConfirm,
    required this.onAnother,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final named = find.label != null && find.label!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.rule),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              InkWell(
                onTap: busy ? null : onOpen,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      GuidePhoto(
                        path: find.photoPath,
                        width: 74,
                        height: 74,
                        radius: 10,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (find.probability != null) ...[
                              GuideConfidenceMark(
                                  probability: find.probability),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              named ? find.label!.trim() : find.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: named
                                  ? TextStyle(
                                      fontFamily: GuideType.serif,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      height: 1.1,
                                      color: colors.ink,
                                    )
                                  : GuideType.latin(colors).copyWith(
                                      fontSize: 18,
                                      height: 1.1,
                                    ),
                            ),
                            if (named) ...[
                              const SizedBox(height: 2),
                              Text(
                                find.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GuideType.latin(colors).copyWith(
                                  fontSize: 13,
                                  color: colors.ink3,
                                ),
                              ),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              _detailOf(context, find),
                              style:
                                  TextStyle(fontSize: 12, color: colors.ink3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.rule)),
                ),
                child: Row(
                  children: [
                    _CardAction(
                      key: Key('guide-seen-confirm-${find.id}'),
                      label: strings.guide_seen_confirm,
                      color: colors.moss,
                      busy: busy,
                      onPressed: onConfirm,
                    ),
                    _CardAction(
                      key: Key('guide-seen-another-${find.id}'),
                      label: strings.guide_seen_another,
                      color: colors.moss,
                      busy: busy,
                      onPressed: onAnother,
                    ),
                    _CardAction(
                      key: Key('guide-seen-delete-${find.id}'),
                      label: strings.guide_outside_delete,
                      color: colors.madder,
                      last: true,
                      busy: busy,
                      onPressed: onDelete,
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

String _detailOf(BuildContext context, GuideSeenFind find) {
  final when = DateFormat.MMMd(
    Localizations.localeOf(context).toString(),
  ).format(find.when);
  return guideSeenDetail(when, find.place);
}

class _CardAction extends StatelessWidget {
  final String label;
  final Color color;
  final bool last;
  final bool busy;
  final VoidCallback onPressed;

  const _CardAction({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.last = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: last
              ? null
              : BorderDirectional(end: BorderSide(color: colors.rule)),
        ),
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FindRow extends StatelessWidget {
  final GuideSeenFind find;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onWithdraw;
  final VoidCallback onDelete;

  const _FindRow({
    required this.find,
    required this.busy,
    required this.onOpen,
    required this.onShare,
    required this.onWithdraw,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final named = find.label != null && find.label!.trim().isNotEmpty;
    final chip = guideSeenChip(find);
    final trailing = Directionality.of(context) == TextDirection.rtl
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 9, 20, 9),
      child: Row(
        children: [
          InkWell(
            onTap: onOpen,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: GuidePhoto(
              path: find.photoPath,
              width: 44,
              height: 44,
              radius: 8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    named ? find.label!.trim() : find.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: named
                        ? TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colors.ink,
                          )
                        : GuideType.latin(colors).copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _detailOf(context, find),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.ink3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: trailing,
            children: [
              if (chip != null)
                _ShareChip(
                  chip: chip,
                  onShare: onShare,
                  onWithdraw: onWithdraw,
                  onOutside: onOpen,
                ),
              TextButton(
                key: Key('guide-seen-row-delete-${find.id}'),
                onPressed: busy ? null : onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: colors.madder,
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(strings.guide_outside_delete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareChip extends StatelessWidget {
  final GuideSeenChip chip;
  final VoidCallback onShare;
  final VoidCallback onWithdraw;
  final VoidCallback onOutside;

  const _ShareChip({
    required this.chip,
    required this.onShare,
    required this.onWithdraw,
    required this.onOutside,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    switch (chip) {
      case GuideSeenChip.share:
        return _Pill(
          key: const Key('guide-seen-share'),
          label: strings.guide_share,
          onPressed: onShare,
          foreground: colors.ink,
          background: colors.cream,
          border: colors.rule,
        );
      case GuideSeenChip.shared:
        return _Pill(
          key: const Key('guide-seen-shared'),
          label: strings.guide_seen_shared,
          onPressed: onWithdraw,
          foreground: Colors.white,
          background: colors.mossFill,
        );
      case GuideSeenChip.review:
        return _Pill(
          key: const Key('guide-seen-review'),
          label: strings.guide_seen_in_review,
          onPressed: onWithdraw,
          foreground: colors.gold,
          background: Color.alphaBlend(
            colors.gold.withValues(alpha: 0.14),
            colors.cream,
          ),
        );
      case GuideSeenChip.rejected:
        return _Status(
          label: strings.guide_seen_not_accepted,
          foreground: colors.madder,
          background: Color.alphaBlend(
            colors.madder.withValues(alpha: 0.14),
            colors.cream,
          ),
        );
      case GuideSeenChip.outside:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('guide-seen-outside'),
            onTap: onOutside,
            borderRadius: BorderRadius.circular(12),
            child: _Status(
              label: strings.guide_seen_not_in_book,
              foreground: colors.ink3,
              background: colors.paper2,
            ),
          ),
        );
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color foreground;
  final Color background;
  final Color? border;

  const _Pill({
    super.key,
    required this.label,
    required this.onPressed,
    required this.foreground,
    required this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: border == null ? BorderSide.none : BorderSide(color: border!),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _Status extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _Status({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _Upsell extends StatelessWidget {
  final VoidCallback onPressed;

  const _Upsell({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.mossFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.guide_seen_upsell_title,
                style: TextStyle(
                  fontFamily: GuideType.serif,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: colors.onMoss,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.guide_seen_upsell_body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: colors.onMoss.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('guide-seen-upsell'),
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: colors.mossFill,
                  backgroundColor: colors.onMoss,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(strings.guide_seen_upsell_action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  final GuideSeenFind find;
  final String title;
  final String detail;
  final VoidCallback onSend;

  const _ShareSheet({
    required this.find,
    required this.title,
    required this.detail,
    required this.onSend,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _consent = false;

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GuidePhoto(
                  path: widget.find.photoPath,
                  width: 64,
                  height: 64,
                  radius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.guide_seen_share_title(widget.title),
                        style: GuideType.section(colors),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.find.name,
                        style: GuideType.latin(colors).copyWith(
                          fontSize: 13,
                          color: colors.ink3,
                        ),
                      ),
                      Text(
                        widget.detail,
                        style: TextStyle(fontSize: 13, color: colors.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Fact(strings.guide_seen_share_reviewed),
            _Fact(strings.guide_seen_share_place),
            _Fact(strings.guide_seen_share_note),
            _Fact(strings.guide_seen_share_anytime),
            const SizedBox(height: 8),
            InkWell(
              key: const Key('guide-seen-consent'),
              onTap: () => setState(() => _consent = !_consent),
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.rule),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              _consent ? colors.mossFill : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _consent ? colors.mossFill : colors.ink3,
                            width: 1.5,
                          ),
                        ),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: _consent
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.guide_seen_share_consent,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('guide-seen-send'),
              onPressed: _consent ? widget.onSend : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.mossFill,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    colors.mossFill.withValues(alpha: 0.45),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(strings.guide_seen_share_send),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String text;

  const _Fact(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, height: 1.45, color: colors.ink2),
      ),
    );
  }
}

class _DeleteSheet extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onDelete;

  const _DeleteSheet({
    required this.title,
    required this.body,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: GuideType.question(colors)),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontSize: 15, height: 1.4, color: colors.ink2),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('guide-seen-delete-confirm'),
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.madder,
                side: BorderSide(color: colors.rule),
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(strings.guide_outside_delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSheet extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onWithdraw;

  const _WithdrawSheet({
    required this.title,
    required this.body,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.rule,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: GuideType.question(colors)),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontSize: 15, height: 1.4, color: colors.ink2),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('guide-seen-withdraw'),
              onPressed: onWithdraw,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.madder,
                side: BorderSide(color: colors.rule),
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(strings.guide_seen_withdraw),
            ),
          ],
        ),
      ),
    );
  }
}
