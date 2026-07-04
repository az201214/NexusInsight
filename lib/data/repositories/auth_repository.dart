import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../database/app_database.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
      };

  factory SessionUser.fromMap(Map<String, dynamic> map) => SessionUser(
        id: map['id'] as String,
        email: map['email'] as String,
        name: map['name'] as String,
      );
}

class AuthRepository {
  AuthRepository(this._db);
  final AppDatabase _db;
  final _storage = const FlutterSecureStorage();

  fb.FirebaseAuth? get _fbAuth {
    try {
      Firebase.app();
      return fb.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<SessionUser?> getCurrentUser() async {
    final fbUser = _fbAuth?.currentUser;
    if (fbUser != null) {
      return SessionUser(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        name: fbUser.displayName ?? '',
      );
    }
    
    // Fallback to secure storage
    final sessionData = await _storage.read(key: 'user_session');
    if (sessionData != null) {
      try {
        final map = jsonDecode(sessionData) as Map<String, dynamic>;
        return SessionUser.fromMap(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<SessionUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final fbInstance = _fbAuth;
    if (fbInstance != null) {
      final credential = await fbInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        return SessionUser(
          id: credential.user!.uid,
          email: email,
          name: name,
        );
      }
    }

    // Local fallback sign up
    final userId = UniqueKey().toString();
    final user = SessionUser(id: userId, email: email, name: name);
    final hashedPassword = _hashPassword(password);

    await _storage.write(key: 'user_profile_$email', value: jsonEncode(user.toMap()));
    await _storage.write(key: 'user_pwd_$email', value: hashedPassword);
    await _storage.write(key: 'user_session', value: jsonEncode(user.toMap()));
    return user;
  }

  Future<SessionUser> signIn({
    required String email,
    required String password,
  }) async {
    final fbInstance = _fbAuth;
    if (fbInstance != null) {
      final credential = await fbInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return SessionUser(
          id: credential.user!.uid,
          email: email,
          name: credential.user!.displayName ?? '',
        );
      }
    }

    // Local fallback sign in
    final storedHash = await _storage.read(key: 'user_pwd_$email');
    if (storedHash == null) {
      throw Exception('User not found');
    }
    
    final inputHash = _hashPassword(password);
    if (storedHash != inputHash) {
      throw Exception('Incorrect password');
    }
    
    final profileData = await _storage.read(key: 'user_profile_$email');
    if (profileData == null) {
      throw Exception('User profile not found');
    }
    
    final user = SessionUser.fromMap(jsonDecode(profileData) as Map<String, dynamic>);
    await _storage.write(key: 'user_session', value: jsonEncode(user.toMap()));
    return user;
  }

  Future<void> signOut() async {
    await _fbAuth?.signOut();
    await _storage.delete(key: 'user_session');
  }
}
