import 'package:lumio/services/epg_service.dart';
import 'package:flutter/material.dart';
import 'package:lumio/repositories/user_preferences.dart';
import 'package:lumio/services/app_state.dart';
import 'package:lumio/models/playlist_model.dart';
import 'package:lumio/services/playlist_service.dart';
import 'package:collection/collection.dart';

class PlaylistController extends ChangeNotifier {
  List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  String? _error;
  final bool _hasInitialized = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasInitialized => _hasInitialized;

  Future<void> loadPlaylists(BuildContext context) async {
    _setLoading(true);
    clearError();

    try {
      _playlists = await PlaylistService.getPlaylists();

      // Try to restore last playlist
      final lastId = await UserPreferences.getLastPlaylist();
      if (lastId != null) {
        _currentPlaylist = _playlists.firstWhereOrNull((p) => p.id == lastId);
        if (_currentPlaylist != null) {
          AppState.currentPlaylist = _currentPlaylist;
        }
      }

      _sortPlaylists();
    } catch (e) {
      setError('Failed to load playlists: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void selectPlaylist(Playlist playlist) {
    _currentPlaylist = playlist;
    AppState.currentPlaylist = playlist;
    UserPreferences.setLastPlaylist(playlist.id);
    notifyListeners();
  }

  Future<Playlist?> createPlaylist({
    required String name,
    required PlaylistType type,
    String? url,
    String? username,
    String? password,
    String? epgUrl,
  }) async {
    if (!_validateInput(name, type, url, username, password)) {
      return null;
    }

    _setLoading(true);
    clearError();

    try {
      final playlist = Playlist(
        id: _generateUniqueId(),
        name: name.trim(),
        type: type,
        url: url?.trim(),
        username: username?.trim(),
        password: password?.trim(),
        epgUrl: epgUrl?.trim(),
        createdAt: DateTime.now(),
      );

      await PlaylistService.savePlaylist(playlist);
      _playlists.add(playlist);
      _sortPlaylists();

      // Trigger EPG update if URL is provided
      if (epgUrl != null && epgUrl.isNotEmpty) {
        refreshEpg(playlist.id, epgUrl);
      }

      return playlist;
    } catch (e) {
      setError('Failed to save playlist: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshEpg(String playlistId, String epgUrl) async {
    try {
      await EpgService.updateEpg(playlistId, epgUrl);
      notifyListeners();
    } catch (e) {
      debugPrint('EPG update failed: $e');
    }
  }

  Future<bool> deletePlaylist(String id) async {
    try {
      await PlaylistService.deletePlaylist(id);
      _playlists.removeWhere((playlist) => playlist.id == id);
      if (_currentPlaylist?.id == id) {
        _currentPlaylist = null;
        AppState.currentPlaylist = null;
        UserPreferences.removeLastPlaylist();
      }
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to delete playlist: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updatePlaylist(Playlist updatedPlaylist) async {
    _setLoading(true);
    clearError();

    try {
      if (_isDuplicateName(updatedPlaylist)) {
        setError('A playlist with this name already exists');
        return false;
      }

      await PlaylistService.updatePlaylist(updatedPlaylist);

      final index = _playlists.indexWhere((p) => p.id == updatedPlaylist.id);
      if (index != -1) {
        _playlists[index] = updatedPlaylist;
        if (_currentPlaylist?.id == updatedPlaylist.id) {
          _currentPlaylist = updatedPlaylist;
          AppState.currentPlaylist = updatedPlaylist;
        }
        _sortPlaylists();
      }

      return true;
    } catch (e) {
      setError('Failed to update playlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool _validateInput(
    String name,
    PlaylistType type,
    String? url,
    String? username,
    String? password,
  ) {
    if (name.trim().isEmpty || name.trim().length < 2) {
      setError('Playlist name must be at least 2 characters');
      return false;
    }

    if (_playlists.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      setError('A playlist with this name already exists');
      return false;
    }

    if (type == PlaylistType.xtream) {
      if (url?.trim().isEmpty ?? true) {
        setError('URL is required');
        return false;
      }
      if (username?.trim().isEmpty ?? true) {
        setError('Username is required');
        return false;
      }
      if (password?.trim().isEmpty ?? true) {
        setError('Password is required');
        return false;
      }

      final uri = Uri.tryParse(url!.trim());
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        setError('Please enter a valid URL');
        return false;
      }
    }

    return true;
  }

  bool _isDuplicateName(Playlist playlist) {
    return _playlists.any(
      (p) =>
          p.id != playlist.id &&
          p.name.toLowerCase() == playlist.name.toLowerCase(),
    );
  }

  void _sortPlaylists() {
    _playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  String _generateUniqueId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_playlists.length}';
  }
}
