// ─── XtreamUser ────────────────────────────────────────────────────────────
class XtreamUser {
  final String username;
  final String password;
  final String serverUrl;
  final String? status;
  final String? expiryDate;
  final int? maxConnections;
  final int? activeConnections;

  const XtreamUser({
    required this.username,
    required this.password,
    required this.serverUrl,
    this.status,
    this.expiryDate,
    this.maxConnections,
    this.activeConnections,
  });

  factory XtreamUser.fromJson(Map<String, dynamic> json, String url, String user, String pass) {
    final info = json['user_info'] ?? {};
    return XtreamUser(
      username: user,
      password: pass,
      serverUrl: url,
      status: info['status'],
      expiryDate: info['exp_date'],
      maxConnections: int.tryParse(info['max_connections']?.toString() ?? ''),
      activeConnections: int.tryParse(info['active_cons']?.toString() ?? ''),
    );
  }
}

// ─── Category ──────────────────────────────────────────────────────────────
class StreamCategory {
  final String categoryId;
  final String categoryName;
  final int parentId;

  const StreamCategory({
    required this.categoryId,
    required this.categoryName,
    required this.parentId,
  });

  factory StreamCategory.fromJson(Map<String, dynamic> json) => StreamCategory(
        categoryId: json['category_id']?.toString() ?? '',
        categoryName: json['category_name'] ?? 'Uncategorized',
        parentId: int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
      );
}

// ─── Live Channel ──────────────────────────────────────────────────────────
class LiveChannel {
  final int streamId;
  final String name;
  final String streamIcon;
  final String epgChannelId;
  final String categoryId;
  final int streamType;
  final bool tvArchive;
  final int tvArchiveDuration;
  final String customSid;

  bool isFavourite;
  EpgEntry? currentProgram;
  EpgEntry? nextProgram;

  LiveChannel({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.epgChannelId,
    required this.categoryId,
    required this.streamType,
    required this.tvArchive,
    required this.tvArchiveDuration,
    required this.customSid,
    this.isFavourite = false,
    this.currentProgram,
    this.nextProgram,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) => LiveChannel(
        streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
        name: json['name'] ?? '',
        streamIcon: json['stream_icon'] ?? '',
        epgChannelId: json['epg_channel_id'] ?? '',
        categoryId: json['category_id']?.toString() ?? '',
        streamType: int.tryParse(json['stream_type']?.toString() ?? '0') ?? 0,
        tvArchive: (json['tv_archive'] == 1 || json['tv_archive'] == '1'),
        tvArchiveDuration: int.tryParse(json['tv_archive_duration']?.toString() ?? '0') ?? 0,
        customSid: json['custom_sid'] ?? '',
      );

  String streamUrl(String serverUrl, String username, String password, {String ext = 'm3u8'}) =>
      '$serverUrl/live/$username/$password/$streamId.$ext';

  Map<String, dynamic> toJson() => {
        'stream_id': streamId,
        'name': name,
        'stream_icon': streamIcon,
        'epg_channel_id': epgChannelId,
        'category_id': categoryId,
        'stream_type': streamType,
        'tv_archive': tvArchive ? 1 : 0,
        'tv_archive_duration': tvArchiveDuration,
        'custom_sid': customSid,
      };
}

// ─── VOD Stream ────────────────────────────────────────────────────────────
class VodStream {
  final int streamId;
  final String name;
  final String streamIcon;
  final String categoryId;
  final String containerExtension;
  final String rating;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final double rating5based;

  const VodStream({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.categoryId,
    required this.containerExtension,
    this.rating = '',
    this.plot = '',
    this.cast = '',
    this.director = '',
    this.genre = '',
    this.releaseDate = '',
    this.rating5based = 0.0,
  });

  factory VodStream.fromJson(Map<String, dynamic> json) => VodStream(
        streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
        name: json['name'] ?? '',
        streamIcon: json['stream_icon'] ?? '',
        categoryId: json['category_id']?.toString() ?? '',
        containerExtension: json['container_extension'] ?? 'mp4',
        rating: json['rating']?.toString() ?? '',
        plot: json['plot'] ?? '',
        cast: json['cast'] ?? '',
        director: json['director'] ?? '',
        genre: json['genre'] ?? '',
        releaseDate: json['releaseDate'] ?? '',
        rating5based: double.tryParse(json['rating_5based']?.toString() ?? '0') ?? 0.0,
      );

  String streamUrl(String serverUrl, String username, String password) =>
      '$serverUrl/movie/$username/$password/$streamId.$containerExtension';
}

// ─── EPG Entry ─────────────────────────────────────────────────────────────
class EpgEntry {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String channelId;

  const EpgEntry({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.channelId,
  });

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  String get timeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} – ${fmt(end)}';
  }
}
