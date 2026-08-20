import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:flutter/material.dart';

class ObservationScopeSwitch extends StatelessWidget {
  final bool isPublic;
  final ValueChanged<bool> onChanged;

  const ObservationScopeSwitch({super.key, required this.isPublic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.person),
          tooltip: S.of(context).observation_private,
        ),
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.people),
          tooltip: S.of(context).observation_public,
        ),
      ],
      selected: {isPublic},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}
