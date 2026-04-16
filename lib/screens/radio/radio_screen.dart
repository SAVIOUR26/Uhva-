import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel/category_bar.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<AppProvider>().loadRadio());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.radioLoading) {
      return const Center(
          child: CircularProgressIndicator(color: UhvaColors.primary));
    }

    if (provider.radioStreams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radio, size: 56, color: UhvaColors.onSurfaceHint),
            SizedBox(height: 16),
            Text('No radio stations available',
                style:
                    TextStyle(color: UhvaColors.onSurfaceMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        CategoryBar(
          categories: provider.radioCategories,
          selectedId: provider.selectedRadioCategoryId,
          onSelect: provider.selectRadioCategory,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            itemCount: provider.filteredRadioStreams.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 0, indent: 68),
            itemBuilder: (ctx, i) {
              final station = provider.filteredRadioStreams[i];
              return _RadioTile(
                station: station,
                isPlaying:
                    provider.nowPlayingRadio?.streamId == station.streamId,
                onTap: () => provider.playRadio(station),
              );
            },
          ),
        ),
        if (provider.nowPlayingRadio != null)
          _RadioMiniPlayer(
            station: provider.nowPlayingRadio!,
            isPlaying: provider.radioIsPlaying,
            onPlayPause: provider.toggleRadioPlayPause,
            onStop: provider.stopRadio,
          ),
      ],
    );
  }
}

// ── Radio Station Tile ─────────────────────────────────────────────────────

class _RadioTile extends StatelessWidget {
  final LiveChannel station;
  final bool isPlaying;
  final VoidCallback onTap;

  const _RadioTile(
      {required this.station,
      required this.isPlaying,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: isPlaying
          ? UhvaColors.primary.withValues(alpha: 0.08)
          : null,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: station.streamIcon.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: station.streamIcon,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _RadioIcon(),
              )
            : _RadioIcon(),
      ),
      title: Text(
        station.name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
          color: isPlaying ? UhvaColors.primary : UhvaColors.onBackground,
        ),
      ),
      subtitle: isPlaying
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq,
                    size: 14, color: UhvaColors.primary),
                const SizedBox(width: 4),
                const Text('Now playing',
                    style: TextStyle(
                        fontSize: 11, color: UhvaColors.primary)),
              ],
            )
          : null,
      trailing: isPlaying
          ? const Icon(Icons.pause_circle_filled,
              color: UhvaColors.primary, size: 28)
          : const Icon(Icons.play_circle_outline,
              color: UhvaColors.onSurfaceMuted, size: 28),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: UhvaColors.card,
      child: const Icon(Icons.radio, size: 28, color: UhvaColors.primary),
    );
  }
}

// ── Mini Player Bar ────────────────────────────────────────────────────────

class _RadioMiniPlayer extends StatelessWidget {
  final LiveChannel station;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const _RadioMiniPlayer({
    required this.station,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: UhvaColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.radio, color: UhvaColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: UhvaColors.onBackground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (isPlaying)
                  const Text('● Live Radio',
                      style: TextStyle(
                          fontSize: 10, color: UhvaColors.primary)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: UhvaColors.primary,
              size: 28,
            ),
            onPressed: onPlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined,
                color: UhvaColors.onSurfaceMuted, size: 24),
            onPressed: onStop,
          ),
        ],
      ),
    );
  }
}

