import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/xtream_service.dart';
import '../services/storage_service.dart';
import '../services/radio_player_service.dart';

enum AppState { idle, loading, loaded, error }

class AppProvider extends ChangeNotifier {
  final _xtream = XtreamService();
  final _storage = StorageService();
  final _radioCtrl = RadioPlayerService();

  AppState _state = AppState.idle;
  AppState get state => _state;

  String _error = '';
  String get error => _error;

  XtreamUser? _user;
  XtreamUser? get user => _user;

  bool get isAuthenticated => _user != null;

  // ─── Live channels ────────────────────────────────────────────────────────
  List<LiveChannel> _allChannels = [];
  List<LiveChannel> get allChannels => _allChannels;

  List<StreamCategory> _liveCategories = [];
  List<StreamCategory> get liveCategories => _liveCategories;

  String _selectedCategoryId = '';
  String get selectedCategoryId => _selectedCategoryId;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<LiveChannel> get filteredChannels {
    var list = _allChannels;
    if (_selectedCategoryId.isNotEmpty) {
      list = list.where((c) => c.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  List<LiveChannel> get favouriteChannels =>
      _allChannels.where((c) => c.isFavourite).toList();

  List<LiveChannel> get recentChannels {
    final history = _storage.getWatchHistory();
    final ids = history.map((h) => h['stream_id'] as int).toList();
    final map = {for (var c in _allChannels) c.streamId: c};
    return ids.map((id) => map[id]).whereType<LiveChannel>().toList();
  }

  // ─── VOD ─────────────────────────────────────────────────────────────────
  List<VodStream> _vodStreams = [];
  List<VodStream> get vodStreams => _vodStreams;

  List<StreamCategory> _vodCategories = [];
  List<StreamCategory> get vodCategories => _vodCategories;

  // ─── Series ───────────────────────────────────────────────────────────────
  List<SeriesStream> _series = [];
  List<SeriesStream> get series => _series;

  List<StreamCategory> _seriesCategories = [];
  List<StreamCategory> get seriesCategories => _seriesCategories;

  // ─── Radio ────────────────────────────────────────────────────────────────
  List<LiveChannel> _radioStreams = [];
  List<LiveChannel> get radioStreams => _radioStreams;

  List<StreamCategory> _radioCategories = [];
  List<StreamCategory> get radioCategories => _radioCategories;

  String _selectedRadioCategoryId = '';
  String get selectedRadioCategoryId => _selectedRadioCategoryId;

  bool _radioLoading = false;
  bool get radioLoading => _radioLoading;

  LiveChannel? _nowPlayingRadio;
  LiveChannel? get nowPlayingRadio => _nowPlayingRadio;

  bool _radioIsPlaying = false;
  bool get radioIsPlaying => _radioIsPlaying;

  List<LiveChannel> get filteredRadioStreams {
    if (_selectedRadioCategoryId.isEmpty) return _radioStreams;
    return _radioStreams
        .where((r) => r.categoryId == _selectedRadioCategoryId)
        .toList();
  }

  // ─── Parental lock ────────────────────────────────────────────────────────
  bool get hasPin => _storage.getPin() != null;
  String? get pin => _storage.getPin();
  Set<String> get lockedCategories => _storage.getLockedCategories();

  Future<void> setPin(String pin) async {
    await _storage.setPin(pin);
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _storage.clearPin();
    await _storage.setLockedCategories({});
    notifyListeners();
  }

  Future<void> setLockedCategories(Set<String> ids) async {
    await _storage.setLockedCategories(ids);
    notifyListeners();
  }

  bool isCategoryLocked(String categoryId) {
    if (!hasPin) return false;
    return lockedCategories.contains(categoryId);
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _storage.init();
    final creds = _storage.loadCredentials();
    if (creds != null) {
      await login(creds['server']!, creds['username']!, creds['password']!);
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> login(String server, String username, String password) async {
    _setState(AppState.loading);
    try {
      _xtream.configure(server, username, password);
      _user = await _xtream.authenticate();
      await _storage.saveCredentials(server, username, password);
      await _loadContent();
      _setState(AppState.loaded);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _user = null;
      _setState(AppState.error);
      return false;
    }
  }

  Future<void> logout() async {
    _radioCtrl.stop();
    await _storage.clearCredentials();
    _user = null;
    _allChannels = [];
    _liveCategories = [];
    _vodStreams = [];
    _vodCategories = [];
    _series = [];
    _seriesCategories = [];
    _radioStreams = [];
    _radioCategories = [];
    _nowPlayingRadio = null;
    _radioIsPlaying = false;
    _setState(AppState.idle);
  }

  // ─── Load content ─────────────────────────────────────────────────────────
  Future<void> _loadContent() async {
    final favIds = _storage.getFavouriteIds();
    final cats = await _xtream.getLiveCategories();
    final channels = await _xtream.getLiveStreams();
    for (var ch in channels) {
      ch.isFavourite = favIds.contains(ch.streamId);
    }
    _liveCategories = cats;
    _allChannels = channels;
    notifyListeners();
  }

  Future<void> reloadLiveChannels() async {
    if (_state == AppState.loading) return;
    _setState(AppState.loading);
    try {
      await _loadContent();
      _setState(AppState.loaded);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setState(AppState.error);
    }
  }

  Future<void> loadVod() async {
    if (_vodStreams.isNotEmpty) return;
    try {
      final cats = await _xtream.getVodCategories();
      final vods = await _xtream.getVodStreams();
      _vodCategories = cats;
      _vodStreams = vods;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSeries() async {
    if (_series.isNotEmpty) return;
    try {
      final cats = await _xtream.getSeriesCategories();
      final list = await _xtream.getSeries();
      _seriesCategories = cats;
      _series = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadRadio() async {
    if (_radioStreams.isNotEmpty || _radioLoading) return;
    _radioLoading = true;
    notifyListeners();
    try {
      final cats = await _xtream.getRadioCategories();
      final streams = await _xtream.getRadioStreams();
      _radioCategories = cats;
      _radioStreams = streams;
    } catch (_) {
      _radioStreams = [];
    } finally {
      _radioLoading = false;
      notifyListeners();
    }
  }

  // ─── Radio playback ───────────────────────────────────────────────────────
  Future<void> playRadio(LiveChannel station) async {
    if (_nowPlayingRadio?.streamId == station.streamId) {
      await _radioCtrl.togglePlayPause();
    } else {
      final url = _xtream.streamUrl(station.streamId);
      await _radioCtrl.play(url);
      _nowPlayingRadio = station;
    }
    _radioIsPlaying = _radioCtrl.isPlaying;
    notifyListeners();
  }

  Future<void> toggleRadioPlayPause() async {
    await _radioCtrl.togglePlayPause();
    _radioIsPlaying = _radioCtrl.isPlaying;
    notifyListeners();
  }

  Future<void> stopRadio() async {
    await _radioCtrl.stop();
    _nowPlayingRadio = null;
    _radioIsPlaying = false;
    notifyListeners();
  }

  // ─── Series info ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) =>
      _xtream.getSeriesInfo(seriesId);

  // ─── Category filter ──────────────────────────────────────────────────────
  void selectCategory(String categoryId) {
    _selectedCategoryId = _selectedCategoryId == categoryId ? '' : categoryId;
    notifyListeners();
  }

  void selectRadioCategory(String categoryId) {
    _selectedRadioCategoryId =
        _selectedRadioCategoryId == categoryId ? '' : categoryId;
    notifyListeners();
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ─── Favourites ───────────────────────────────────────────────────────────
  Future<void> toggleFavourite(LiveChannel channel) async {
    await _storage.toggleFavourite(channel.streamId);
    channel.isFavourite = !channel.isFavourite;
    notifyListeners();
  }

  // ─── Watch history ────────────────────────────────────────────────────────
  Future<void> addToHistory(LiveChannel channel) async {
    await _storage.addToHistory(channel);
  }

  // ─── URL helpers ─────────────────────────────────────────────────────────
  String streamUrl(int streamId, {String ext = 'm3u8', String directSource = ''}) =>
      _xtream.streamUrl(streamId, ext: ext, directSource: directSource);
  String vodUrl(int streamId, String ext) => _xtream.vodUrl(streamId, ext);
  String seriesEpisodeUrl(String episodeId, String ext) =>
      _xtream.seriesEpisodeUrl(episodeId, ext);
  String catchupUrl(int streamId, DateTime start, int durationMinutes) =>
      _xtream.catchupUrl(streamId, start, durationMinutes);

  Future<List<EpgEntry>> getEpg(String epgChannelId, {int limit = 10}) =>
      _xtream.getEpg(epgChannelId, limit: limit);

  @override
  void dispose() {
    _radioCtrl.dispose();
    super.dispose();
  }

  void _setState(AppState s) {
    _state = s;
    notifyListeners();
  }
}
