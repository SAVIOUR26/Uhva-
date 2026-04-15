import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ChannelTile extends StatelessWidget {
  final LiveChannel channel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onFavouriteTap;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.isSelected = false,
    this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? UhvaColors.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _ChannelIcon(url: channel.streamIcon, name: channel.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? UhvaColors.primaryLight
                          : UhvaColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (channel.currentProgram != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      channel.currentProgram!.title,
                      style: const TextStyle(
                        fontSize: 10,
                        color: UhvaColors.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: channel.currentProgram!.progress,
                      backgroundColor: UhvaColors.divider,
                      valueColor: AlwaysStoppedAnimation(
                        isSelected ? UhvaColors.primaryLight : UhvaColors.primary,
                      ),
                      minHeight: 2,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _LiveBadge(),
            if (onFavouriteTap != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onFavouriteTap,
                child: Icon(
                  channel.isFavourite ? Icons.star : Icons.star_border,
                  color: channel.isFavourite
                      ? Colors.amber
                      : UhvaColors.onSurfaceHint,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelIcon extends StatelessWidget {
  final String url;
  final String name;

  const _ChannelIcon({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: UhvaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => _initials(name),
              errorWidget: (_, __, ___) => _initials(name),
            )
          : _initials(name),
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : name.substring(0, name.length.clamp(0, 2));
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: UhvaColors.primaryLight,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: UhvaColors.liveRed,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
