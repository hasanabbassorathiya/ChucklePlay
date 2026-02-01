import 'package:flutter/material.dart';
import '../models/category_type.dart';
import '../models/category_view_model.dart';
import '../models/playlist_content_model.dart';
import '../models/content_type.dart';
import '../repositories/m3u_repository.dart';
import '../services/app_state.dart';
import '../services/watch_history_service.dart';

class StbDashboardController extends ChangeNotifier {
  final M3uRepository _repository = AppState.m3uRepository ?? M3uRepository();
  final WatchHistoryService _watchHistoryService = WatchHistoryService();
  bool _isLoading = true;
  String? _errorMessage;

  final List<CategoryViewModel> _liveCategories = [];
  final List<CategoryViewModel> _movieCategories = [];
  final List<CategoryViewModel> _seriesCategories = [];
  final List<ContentItem> _recentlyWatched = [];
  ContentItem? _featuredContent;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CategoryViewModel> get liveCategories => _liveCategories;
  List<CategoryViewModel> get movieCategories => _movieCategories;
  List<CategoryViewModel> get seriesCategories => _seriesCategories;
  List<ContentItem> get recentlyWatched => _recentlyWatched;
  ContentItem? get featuredContent => _featuredContent;

  StbDashboardController() {
    // We don't call _init() here anymore to avoid notifyListeners() during build.
    // The view should call init() in addPostFrameCallback or we can handle it lazily.
  }

  Future<void> init() async {
    if (!_isLoading && _liveCategories.isNotEmpty) return; // Already initialized
    await _init();
  }

  Future<void> _init() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Ensure repository is available
      AppState.m3uRepository ??= _repository;

      // Load Recently Watched
      final currentPlaylist = AppState.currentPlaylist;
      if (currentPlaylist != null) {
        final history = await _watchHistoryService.getRecentlyWatched(currentPlaylist.id, limit: 10);
        _recentlyWatched.clear();
        _recentlyWatched.addAll(history.map((h) => ContentItem(
              h.streamId,
              h.title,
              h.imagePath ?? '',
              h.contentType,
            )));
      }

      // Load Categories and a few items for each
      final categories = await _repository.getCategories();
      if (categories != null) {
        for (var category in categories) {
          final m3uItems = await _repository.getM3uItemsByCategoryId(
            categoryId: category.categoryId,
            top: 20,
          );

          final viewModel = CategoryViewModel(
            category: category,
            contentItems:
                m3uItems
                    ?.map(
                      (x) => ContentItem(
                        x.url,
                        x.name ?? '',
                        x.tvgLogo ?? '',
                        x.contentType,
                        m3uItem: x,
                      ),
                    )
                    .toList() ??
                [],
          );

          switch (category.type) {
            case CategoryType.live:
              _liveCategories.add(viewModel);
              break;
            case CategoryType.vod:
              _movieCategories.add(viewModel);
              break;
            case CategoryType.series:
              _seriesCategories.add(viewModel);
              break;
          }
        }
      }

      // Pick a featured item randomly from movies or live streams
      final List<ContentItem> potentialFeatured = [];
      if (_movieCategories.isNotEmpty) {
        for (var cat in _movieCategories) {
          potentialFeatured.addAll(cat.contentItems);
        }
      }

      if (potentialFeatured.isEmpty && _liveCategories.isNotEmpty) {
        for (var cat in _liveCategories) {
          potentialFeatured.addAll(cat.contentItems);
        }
      }

      if (potentialFeatured.isNotEmpty) {
        potentialFeatured.shuffle();
        _featuredContent = potentialFeatured.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _init();
}
