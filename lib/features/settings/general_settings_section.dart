import 'package:lumio/controllers/favorites_controller.dart';
import 'package:lumio/controllers/watch_history_controller.dart';
import 'package:lumio/features/auth/widgets/login_dialog.dart';
import 'package:lumio/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumio/controllers/locale_provider.dart';
import 'package:lumio/controllers/theme_provider.dart';
import 'package:lumio/database/database.dart';
import 'package:lumio/features/settings/subtitle_settings_section.dart';
import 'package:lumio/features/settings/category_settings_section.dart';
import 'package:lumio/features/playlist/m3u_data_loader_screen.dart';
import 'package:lumio/features/playlist/xtream_code_data_loader_screen.dart';
import 'package:lumio/core/widgets/dropdown_tile_widget.dart';
import 'package:lumio/core/widgets/section_title_widget.dart';
import 'package:lumio/features/playlist/playlist_screen.dart';
import 'package:lumio/controllers/xtream_code_home_controller.dart';
import 'package:lumio/l10n/localization_extension.dart';
import 'package:lumio/l10n/supported_languages.dart';
import 'package:lumio/models/m3u_item.dart';
import 'package:lumio/repositories/user_preferences.dart';
import 'package:lumio/services/app_state.dart';
import 'package:lumio/services/m3u_parser.dart';
import 'package:lumio/services/service_locator.dart';
import 'package:lumio/utils/get_playlist_type.dart';
import 'package:lumio/utils/show_loading_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GeneralSettingsWidget extends StatefulWidget {
  const GeneralSettingsWidget({super.key});

  @override
  State<GeneralSettingsWidget> createState() => _GeneralSettingsWidgetState();
}

class _GeneralSettingsWidgetState extends State<GeneralSettingsWidget> {
  final AppDatabase database = getIt<AppDatabase>();
  late final XtreamCodeHomeController _xtreamController;

