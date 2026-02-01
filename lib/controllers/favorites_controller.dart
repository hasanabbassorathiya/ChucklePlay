import 'package:lumio/services/firestore_service.dart';
import 'package:lumio/services/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:lumio/models/content_type.dart';
import 'package:lumio/models/favorite.dart';
import 'package:lumio/models/playlist_content_model.dart';
import 'package:lumio/repositories/favorites_repository.dart';

class FavoritesController extends ChangeNotifier {
  final FavoritesRepository _repository = FavoritesRepository();
  final FirestoreService _firestoreService = getIt<FirestoreService>();

  List<Favorite> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Favorite> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Favorite> get liveStreamFavorites =>
      _favorites.where((f) => f.contentType == ContentType.liveStream).toList();

  List<Favorite> get movieFavorites =>
      _favorites.where((f) => f.contentType == ContentType.vod).toList();

  List<Favorite> get seriesFavorites =>
      _favorites.where((f) => f.contentType == ContentType.series).toList();

  int get totalFavoriteCount => _favorites.length;
  int get liveStreamFavoriteCount => liveStreamFavorites.length;
  int get movieFavoriteCount => movieFavorites.length;
  int get seriesFavoriteCount => seriesFavorites.length;

  Future<void> loadFavorites() async {
    print('FavoritesController: loadFavorites başladı');
    try {
      _setLoading(true);
      _setError(null);

      _favorites.clear();
      notifyListeners();

      _favorites = await _repository.getAllFavorites();
      print('FavoritesController: ${_favorites.length} favori yüklendi');
      notifyListeners();
    } catch (e) {
      print('FavoritesController: Hata: $e');
      _setError('Favoriler yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncWithCloud() async {
    try {
      final cloudFavorites = await _firestoreService.getFavorites();

      for (var fav in cloudFavorites) {
        // Check if exists locally
        final exists = await _repository.isFavorite(
          fav.streamId,
          fav.contentType,
          episodeId: fav.episodeId
        );

        if (!exists) {
          await _repository.insertFavorite(fav);
          // debugPrint('Synced favorite from cloud: ${fav.name}');
        }
      }

      // Reload favorites to show new items
      await loadFavorites();
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<bool> addFavorite(ContentItem contentItem) async {
    try {
      _setError(null);

      await _repository.addFavorite(contentItem);
      await loadFavorites();

      // Sync to cloud
      final addedFavorite = _favorites.firstWhere(
          (f) => f.streamId == contentItem.id && f.contentType == contentItem.contentType,
          orElse: () => throw Exception('Favorite not found after adding'));
      await _firestoreService.syncFavorite(addedFavorite);

      return true;
    } catch (e) {
      _setError('Favori eklenirken hata oluştu: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(String streamId, ContentType contentType, {String? episodeId}) async {
    try {
      _setError(null);

      // Find favorite to get its ID for cloud deletion
      final favoriteToDelete = _favorites.firstWhere(
        (f) => f.streamId == streamId && f.contentType == contentType && f.episodeId == episodeId,
        orElse: () => throw Exception('Favorite not found'),
      );

      await _repository.removeFavorite(streamId, contentType, episodeId: episodeId);
      await loadFavorites();

      // Sync removal
      await _firestoreService.deleteFavorite(favoriteToDelete.id);

      return true;
    } catch (e) {
      _setError('Favori kaldırılırken hata oluştu: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(ContentItem contentItem) async {
    try {
      _setError(null);
      
      final result = await _repository.toggleFavorite(contentItem);
      await loadFavorites();
      
      return result;
    } catch (e) {
      _setError('Favori işlemi sırasında hata oluştu: $e');
      return false;
    }
  }

  Future<bool> isFavorite(String streamId, ContentType contentType, {String? episodeId}) async {
    try {
      return await _repository.isFavorite(streamId, contentType, episodeId: episodeId);
    } catch (e) {
      _setError('Favori kontrolü sırasında hata oluştu: $e');
      return false;
    }
  }

  Future<List<Favorite>> getFavoritesByContentType(ContentType contentType) async {
    try {
      return await _repository.getFavoritesByContentType(contentType);
    } catch (e) {
      _setError('Favoriler getirilirken hata oluştu: $e');
      return [];
    }
  }

  Future<int> getFavoriteCount() async {
    try {
      return await _repository.getFavoriteCount();
    } catch (e) {
      _setError('Favori sayısı getirilirken hata oluştu: $e');
      return 0;
    }
  }

  Future<int> getFavoriteCountByContentType(ContentType contentType) async {
    try {
      return await _repository.getFavoriteCountByContentType(contentType);
    } catch (e) {
      _setError('Favori sayısı getirilirken hata oluştu: $e');
      return 0;
    }
  }

  Future<bool> updateFavorite(Favorite favorite) async {
    try {
      _setError(null);
      
      await _repository.updateFavorite(favorite);
      await loadFavorites();
      
      return true;
    } catch (e) {
      _setError('Favori güncellenirken hata oluştu: $e');
      return false;
    }
  }

  Future<bool> clearAllFavorites() async {
    try {
      _setError(null);
      
      await _repository.clearAllFavorites();
      _favorites.clear();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Favoriler temizlenirken hata oluştu: $e');
      return false;
    }
  }

  List<Favorite> searchFavorites(String query) {
    if (query.isEmpty) return _favorites;
    
    return _favorites.where((favorite) =>
        favorite.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<Favorite> filterFavoritesByContentType(ContentType contentType) {
    return _favorites.where((favorite) => favorite.contentType == contentType).toList();
  }

  void clearError() {
    _setError(null);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 