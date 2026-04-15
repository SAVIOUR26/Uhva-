import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../player/vod_player_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final SeriesStream series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool _loading = true;
  Map<String, List<SeriesEpisode>> _episodesBySeason = {};
  List<String> _seasons = [];
  String _selectedSeason = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final data = await context
          .read<AppProvider>()
          .getSeriesInfo(widget.series.seriesId.toString());

      final rawEpisodes = data['episodes'] as Map<String, dynamic>? ?? {};
      final Map<String, List<SeriesEpisode>> parsed = {};

      for (final entry in rawEpisodes.entries) {
        final seasonNum = int.tryParse(entry.key) ?? 0;
        final list = (entry.value as List? ?? [])
            .map((e) => SeriesEpisode.fromJson(
                e as Map<String, dynamic>, seasonNum))
            .toList();
        list.sort((a, b) => a.episodeNum.compareTo(b.episodeNum));
        parsed[entry.key] = list;
      }

      final seasons = parsed.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      if (mounted) {
        setState(() {
          _episodesBySeason = parsed;
          _seasons = seasons;
          _selectedSeason = seasons.isNotEmpty ? seasons.first : '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playEpisode(SeriesEpisode episode) {
    final provider = context.read<AppProvider>();
    final url = provider.seriesEpisodeUrl(episode.id, episode.containerExtension);
    final title =
        '${widget.series.name} · S${episode.season.toString().padLeft(2, '0')}E${episode.episodeNum.toString().padLeft(2, '0')}${episode.title.isNotEmpty ? ' – ${episode.title}' : ''}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VodPlayerScreen(directUrl: url, displayTitle: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;

    return Scaffold(
      backgroundColor: UhvaColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: UhvaColors.primary))
          : Column(
              children: [
                _SeriesHeader(series: series),
                if (_seasons.isNotEmpty) ...[
                  _SeasonSelector(
                    seasons: _seasons,
                    selected: _selectedSeason,
                    onSelect: (s) => setState(() => _selectedSeason = s),
                  ),
                  const Divider(height: 0),
                ],
                Expanded(child: _EpisodeList(
                  episodes: _episodesBySeason[_selectedSeason] ?? [],
                  onPlay: _playEpisode,
                )),
              ],
            ),
    );
  }
}

class _SeriesHeader extends StatelessWidget {
  final SeriesStream series;
  const _SeriesHeader({required this.series});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: UhvaColors.surface,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image with gradient + back button overlay
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                series.cover.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: series.cover,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: UhvaColors.surfaceAlt),
                        errorWidget: (_, __, ___) =>
                            Container(color: UhvaColors.surfaceAlt),
                      )
                    : Container(color: UhvaColors.surfaceAlt),
                // Bottom gradient fade
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, UhvaColors.surface],
                      stops: [0.5, 1.0],
                    ),
                  ),
                ),
                // Top gradient for back button readability
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: SizedBox(height: 80),
                  ),
                ),
                Positioned(
                  top: 36,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // Metadata below the cover
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: UhvaColors.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    if (series.genre.isNotEmpty)
                      _MetaChip(series.genre),
                    if (series.rating.isNotEmpty && series.rating != '0')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            series.rating,
                            style: const TextStyle(
                                fontSize: 12,
                                color: UhvaColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    if (series.releaseDate.isNotEmpty)
                      _MetaChip(series.releaseDate.length >= 4
                          ? series.releaseDate.substring(0, 4)
                          : series.releaseDate),
                  ],
                ),
                if (series.plot.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    series.plot,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: UhvaColors.onSurfaceMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, color: UhvaColors.onSurfaceMuted),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  final List<String> seasons;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SeasonSelector({
    required this.seasons,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: UhvaColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: seasons.length,
        itemBuilder: (_, i) {
          final s = seasons[i];
          final sel = s == selected;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? UhvaColors.primary : UhvaColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Season $s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? Colors.white : UhvaColors.onSurfaceMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpisodeList extends StatelessWidget {
  final List<SeriesEpisode> episodes;
  final ValueChanged<SeriesEpisode> onPlay;

  const _EpisodeList({required this.episodes, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return const Center(
        child: Text(
          'No episodes available',
          style: TextStyle(color: UhvaColors.onSurfaceMuted),
        ),
      );
    }

    return ListView.separated(
      itemCount: episodes.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
      itemBuilder: (_, i) {
        final ep = episodes[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: UhvaColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                ep.episodeNum.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: UhvaColors.primaryLight,
                ),
              ),
            ),
          ),
          title: Text(
            ep.title.isNotEmpty ? ep.title : 'Episode ${ep.episodeNum}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: UhvaColors.onBackground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: ep.duration.isNotEmpty
              ? Text(
                  ep.duration,
                  style: const TextStyle(
                      fontSize: 11, color: UhvaColors.onSurfaceHint),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline,
                color: UhvaColors.primary, size: 28),
            onPressed: () => onPlay(ep),
          ),
          onTap: () => onPlay(ep),
        );
      },
    );
  }
}