  bool _backgroundPlayEnabled = false;
  bool _isLoading = true;
  String? _selectedFilePath;
  String _selectedTheme = 'system';
  bool _brightnessGesture = false;
  bool _volumeGesture = false;
  bool _seekGesture = false;
  bool _speedUpOnLongPress = true;
  bool _seekOnDoubleTap = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _xtreamController = XtreamCodeHomeController(all: true);
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isXtreamCode) {
        _xtreamController.init(true);
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      final backgroundPlay = await UserPreferences.getBackgroundPlay();
      final themeMode = await UserPreferences.getThemeMode();
      final brightnessGesture = await UserPreferences.getBrightnessGesture();
      final volumeGesture = await UserPreferences.getVolumeGesture();
      final seekGesture = await UserPreferences.getSeekGesture();
      final speedUpOnLongPress = await UserPreferences.getSpeedUpOnLongPress();
      final seekOnDoubleTap = await UserPreferences.getSeekOnDoubleTap();
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _backgroundPlayEnabled = backgroundPlay;
        _selectedTheme = _themeModeToString(themeMode);
        _brightnessGesture = brightnessGesture;
        _volumeGesture = volumeGesture;
        _seekGesture = seekGesture;
        _speedUpOnLongPress = speedUpOnLongPress;
        _seekOnDoubleTap = seekOnDoubleTap;
        _appVersion = packageInfo.version;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _saveBackgroundPlaySetting(bool value) async {
    try {
      await UserPreferences.setBackgroundPlay(value);
      setState(() {
        _backgroundPlayEnabled = value;
      });
    } catch (e) {
      setState(() {
        _backgroundPlayEnabled = !value;
      });
    }
  }

  Widget _buildFocusableListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return FocusableControlBuilder(
      onPressed: onTap,
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? const Color(0xFFE50914).withValues(alpha: 0.1) : null,
              border: isFocused
                  ? const Border(
                      left: BorderSide(color: Color(0xFFE50914), width: 4),
                    )
                  : null,
            ),
            child: ListTile(
              leading: Icon(icon, color: isFocused ? const Color(0xFFE50914) : null),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isFocused ? FontWeight.bold : null,
                  color: isFocused ? Theme.of(context).colorScheme.onSurface : null,
                ),
              ),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: trailing ?? const Icon(Icons.chevron_right),
              selected: isFocused,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusableSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FocusableControlBuilder(
      onPressed: () => onChanged(!value),
      builder: (context, state) {
        final isFocused = state.isFocused;
        return AnimatedScale(
          scale: isFocused ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: isFocused ? const Color(0xFFE50914).withValues(alpha: 0.1) : null,
              border: isFocused
                  ? const Border(
                      left: BorderSide(color: Color(0xFFE50914), width: 4),
                    )
                  : null,
            ),
            child: SwitchListTile(
              secondary: Icon(icon, color: isFocused ? const Color(0xFFE50914) : null),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isFocused ? FontWeight.bold : null,
                  color: isFocused ? Theme.of(context).colorScheme.onSurface : null,
                ),
              ),
              subtitle: Text(subtitle),
              value: value,
              onChanged: onChanged,
              selected: isFocused,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: _buildFocusableListTile(
                  icon: Icons.home,
                  title: context.loc.playlist_list,
                  onTap: () async {
                    await UserPreferences.removeLastPlaylist();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const PlaylistScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SectionTitleWidget(title: "Sync & Account"),
              Card(
                child: StreamBuilder<User?>(
                  stream: getIt<AuthService>().authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final isLoggedIn = user != null;

                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            isLoggedIn ? Icons.cloud_done : Icons.cloud_off,
                            color: isLoggedIn ? Colors.green : Colors.grey,
                          ),
                          title: Text(isLoggedIn
                              ? 'Signed in as ${user.email}'
                              : 'Sync favorites and history'),
                          subtitle: Text(isLoggedIn
                              ? 'Your data is being synced to the cloud'
                              : 'Sign in to sync your data across devices'),
                          trailing: isLoggedIn
                              ? IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () async {
                                    await getIt<AuthService>().signOut();
                                  },
                                  tooltip: 'Sign Out',
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    final success = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => const LoginDialog(),
                                    );

                                    if (success == true && context.mounted) {
                                      // Trigger sync
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Syncing data...')),
                                      );

                                      // Run sync in background
                                      Future.wait([
                                        context.read<FavoritesController>().syncWithCloud(),
                                        context.read<WatchHistoryController>().syncWithCloud(),
                                      ]).then((_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Sync complete')),
                                          );
                                        }
                                      });
                                    }
                                  },
                                  child: const Text('Sign In'),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SectionTitleWidget(title: context.loc.general_settings),
              Card(
                child: Column(
                  children: [
                    _buildFocusableListTile(
                      icon: Icons.refresh,
                      title: context.loc.refresh_contents,
                      trailing: const Icon(Icons.cloud_download),
                      onTap: () {
                        final playlist = AppState.currentPlaylist;
                        if (isXtreamCode && playlist != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => XtreamCodeDataLoaderScreen(
                                playlist: playlist,
                                refreshAll: true,
                              ),
                            ),
                          );
                        }

                        if (isM3u) {
                          refreshM3uPlaylist();
                        }
                      },
                    ),
                    if (isXtreamCode) const Divider(height: 1),
                    if (isXtreamCode)
                      _buildFocusableListTile(
                        icon: Icons.subtitles_outlined,
                        title: context.loc.hide_category,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategorySettingsScreen(
                                controller: _xtreamController,
                              ),
                            ),
                          );

                          if (result == true) {
                            if (!context.mounted) return;
                            final playlist = AppState.currentPlaylist;
                            if (isXtreamCode && playlist != null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => XtreamCodeDataLoaderScreen(
                                    playlist: playlist,
                                    refreshAll: true,
                                  ),
                                ),
                              );
                            }

                            if (isM3u) {
                              refreshM3uPlaylist();
                            }
                          }
                        },
                      ),
                    const Divider(height: 1),
                    DropdownTileWidget<Locale>(
                      icon: Icons.language,
                      label: context.loc.app_language,
                      value: Localizations.localeOf(context),
                      items: [
                        ...supportedLanguages.map(
                          (language) => DropdownMenuItem(
                            value: Locale(language['code']),
                            child: Text(language['name']),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        Provider.of<LocaleProvider>(
                          context,
                          listen: false,
                        ).setLocale(v!);
                      },
                    ),
                    const Divider(height: 1),
                    DropdownTileWidget<String>(
                      icon: Icons.color_lens_outlined,
                      label: context.loc.theme,
                      value: _selectedTheme,
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(context.loc.standard),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text(context.loc.light),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text(context.loc.dark),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          final themeMode = _stringToThemeMode(value);
                          await themeProvider.setTheme(themeMode);
                          setState(() {
                            _selectedTheme = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionTitleWidget(title: context.loc.player_settings),
              Card(
                child: Column(
                  children: [
                    _buildFocusableSwitchTile(
                      icon: Icons.play_circle_outline,
                      title: context.loc.continue_on_background,
                      subtitle: context.loc.continue_on_background_description,
                      value: _backgroundPlayEnabled,
                      onChanged: _saveBackgroundPlaySetting,
                    ),
                    const Divider(height: 1),
                    _buildFocusableListTile(
                      icon: Icons.subtitles_outlined,
                      title: context.loc.subtitle_settings,
                      subtitle: context.loc.subtitle_settings_description,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubtitleSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    // Player gesture settings - Only show on mobile platforms (Android & iOS)
                    if (Theme.of(context).platform == TargetPlatform.android ||
                        Theme.of(context).platform == TargetPlatform.iOS) ...[
                      const Divider(height: 1),
                      _buildFocusableSwitchTile(
                        icon: Icons.brightness_6,
                        title: context.loc.brightness_gesture,
                        subtitle: context.loc.brightness_gesture_description,
                        value: _brightnessGesture,
                        onChanged: (value) async {
                          await UserPreferences.setBrightnessGesture(value);
                          setState(() {
                            _brightnessGesture = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildFocusableSwitchTile(
                        icon: Icons.volume_up,
                        title: context.loc.volume_gesture,
                        subtitle: context.loc.volume_gesture_description,
                        value: _volumeGesture,
                        onChanged: (value) async {
                          await UserPreferences.setVolumeGesture(value);
                          setState(() {
                            _volumeGesture = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildFocusableSwitchTile(
                        icon: Icons.swipe,
                        title: context.loc.seek_gesture,
                        subtitle: context.loc.seek_gesture_description,
                        value: _seekGesture,
                        onChanged: (value) async {
                          await UserPreferences.setSeekGesture(value);
                          setState(() {
                            _seekGesture = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildFocusableSwitchTile(
                        icon: Icons.fast_forward,
                        title: context.loc.speed_up_on_long_press,
                        subtitle: context.loc.speed_up_on_long_press_description,
                        value: _speedUpOnLongPress,
                        onChanged: (value) async {
                          await UserPreferences.setSpeedUpOnLongPress(value);
                          setState(() {
                            _speedUpOnLongPress = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildFocusableSwitchTile(
                        icon: Icons.touch_app,
                        title: context.loc.seek_on_double_tap,
                        subtitle: context.loc.seek_on_double_tap_description,
                        value: _seekOnDoubleTap,
                        onChanged: (value) async {
                          await UserPreferences.setSeekOnDoubleTap(value);
                          setState(() {
                            _seekOnDoubleTap = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionTitleWidget(title: context.loc.about),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(context.loc.app_version),
                      subtitle: Text(_appVersion.isNotEmpty ? _appVersion : 'Loading...'),
                      dense: true,
                    ),
                    const Divider(height: 1),
                    _buildFocusableListTile(
                      icon: Icons.code,
                      title: context.loc.support_on_github,
                      subtitle: context.loc.support_on_github_description,
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () async {
                        final url = Uri.parse('https://github.com/lumio/lumio-player'); // TODO: Update URL when new repo is ready
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  refreshM3uPlaylist() async {
    final playlist = AppState.currentPlaylist;
    if (playlist == null) return;

    List<M3uItem> oldM3uItems = AppState.m3uItems ?? [];
    List<M3uItem> newM3uItems = [];

    final url = playlist.url;
    if (url != null && url.startsWith('http')) {
      showLoadingDialog(context, context.loc.loading_m3u);
      final params = {
        'id': playlist.id,
        'url': url,
      };
      newM3uItems = await compute(M3uParser.parseM3uUrl, params);
    } else {
      await _pickFile();
      if (!mounted) return;
      if (_selectedFilePath == null) return;

      showLoadingDialog(context, context.loc.loading_m3u);
      final params = {
        'id': playlist.id,
        'filePath': _selectedFilePath!,
      };
      newM3uItems = await compute(M3uParser.parseM3uFile, params);
    }

    newM3uItems = updateM3UItemIdsByPosition(
      oldItems: oldM3uItems,
      newItems: newM3uItems,
    );

    await database.deleteAllM3uItems(playlist.id);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => M3uDataLoaderScreen(
          playlist: playlist,
          m3uItems: newM3uItems,
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    _selectedFilePath = null;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.file_selection_error)),
      );
    }
  }

  List<M3uItem> updateM3UItemIdsByPosition({
    required List<M3uItem> oldItems,
    required List<M3uItem> newItems,
  }) {
    Map<String, List<MapEntry<int, String>>> groupedOldItems = {};
    for (int i = 0; i < oldItems.length; i++) {
      M3uItem item = oldItems[i];
      String key = "${item.url}|||${item.name}";
      groupedOldItems.putIfAbsent(key, () => []);
      groupedOldItems[key]!.add(MapEntry(i, item.id));
    }

    Map<String, int> groupUsageCounter = {};
    List<M3uItem> updatedItems = [];

    for (int i = 0; i < newItems.length; i++) {
      M3uItem newItem = newItems[i];
      String key = "${newItem.url}|||${newItem.name}";

      if (groupedOldItems.containsKey(key)) {
        List<MapEntry<int, String>> oldGroup = groupedOldItems[key]!;
        int usageCount = groupUsageCounter[key] ?? 0;

        if (usageCount < oldGroup.length) {
          String oldId = oldGroup[usageCount].value;
          updatedItems.add(newItem.copyWith(id: oldId));
          groupUsageCounter[key] = usageCount + 1;
        } else {
          updatedItems.add(newItem);
        }
      } else {
        updatedItems.add(newItem);
      }
    }

    return updatedItems;
  }
}
