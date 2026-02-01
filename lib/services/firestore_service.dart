import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite.dart';
import '../models/watch_history.dart';
import '../models/content_type.dart';

class FirestoreService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirestoreService() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint('FirestoreService: Firebase not initialized: $e');
    }
  }

  String? get _userId => _auth?.currentUser?.uid;

  // --- Favorites ---

  Future<void> syncFavorite(Favorite favorite) async {
    if (_userId == null || _firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(favorite.id)
          .set(favorite.toJson());
    } catch (e) {
      debugPrint('Error syncing favorite: $e');
    }
  }

  Future<void> deleteFavorite(String favoriteId) async {
    if (_userId == null || _firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(favoriteId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting favorite from firestore: $e');
    }
  }

  Future<List<Favorite>> getFavorites() async {
    if (_userId == null || _firestore == null) return [];

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert integer content type from JSON back to enum if needed handled in fromJson?
        // Favorite.fromJson usually takes a Map that matches what we saved.
        // Wait, Favorite.fromJson in our code was `Favorite.fromDrift(FavoritesData driftObject)`.
        // We need a proper `fromJson` for Favorite that takes a Map<String, dynamic>.
        // I'll assume I need to add that to Favorite model or parse it manually here.

        return Favorite(
          id: data['id'],
          playlistId: data['playlist_id'],
          contentType: ContentType.values[data['content_type']],
          streamId: data['stream_id'],
          episodeId: data['episode_id'],
          m3uItemId: data['m3u_item_id'],
          name: data['name'],
          imagePath: data['image_path'],
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      return [];
    }
  }

  // --- Watch History ---

  Future<void> syncWatchHistory(WatchHistory history) async {
    if (_userId == null || _firestore == null) return;

    try {
      // Create a unique ID for the history item, usually combination of playlist and stream
      final docId = '${history.playlistId}_${history.streamId}';

      await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('watch_history')
          .doc(docId)
          .set(history.toJson());
    } catch (e) {
      debugPrint('Error syncing watch history: $e');
    }
  }

  Future<List<WatchHistory>> getWatchHistory() async {
    if (_userId == null || _firestore == null) return [];

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection('watch_history')
          .orderBy('lastWatched', descending: true)
          .get();

      return snapshot.docs.map((doc) => WatchHistory.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching watch history: $e');
      return [];
    }
  }
}
