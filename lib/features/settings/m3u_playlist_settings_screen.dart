import 'package:lumio/controllers/playlist_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:lumio/models/api_response.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/services/app_state.dart';
import 'package:lumio/l10n/localization_extension.dart';
import '../../core/widgets/playlist_info_widget.dart';
import 'general_settings_section.dart';

class M3uPlaylistSettingsScreen extends StatefulWidget {
  final Playlist playlist;

  const M3uPlaylistSettingsScreen({super.key, required this.playlist});

  @override
  State<M3uPlaylistSettingsScreen> createState() =>
      _N3uPlaylistSettingsScreenState();
}

class _N3uPlaylistSettingsScreenState extends State<M3uPlaylistSettingsScreen> {
  void _showEditDialog(BuildContext context) {
    final playlist = widget.playlist;
    final nameController = TextEditingController(text: playlist.name);
    final urlController = TextEditingController(text: playlist.url);
    final epgUrlController = TextEditingController(text: playlist.epgUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Playlist Adı'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'M3U URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: epgUrlController,
                decoration: const InputDecoration(labelText: 'EPG URL (Opsiyonel)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedPlaylist = Playlist(
                id: playlist.id,
                name: nameController.text.trim(),
                type: playlist.type,
                url: urlController.text.trim(),
                username: playlist.username,
                password: playlist.password,
                epgUrl: epgUrlController.text.trim(),
                createdAt: playlist.createdAt,
              );

              final controller = context.read<PlaylistController>();
              final success = await controller.updatePlaylist(updatedPlaylist);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Force UI refresh if needed, though widget.playlist might be stale
                // Usually we'd want to pop or use a callback
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  ApiResponse? _serverInfo;

  @override
  void initState() {
    super.initState();
    _loadServerInfo();
  }

  Future<void> _loadServerInfo() async {
    final xtreamRepo = AppState.xtreamCodeRepository;
    if (xtreamRepo != null) {
      final info = await xtreamRepo.getPlayerInfo();
      if (mounted) {
        setState(() {
          _serverInfo = info;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SelectableText(
          context.loc.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditDialog(context),
            tooltip: 'Edit Playlist',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        children: [
          const GeneralSettingsWidget(),
          const SizedBox(height: 16),
          PlaylistInfoWidget(playlist: widget.playlist),
        ],
      ),
    );
  }
}
