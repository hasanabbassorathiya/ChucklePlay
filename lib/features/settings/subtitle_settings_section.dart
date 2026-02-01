import 'package:lumio/core/widgets/dropdown_tile_widget.dart';
import 'package:lumio/core/widgets/slider_tile_widget.dart';
import 'package:lumio/features/settings/widgets/subtitle_customization_list.dart';
import 'package:lumio/repositories/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:lumio/l10n/localization_extension.dart';


class SubtitleSettingsScreen extends StatefulWidget {
  const SubtitleSettingsScreen({super.key});

  @override
  State<SubtitleSettingsScreen> createState() => _SubtitleSettingsScreenState();
}

class _SubtitleSettingsScreenState extends State<SubtitleSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.subtitle_settings),
        actions: [
          TextButton(
            onPressed: () {
              // Reset defaults logic should be inside SubtitleCustomizationList
              // or triggered via EventBus if settings are external.
              // For now, reload the screen to reflect defaults.
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SubtitleSettingsScreen()),
              );
            },
            child: Text(context.loc.reset),
          ),
        ],
      ),
      body: const SubtitleCustomizationList(showPreview: true),
    );
  }
}
