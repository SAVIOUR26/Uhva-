import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final LiveChannel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;

  bool _showOsd = true;
  bool _isBuffering = false;
  bool _hasError = false;

  late LiveChannel _channel;
  List<EpgEntry> _epg = [];

  @override
  void initState() {
    super.initState();
    _channel = widget.channel;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();
    _player = Player();
    _videoController = VideoController(_player);
    _player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });
    _player.stream.error.listen((error) {
      if (mounted && error.isNotEmpty) setState(() => _hasError = true);
    });
    _initStream();
    _loadEpg();
    _autoHideOsd();
  }

  void _initStream() {
    final url = context.read<AppProvider>().streamUrl(_channel.streamId);
    _player.open(Media(url));
    setState(() => _hasError = false);
  }

  Future<void> _loadEpg() async {
    if (_channel.epgChannelId.isEmpty) return;
    final entries = await context.read<AppProvider>().getEpg(_channel.epgChannelId);
    if (mounted) setState(() => _epg = entries);
  }

  void _toggleOsd() {
    setState(() => _showOsd = !_showOsd);
    if (_showOsd) _autoHideOsd();
  }

  void _autoHideOsd() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showOsd = false);
    });
  }

  EpgEntry? get _currentEpg {
    final now = DateTime.now();
    for (final e in _epg) {
      if (now.isAfter(e.start) && now.isBefore(e.end)) return e;
    }
    return null;
  }

  EpgEntry? get _nextEpg {
    final curr = _currentEpg;
    if (curr == null) return null;
    final idx = _epg.indexOf(curr);
    return idx < _epg.length - 1 ? _epg[idx + 1] : null;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOsd,
        child: Stack(
          children: [
            // ── Video ────────────────────────────────────────────────────
            SizedBox.expand(
              child: Video(
                controller: _videoController,
                controls: NoVideoControls,
              ),
            ),

            // ── Buffering spinner ─────────────────────────────────────────
            if (_isBuffering && !_hasError)
              const Center(
                child: CircularProgressIndicator(
                  color: UhvaColors.primary,
                  strokeWidth: 2.5,
                ),
              ),

            // ── Error state ──────────────────────────────────────────────
            if (_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.signal_wifi_off,
                        color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Stream unavailable. Try again.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() => _hasError = false);
                        _initStream();
                      },
                      child: const Text('Retry',
                          style: TextStyle(color: UhvaColors.primaryLight)),
                    ),
                  ],
                ),
              ),

            // ── OSD ──────────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showOsd ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showOsd,
                child: _OsdOverlay(
                  channel: _channel,
                  currentEpg: _currentEpg,
                  nextEpg: _nextEpg,
                  onBack: () => Navigator.pop(context),
                  onFavourite: () {
                    context.read<AppProvider>().toggleFavourite(_channel);
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OsdOverlay extends StatelessWidget {
  final LiveChannel channel;
  final EpgEntry? currentEpg;
  final EpgEntry? nextEpg;
  final VoidCallback onBack;
  final VoidCallback onFavourite;

  const _OsdOverlay({
    required this.channel,
    required this.currentEpg,
    required this.nextEpg,
    required this.onBack,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top gradient bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 36, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: onBack,
                ),
                if (channel.streamIcon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CachedNetworkImage(
                      imageUrl: channel.streamIcon,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                Expanded(
                  child: Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: UhvaColors.liveRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '● LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    channel.isFavourite ? Icons.star : Icons.star_border,
                    color: channel.isFavourite ? Colors.amber : Colors.white70,
                  ),
                  onPressed: onFavourite,
                ),
              ],
            ),
          ),
        ),

        // Bottom EPG bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentEpg != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentEpg!.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        currentEpg!.timeRange,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: currentEpg!.progress,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(UhvaColors.primary),
                      minHeight: 3,
                    ),
                  ),
                  if (nextEpg != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Next: ',
                            style: TextStyle(
                                color: UhvaColors.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        Text(nextEpg!.title,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11)),
                        const Spacer(),
                        Text(nextEpg!.timeRange,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ],
                ] else
                  Text(
                    channel.name,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
