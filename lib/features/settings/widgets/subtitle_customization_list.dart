import 'package:flutter/material.dart';
import 'package:lumio/core/widgets/color_picker_tile_widget.dart';
import 'package:lumio/core/widgets/dropdown_tile_widget.dart';
import 'package:lumio/core/widgets/slider_tile_widget.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/repositories/user_preferences.dart';
import 'package:lumio/services/event_bus.dart';

class SubtitleCustomizationList extends StatefulWidget {
  final bool showPreview;

  const SubtitleCustomizationList({super.key, this.showPreview = true});

  @override
  State<SubtitleCustomizationList> createState() => _SubtitleCustomizationListState();
}

class _SubtitleCustomizationListState extends State<SubtitleCustomizationList> {
  bool _isLoading = true;

  double _fontSize = 32.0;
  double _height = 1.4;
  double _letterSpacing = 0.0;
  double _wordSpacing = 0.0;
  Color _textColor = const Color(0xffffffff);
  Color _backgroundColor = const Color(0xaa000000);
  FontWeight _fontWeight = FontWeight.normal;
  TextAlign _textAlign = TextAlign.center;
  double _padding = 24.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _fontSize = await UserPreferences.getSubtitleFontSize();
    _height = await UserPreferences.getSubtitleHeight();
    _letterSpacing = await UserPreferences.getSubtitleLetterSpacing();
    _wordSpacing = await UserPreferences.getSubtitleWordSpacing();
    _textColor = await UserPreferences.getSubtitleTextColor();
    _backgroundColor = await UserPreferences.getSubtitleBackgroundColor();
    _fontWeight = await UserPreferences.getSubtitleFontWeight();
    _textAlign = await UserPreferences.getSubtitleTextAlign();
    _padding = await UserPreferences.getSubtitlePadding();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await UserPreferences.setSubtitleFontSize(_fontSize);
    await UserPreferences.setSubtitleHeight(_height);
    await UserPreferences.setSubtitleLetterSpacing(_letterSpacing);
    await UserPreferences.setSubtitleWordSpacing(_wordSpacing);
    await UserPreferences.setSubtitleTextColor(_textColor);
    await UserPreferences.setSubtitleBackgroundColor(_backgroundColor);
    await UserPreferences.setSubtitleFontWeight(_fontWeight);
    await UserPreferences.setSubtitleTextAlign(_textAlign);
    await UserPreferences.setSubtitlePadding(_padding);

    // Notify listeners (PlayerWidget) about the change
    EventBus().emit('subtitle_config_changed', null);
  }

  Future<void> _updateFontSize(double value) async {
    setState(() => _fontSize = value);
    await _saveSettings();
  }

  void _updateHeight(double value) {
    setState(() => _height = value);
    _saveSettings();
  }

  void _updateLetterSpacing(double value) {
    setState(() => _letterSpacing = value);
    _saveSettings();
  }

  void _updateWordSpacing(double value) {
    setState(() => _wordSpacing = value);
    _saveSettings();
  }

  void _updatePadding(double value) {
    setState(() => _padding = value);
    _saveSettings();
  }

  void _updateTextColor(Color color) {
    setState(() => _textColor = color);
    _saveSettings();
  }

  void _updateBackgroundColor(Color color) {
    setState(() => _backgroundColor = color);
    _saveSettings();
  }

  void _updateFontWeight(FontWeight weight) {
    setState(() => _fontWeight = weight);
    _saveSettings();
  }

  void _updateTextAlign(TextAlign align) {
    setState(() => _textAlign = align);
    _saveSettings();
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.loc.preview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_padding),
                decoration: BoxDecoration(
                  color: Colors.grey[900], // Always dark for subtitle preview
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://picsum.photos/800/400'), // Optional background
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                ),
                child: Text(
                  context.loc.sample_text,
                  textAlign: _textAlign,
                  // Scale down for preview if not in full player
                  textScaler: const TextScaler.linear(0.5),
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: _height,
                    letterSpacing: _letterSpacing,
                    wordSpacing: _wordSpacing,
                    color: _textColor,
                    backgroundColor: _backgroundColor,
                    fontWeight: _fontWeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (widget.showPreview) _buildPreviewCard(),

        Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.loc.font_settings,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SliderTileWidget(
                icon: Icons.format_size,
                label: context.loc.font_size,
                value: _fontSize,
                min: 12,
                max: 72,
                divisions: 60,
                onChanged: _updateFontSize,
              ),
              const Divider(height: 1),
              SliderTileWidget(
                icon: Icons.format_line_spacing,
                label: context.loc.font_height,
                value: _height,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                onChanged: _updateHeight,
              ),
              const Divider(height: 1),
              SliderTileWidget(
                icon: Icons.space_bar,
                label: context.loc.letter_spacing,
                value: _letterSpacing,
                min: -2.0,
                max: 5.0,
                divisions: 70,
                onChanged: _updateLetterSpacing,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.loc.color_settings,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ColorPickerTileWidget(
                title: context.loc.text_color,
                icon: Icons.format_color_text,
                color: _textColor,
                onChanged: _updateTextColor,
              ),
              const Divider(height: 1),
              ColorPickerTileWidget(
                title: context.loc.background_color,
                icon: Icons.format_color_fill,
                color: _backgroundColor,
                onChanged: _updateBackgroundColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.style,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.loc.style_settings,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              DropdownTileWidget<FontWeight>(
                icon: Icons.format_bold,
                label: context.loc.font_weight,
                value: _fontWeight,
                items: [
                  DropdownMenuItem(
                    value: FontWeight.w300,
                    child: Text(context.loc.thin),
                  ),
                  DropdownMenuItem(
                    value: FontWeight.normal,
                    child: Text(context.loc.normal),
                  ),
                  DropdownMenuItem(
                    value: FontWeight.w500,
                    child: Text(context.loc.medium),
                  ),
                  DropdownMenuItem(
                    value: FontWeight.bold,
                    child: Text(context.loc.bold),
                  ),
                  DropdownMenuItem(
                    value: FontWeight.w900,
                    child: Text(context.loc.extreme_bold),
                  ),
                ],
                onChanged: (v) => _updateFontWeight(v!),
              ),
              const Divider(height: 1),
              SliderTileWidget(
                icon: Icons.padding,
                label: context.loc.padding,
                value: _padding,
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: _updatePadding,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
