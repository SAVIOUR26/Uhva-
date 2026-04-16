import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../player/player_screen.dart';
import '../player/vod_player_screen.dart';
import '../series/series_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
    // Pre-load VOD + Series if not already loaded
    final provider = context.read<AppProvider>();
    provider.loadVod();
    provider.loadSeries();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _onChanged,
          style: const TextStyle(color: UhvaColors.onBackground, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search channels, movies, series…',
            hintStyle:
                const TextStyle(color: UhvaColors.onSurfaceMuted, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        color: UhvaColors.onSurfaceMuted, size: 20),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _query.isEmpty
          ? _RecentChannels(
              channels: provider.recentChannels,
              onTap: (ch) => _openChannel(context, provider, ch),
            )
          : _SearchResults(
              query: _query,
              provider: provider,
              onChannelTap: (ch) => _openChannel(context, provider, ch),
              onVodTap: (v) => _openVod(context, provider, v),
              onSeriesTap: (s) => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(series: s)),
              ),
            ),
    );
  }

  void _openChannel(
      BuildContext context, AppProvider provider, LiveChannel ch) {
    provider.addToHistory(ch);
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch)));
  }

  void _openVod(BuildContext context, AppProvider provider, VodStream v) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VodPlayerScreen(vod: v)),
    );
  }
}

// ── Recent Channels (empty state) ─────────────────────────────────────────

class _RecentChannels extends StatelessWidget {
  final List<LiveChannel> channels;
  final void Function(LiveChannel) onTap;

  const _RecentChannels({required this.channels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 56, color: UhvaColors.onSurfaceHint),
            SizedBox(height: 16),
            Text('Search across Live TV, Movies & Series',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: UhvaColors.onSurfaceMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        const _SectionHeader(icon: Icons.history, label: 'Recently Watched'),
        ...channels.take(8).map((ch) => _ChannelResultTile(
              channel: ch,
              onTap: () => onTap(ch),
            )),
      ],
    );
  }
}

// ── Search Results ─────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final String query;
  final AppProvider provider;
  final void Function(LiveChannel) onChannelTap;
  final void Function(VodStream) onVodTap;
  final void Function(SeriesStream) onSeriesTap;

  const _SearchResults({
    required this.query,
    required this.provider,
    required this.onChannelTap,
    required this.onVodTap,
    required this.onSeriesTap,
  });

  List<LiveChannel> get _liveResults => provider.allChannels
      .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
      .take(20)
      .toList();

  List<VodStream> get _vodResults => provider.vodStreams
      .where((v) => v.name.toLowerCase().contains(query.toLowerCase()))
      .take(20)
      .toList();

  List<SeriesStream> get _seriesResults => provider.series
      .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
      .take(20)
      .toList();

  @override
  Widget build(BuildContext context) {
    final live = _liveResults;
    final vod = _vodResults;
    final series = _seriesResults;
    final totalCount = live.length + vod.length + series.length;

    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: 52, color: UhvaColors.onSurfaceHint),
            const SizedBox(height: 14),
            Text('No results for "$query"',
                style: const TextStyle(
                    color: UhvaColors.onSurfaceMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Live TV
        if (live.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.live_tv,
              label: 'Live Channels',
              count: live.length),
          ...live.map((ch) => _ChannelResultTile(
                channel: ch,
                onTap: () => onChannelTap(ch),
              )),
        ],
        // Movies
        if (vod.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.movie_outlined,
              label: 'Movies',
              count: vod.length),
          ...vod.map((v) => _VodResultTile(
                vod: v,
                onTap: () => onVodTap(v),
              )),
        ],
        // Series
        if (series.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.video_library_outlined,
              label: 'Series',
              count: series.length),
          ...series.map((s) => _SeriesResultTile(
                series: s,
                onTap: () => onSeriesTap(s),
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;

  const _SectionHeader({required this.icon, required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: UhvaColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: UhvaColors.primary),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: UhvaColors.primary,
              letterSpacing: 1.1,
            ),
          ),
          if (count != null) ...[
            const Spacer(),
            Text('$count',
                style: const TextStyle(
                    fontSize: 11, color: UhvaColors.onSurfaceMuted)),
          ],
        ],
      ),
    );
  }
}

// ── Channel Result Tile ────────────────────────────────────────────────────

class _ChannelResultTile extends StatelessWidget {
  final LiveChannel channel;
  final VoidCallback onTap;

  const _ChannelResultTile({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: channel.streamIcon.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: channel.streamIcon,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _PlaceholderIcon(Icons.live_tv),
              )
            : _PlaceholderIcon(Icons.live_tv),
      ),
      title: Text(channel.name,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: UhvaColors.onBackground)),
      subtitle: channel.currentProgram != null
          ? Text(channel.currentProgram!.title,
              style: const TextStyle(
                  fontSize: 11, color: UhvaColors.onSurfaceMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: UhvaColors.liveRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('LIVE',
            style: TextStyle(
                color: UhvaColors.liveRed,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── VOD Result Tile ────────────────────────────────────────────────────────

class _VodResultTile extends StatelessWidget {
  final VodStream vod;
  final VoidCallback onTap;

  const _VodResultTile({required this.vod, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: vod.streamIcon.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: vod.streamIcon,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _PlaceholderIcon(Icons.movie),
              )
            : _PlaceholderIcon(Icons.movie),
      ),
      title: Text(vod.name,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: UhvaColors.onBackground)),
      subtitle: vod.genre.isNotEmpty
          ? Text(vod.genre,
              style: const TextStyle(
                  fontSize: 11, color: UhvaColors.onSurfaceMuted))
          : null,
      trailing: vod.rating5based > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 13, color: Colors.amber),
                const SizedBox(width: 3),
                Text(vod.rating5based.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 11, color: UhvaColors.onSurface)),
              ],
            )
          : null,
    );
  }
}

// ── Series Result Tile ─────────────────────────────────────────────────────

class _SeriesResultTile extends StatelessWidget {
  final SeriesStream series;
  final VoidCallback onTap;

  const _SeriesResultTile({required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: series.cover.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: series.cover,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    _PlaceholderIcon(Icons.video_library),
              )
            : _PlaceholderIcon(Icons.video_library),
      ),
      title: Text(series.name,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: UhvaColors.onBackground)),
      subtitle: series.genre.isNotEmpty
          ? Text(series.genre,
              style: const TextStyle(
                  fontSize: 11, color: UhvaColors.onSurfaceMuted))
          : null,
      trailing: series.rating5based > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 13, color: Colors.amber),
                const SizedBox(width: 3),
                Text(series.rating5based.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 11, color: UhvaColors.onSurface)),
              ],
            )
          : null,
    );
  }
}

// ── Shared Placeholder Icon ────────────────────────────────────────────────

class _PlaceholderIcon extends StatelessWidget {
  final IconData icon;
  const _PlaceholderIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: UhvaColors.card,
      child: Icon(icon, size: 22, color: UhvaColors.onSurfaceHint),
    );
  }
}
