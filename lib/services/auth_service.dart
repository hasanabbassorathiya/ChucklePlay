import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseAuth? _auth;

  AuthService() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint('AuthService: Firebase not initialized: $e');
    }
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  User? get currentUser => _auth?.currentUser;

  Future<User?> signInAnonymously() async {
    if (_auth == null) return null;
    try {
      final userCredential = await _auth!.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    if (_auth == null) return null;
    try {
      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    if (_auth == null) return null;
    try {
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (_auth == null) return;
    try {
      await _auth!.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
