import 'dart:io';

import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/shell/app_version.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/shell/play_update.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String _playListing =
    'https://play.google.com/store/apps/details?id=sk.ab.herbs';

/// Shared with the app builder so a block covers every route, not only the shell.
class VersionGateController extends ChangeNotifier {
  VersionGateController._();

  static final instance = VersionGateController._();

  VersionPrompt prompt = VersionPrompt.none;

  void apply(VersionPrompt next) {
    if (prompt == next) return;
    prompt = next;
    notifyListeners();
  }

  void resetForTest() {
    prompt = VersionPrompt.none;
    notifyListeners();
  }
}

Future<bool> _openExternal(String path) async {
  try {
    return await launchUrl(
      Uri.parse(path),
      mode: LaunchMode.externalApplication,
    );
  } catch (error) {
    debugPrint('store listing: $error');
    return false;
  }
}

/// Opens the store. A required Android update tries Play's immediate flow
/// first. A denial leaves the gate up. No Play offer falls through to the listing.
Future<void> openAppUpdate({required bool requiredUpdate}) async {
  if (requiredUpdate && Platform.isAndroid) {
    final outcome = await playImmediateUpdate();
    if (outcome != PlayUpdateOutcome.unavailable) return;
  }
  if (Platform.isAndroid) {
    if (await _openExternal(playStore)) return;
    await _openExternal(_playListing);
    return;
  }
  await _openExternal(appStoreListing);
}

class VersionRequiredPage extends StatefulWidget {
  final Future<void> Function() onUpdate;

  const VersionRequiredPage({super.key, required this.onUpdate});

  @override
  State<VersionRequiredPage> createState() => _VersionRequiredPageState();
}

class _VersionRequiredPageState extends State<VersionRequiredPage> {
  bool _opening = false;

  Future<void> _tap() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onUpdate();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GuideTheme(
      child: Builder(
        builder: (context) {
          final colors = GuideColors.of(context);
          return PopScope(
            canPop: false,
            child: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    key: const Key('version-required'),
                    children: [
                      const Spacer(),
                      const GuideWordmark(),
                      const SizedBox(height: 20),
                      Text(
                        S.of(context).version_required,
                        style: GuideType.section(colors),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        key: const Key('version-required-update'),
                        onPressed: _opening ? null : _tap,
                        child: Text(S.of(context).guide_offline_update),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VersionBanner extends StatelessWidget {
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const VersionBanner({
    super.key,
    required this.onUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Material(
      key: const Key('version-banner'),
      color: colors.cream,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                S.of(context).new_version,
                style: TextStyle(
                  fontFamily: GuideType.sans,
                  color: colors.ink,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
            TextButton(
              key: const Key('version-banner-update'),
              onPressed: onUpdate,
              child: Text(S.of(context).guide_offline_update),
            ),
            IconButton(
              key: const Key('version-banner-dismiss'),
              tooltip: S.of(context).close,
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colors.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
