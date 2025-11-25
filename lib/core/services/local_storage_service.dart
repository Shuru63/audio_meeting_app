import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  static const String _keyUser = 'user';
  static const String _keyToken = 'token';
  static const String _keyDeviceId = 'device_id';
  static const String _keyIsFirstTime = 'is_first_time';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  static Future<void> init() async {
    _instance ??= LocalStorageService._();
    _preferences ??= await SharedPreferences.getInstance();
  }

  // User Methods
  Future<bool> saveUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      return await _preferences!.setString(_keyUser, userJson);
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final userJson = _preferences!.getString(_keyUser);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> clearUser() async {
    return await _preferences!.remove(_keyUser);
  }

  // Token Methods
  Future<bool> saveToken(String token) async {
    return await _preferences!.setString(_keyToken, token);
  }

  String? getToken() {
    return _preferences!.getString(_keyToken);
  }

  Future<bool> clearToken() async {
    return await _preferences!.remove(_keyToken);
  }

  // Device ID Methods
  Future<bool> saveDeviceId(String deviceId) async {
    return await _preferences!.setString(_keyDeviceId, deviceId);
  }

  String? getDeviceId() {
    return _preferences!.getString(_keyDeviceId);
  }

  // First Time Methods
  Future<bool> setFirstTime(bool isFirstTime) async {
    return await _preferences!.setBool(_keyIsFirstTime, isFirstTime);
  }

  bool isFirstTime() {
    return _preferences!.getBool(_keyIsFirstTime) ?? true;
  }

  // Theme Methods
  Future<bool> saveThemeMode(String themeMode) async {
    return await _preferences!.setString(_keyThemeMode, themeMode);
  }

  String getThemeMode() {
    return _preferences!.getString(_keyThemeMode) ?? 'light';
  }

  // Language Methods
  Future<bool> saveLanguage(String language) async {
    return await _preferences!.setString(_keyLanguage, language);
  }

  String getLanguage() {
    return _preferences!.getString(_keyLanguage) ?? 'en';
  }

  // Clear All Data
  Future<bool> clearAll() async {
    return await _preferences!.clear();
  }

  // Generic Methods
  Future<bool> setString(String key, String value) async {
    return await _preferences!.setString(key, value);
  }

  String? getString(String key) {
    return _preferences!.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _preferences!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _preferences!.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _preferences!.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    return await _preferences!.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _preferences!.getDouble(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences!.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _preferences!.getStringList(key);
  }

  Future<bool> remove(String key) async {
    return await _preferences!.remove(key);
  }

  bool containsKey(String key) {
    return _preferences!.containsKey(key);
  }
}