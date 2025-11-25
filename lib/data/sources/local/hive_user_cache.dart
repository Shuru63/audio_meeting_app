import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../../../core/error/exceptions.dart';
import '../../models/user_model.dart';

class HiveUserCache {
  static const String _boxName = 'userCache';
  static const String _currentUserKey = 'currentUser';
  static const String _usersKey = 'users';
  
  Box? _box;
  final Logger _logger = Logger();

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      _logger.i('Hive user cache initialized');
    } catch (e) {
      _logger.e('Failed to initialize Hive: $e');
      throw CacheException(message: 'Failed to initialize cache');
    }
  }

  Future<void> cacheCurrentUser(UserModel user) async {
    try {
      await _ensureBoxOpen();
      await _box!.put(_currentUserKey, user.toJson());
      _logger.i('Cached current user: ${user.id}');
    } catch (e) {
      _logger.e('Failed to cache user: $e');
      throw CacheException(message: 'Failed to cache user');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      await _ensureBoxOpen();
      final userData = _box!.get(_currentUserKey);
      
      if (userData == null) return null;
      
      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    } catch (e) {
      _logger.e('Failed to get cached user: $e');
      return null;
    }
  }

  Future<void> clearCurrentUser() async {
    try {
      await _ensureBoxOpen();
      await _box!.delete(_currentUserKey);
      _logger.i('Cleared current user cache');
    } catch (e) {
      _logger.e('Failed to clear user cache: $e');
      throw CacheException(message: 'Failed to clear cache');
    }
  }

  Future<void> cacheUsers(List<UserModel> users) async {
    try {
      await _ensureBoxOpen();
      final usersData = users.map((user) => user.toJson()).toList();
      await _box!.put(_usersKey, usersData);
      _logger.i('Cached ${users.length} users');
    } catch (e) {
      _logger.e('Failed to cache users: $e');
      throw CacheException(message: 'Failed to cache users');
    }
  }

  Future<List<UserModel>> getCachedUsers() async {
    try {
      await _ensureBoxOpen();
      final usersData = _box!.get(_usersKey);
      
      if (usersData == null) return [];
      
      final usersList = List<Map<String, dynamic>>.from(usersData);
      return usersList.map((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      _logger.e('Failed to get cached users: $e');
      return [];
    }
  }

  Future<void> cacheUser(UserModel user) async {
    try {
      await _ensureBoxOpen();
      await _box!.put('user_${user.id}', user.toJson());
      _logger.i('Cached user: ${user.id}');
    } catch (e) {
      _logger.e('Failed to cache user: $e');
      throw CacheException(message: 'Failed to cache user');
    }
  }

  Future<UserModel?> getCachedUser(String userId) async {
    try {
      await _ensureBoxOpen();
      final userData = _box!.get('user_$userId');
      
      if (userData == null) return null;
      
      return UserModel.fromJson(Map<String, dynamic>.from(userData));
    } catch (e) {
      _logger.e('Failed to get cached user: $e');
      return null;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _ensureBoxOpen();
      await _box!.delete('user_$userId');
      _logger.i('Deleted cached user: $userId');
    } catch (e) {
      _logger.e('Failed to delete cached user: $e');
      throw CacheException(message: 'Failed to delete user');
    }
  }

  Future<void> clearAll() async {
    try {
      await _ensureBoxOpen();
      await _box!.clear();
      _logger.i('Cleared all user cache');
    } catch (e) {
      _logger.e('Failed to clear cache: $e');
      throw CacheException(message: 'Failed to clear cache');
    }
  }

  Future<bool> hasCurrentUser() async {
    try {
      await _ensureBoxOpen();
      return _box!.containsKey(_currentUserKey);
    } catch (e) {
      _logger.e('Failed to check user cache: $e');
      return false;
    }
  }

  Future<void> updateUserField({
    required String userId,
    required String field,
    required dynamic value,
  }) async {
    try {
      await _ensureBoxOpen();
      final user = await getCachedUser(userId);
      
      if (user == null) {
        throw CacheException(message: 'User not found in cache');
      }

      final userData = user.toJson();
      userData[field] = value;
      
      await _box!.put('user_$userId', userData);
      _logger.i('Updated user field: $field for user: $userId');
    } catch (e) {
      _logger.e('Failed to update user field: $e');
      throw CacheException(message: 'Failed to update user field');
    }
  }

  Future<void> _ensureBoxOpen() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }

  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _logger.i('Closed user cache box');
    }
  }

  // Statistics
  Future<int> getCacheSize() async {
    try {
      await _ensureBoxOpen();
      return _box!.length;
    } catch (e) {
      _logger.e('Failed to get cache size: $e');
      return 0;
    }
  }

  Future<List<String>> getAllCachedUserIds() async {
    try {
      await _ensureBoxOpen();
      final keys = _box!.keys.toList();
      return keys
          .where((key) => key.toString().startsWith('user_'))
          .map((key) => key.toString().replaceFirst('user_', ''))
          .toList();
    } catch (e) {
      _logger.e('Failed to get cached user IDs: $e');
      return [];
    }
  }
}