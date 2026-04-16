import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _keyCredentials = 'uhva_credentials';
  static const _keyFavourites = 'uhva_favourites';
  static const _keyWatchHistory = 'uhva_history';
  static const _keyPin = 'uhva_pin';
  static const _keyLockedCategories = 'uhva_locked_cats';
  static const int _pinSalt = 0x2A; // XOR obfuscation salt

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Credentials ─────────────────────────────────────────────────────────
  Future<void> saveCredentials(String serverUrl, String username, String password) async {
    await _prefs?.setString(_keyCredentials, jsonEncode({
      'server': serverUrl,
      'username': username,
      'password': password,
    }));
  }

  Map<String, String>? loadCredentials() {
    final raw = _prefs?.getString(_keyCredentials);
    if (raw == null) return null;
    final data = jsonDecode(raw);
    return {
      'server': data['server'] ?? '',
      'username': data['username'] ?? '',
      'password': data['password'] ?? '',
    };
  }

  Future<void> clearCredentials() async {
    await _prefs?.remove(_keyCredentials);
  }

  // ─── Favourites ──────────────────────────────────────────────────────────
  List<int> getFavouriteIds() {
    final raw = _prefs?.getString(_keyFavourites);
    if (raw == null) return [];
    return List<int>.from(jsonDecode(raw));
  }

  Future<void> toggleFavourite(int streamId) async {
    final ids = getFavouriteIds();
    if (ids.contains(streamId)) {
      ids.remove(streamId);
    } else {
      ids.add(streamId);
    }
    await _prefs?.setString(_keyFavourites, jsonEncode(ids));
  }

  bool isFavourite(int streamId) => getFavouriteIds().contains(streamId);

  // ─── Parental PIN ─────────────────────────────────────────────────────────
  Future<void> setPin(String pin) async {
    final obfuscated =
        pin.codeUnits.map((c) => c ^ _pinSalt).join(',');
    await _prefs?.setString(_keyPin, obfuscated);
  }

  String? getPin() {
    final raw = _prefs?.getString(_keyPin);
    if (raw == null || raw.isEmpty) return null;
    try {
      final digits = raw
          .split(',')
          .map((s) => String.fromCharCode(int.parse(s) ^ _pinSalt))
          .join();
      return digits;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPin() async => _prefs?.remove(_keyPin);

  Future<void> setLockedCategories(Set<String> ids) async =>
      _prefs?.setString(_keyLockedCategories, jsonEncode(ids.toList()));

  Set<String> getLockedCategories() {
    final raw = _prefs?.getString(_keyLockedCategories);
    if (raw == null) return {};
    return Set<String>.from(jsonDecode(raw));
  }

  // ─── Watch history ────────────────────────────────────────────────────────
  Future<void> addToHistory(LiveChannel channel) async {
    final history = getWatchHistory();
    history.removeWhere((c) => c['stream_id'] == channel.streamId);
    history.insert(0, channel.toJson());
    if (history.length > 20) history.removeLast();
    await _prefs?.setString(_keyWatchHistory, jsonEncode(history));
  }

  List<Map<String, dynamic>> getWatchHistory() {
    final raw = _prefs?.getString(_keyWatchHistory);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }
}
