import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class ActionsSection extends StatelessWidget {
  const ActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (provider.hasSaved || provider.isSaving)
                ? null
                : () => provider.savePcaResults(),
            icon: provider.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FaIcon(
                    provider.hasSaved
                        ? FontAwesomeIcons.check
                        : FontAwesomeIcons.floppyDisk,
                    size: 14,
                  ),
            label: Text(provider.isSaving
                ? 'Saving...'
                : provider.hasSaved
                    ? 'Saved'
                    : 'Save Results'),
          ),
        ),
      ],
    );
  }
}
