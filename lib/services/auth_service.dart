import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class User {
  final int? id;
  final String username;
  final String displayName;
  final String avatarEmoji;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.displayName,
    required this.avatarEmoji,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      displayName: map['display_name'] as String,
      avatarEmoji: map['avatar_emoji'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_emoji': avatarEmoji,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

abstract class AuthService {
  Future<User?> checkActiveSession();
  Future<User> login(String username, String password);
  Future<User> register(
    String username,
    String displayName,
    String password,
    String avatarEmoji,
  );
  Future<void> logout();
}

class LocalAuthService implements AuthService {
  static const String _prefSessionKey = 'logged_in_username';

  const LocalAuthService();

  // FNV-1a 64-bit non-cryptographic hash for local-only password storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    int hash = 0xcbf29ce484222325;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16);
  }

  @override
  Future<User?> checkActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_prefSessionKey);
      if (username == null || username.isEmpty) return null;

      final dbUser = await DatabaseHelper.instance.getUser(username);
      if (dbUser == null) {
        // Stale session, clean it up
        await prefs.remove(_prefSessionKey);
        return null;
      }
      return User.fromMap(dbUser);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> login(String username, String password) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty || password.trim().isEmpty) {
      throw Exception('Username and password cannot be empty');
    }

    final dbUser = await DatabaseHelper.instance.getUser(cleanUsername);
    if (dbUser == null) {
      throw Exception('User not found');
    }

    final inputHash = _hashPassword(password);
    final storedHash = dbUser['password_hash'] as String;

    if (inputHash != storedHash) {
      throw Exception('Incorrect password');
    }

    final user = User.fromMap(dbUser);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSessionKey, user.username);
    return user;
  }

  @override
  Future<User> register(
    String username,
    String displayName,
    String password,
    String avatarEmoji,
  ) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanDisplayName = displayName.trim();

    if (cleanUsername.isEmpty || cleanDisplayName.isEmpty || password.trim().isEmpty) {
      throw Exception('All fields are required');
    }

    final existing = await DatabaseHelper.instance.getUser(cleanUsername);
    if (existing != null) {
      throw Exception('Username already exists');
    }

    final hash = _hashPassword(password);
    final now = DateTime.now();

    final userRow = {
      'username': cleanUsername,
      'password_hash': hash,
      'display_name': cleanDisplayName,
      'avatar_emoji': avatarEmoji.isEmpty ? '🏠' : avatarEmoji,
      'created_at': now.toIso8601String(),
    };

    final id = await DatabaseHelper.instance.insertUser(userRow);
    final user = User(
      id: id,
      username: cleanUsername,
      displayName: cleanDisplayName,
      avatarEmoji: avatarEmoji.isEmpty ? '🏠' : avatarEmoji,
      createdAt: now,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSessionKey, user.username);
    return user;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSessionKey);
  }
}
