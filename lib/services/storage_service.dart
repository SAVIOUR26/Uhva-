import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _keyCredentials = 'uhva_credentials';
  static const _keyFavourites = 'uhva_favourites';
  static const _keyWatchHistory = 'uhva_history';

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
