import 'package:dio/dio.dart';
import '../models/models.dart';

class XtreamService {
  late Dio _dio;
  late String _serverUrl;
  late String _username;
  late String _password;

  static final XtreamService _instance = XtreamService._internal();
  factory XtreamService() => _instance;
  XtreamService._internal();

  void configure(String serverUrl, String username, String password) {
    _serverUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    _username = username;
    _password = password;
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': 'UHVA-Player/1.0'},
    ));
  }

  String get _apiBase => '$_serverUrl/player_api.php?username=$_username&password=$_password';

  // ─── Auth ────────────────────────────────────────────────────────────────
  Future<XtreamUser> authenticate() async {
    final res = await _dio.get(_apiBase);
    if (res.statusCode != 200) throw Exception('Auth failed: ${res.statusCode}');
    final data = res.data;
    if (data['user_info'] == null) throw Exception('Invalid credentials');
    return XtreamUser.fromJson(data, _serverUrl, _username, _password);
  }

  // ─── Live categories ─────────────────────────────────────────────────────
  Future<List<StreamCategory>> getLiveCategories() async {
    final res = await _dio.get('$_apiBase&action=get_live_categories');
    final List list = res.data ?? [];
    return list.map((e) => StreamCategory.fromJson(e)).toList();
  }

  // ─── Live streams ─────────────────────────────────────────────────────────
  Future<List<LiveChannel>> getLiveStreams({String? categoryId}) async {
    String url = '$_apiBase&action=get_live_streams';
    if (categoryId != null && categoryId.isNotEmpty) {
      url += '&category_id=$categoryId';
    }
    final res = await _dio.get(url);
    final List list = res.data ?? [];
    return list.map((e) => LiveChannel.fromJson(e)).toList();
  }

  // ─── VOD categories ──────────────────────────────────────────────────────
  Future<List<StreamCategory>> getVodCategories() async {
    final res = await _dio.get('$_apiBase&action=get_vod_categories');
    final List list = res.data ?? [];
    return list.map((e) => StreamCategory.fromJson(e)).toList();
  }

  // ─── VOD streams ─────────────────────────────────────────────────────────
  Future<List<VodStream>> getVodStreams({String? categoryId}) async {
    String url = '$_apiBase&action=get_vod_streams';
    if (categoryId != null && categoryId.isNotEmpty) {
      url += '&category_id=$categoryId';
    }
    final res = await _dio.get(url);
    final List list = res.data ?? [];
    return list.map((e) => VodStream.fromJson(e)).toList();
  }

  // ─── EPG for a channel ───────────────────────────────────────────────────
  Future<List<EpgEntry>> getEpg(String epgChannelId, {int limit = 10}) async {
    try {
      final res = await _dio.get(
          '$_apiBase&action=get_simple_data_table&stream_id=$epgChannelId');
      final epgData = res.data?['epg_listings'] ?? [];
      return (epgData as List).map((e) {
        final start = DateTime.fromMillisecondsSinceEpoch(
            int.parse(e['start_timestamp'].toString()) * 1000);
        final end = DateTime.fromMillisecondsSinceEpoch(
            int.parse(e['stop_timestamp'].toString()) * 1000);
        return EpgEntry(
          title: _decodeBase64Safe(e['title'] ?? '') ,
          description: _decodeBase64Safe(e['description'] ?? ''),
          start: start,
          end: end,
          channelId: epgChannelId,
        );
      }).take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  String streamUrl(int streamId, {String ext = 'm3u8'}) =>
      '$_serverUrl/live/$_username/$_password/$streamId.$ext';

  String vodUrl(int streamId, String ext) =>
      '$_serverUrl/movie/$_username/$_password/$streamId.$ext';

  String _decodeBase64Safe(String input) {
    try {
      final bytes = Uri.decodeFull(input);
      return bytes;
    } catch (_) {
      return input;
    }
  }
}
