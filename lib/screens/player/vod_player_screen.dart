import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class VodPlayerScreen extends StatefulWidget {
  /// Pass [vod] for movie playback or [directUrl] + [displayTitle] for
  /// episode playback. At least one of [vod] or [directUrl] must be provided.
  final VodStream? vod;
  final String? directUrl;
  final String? displayTitle;

  const VodPlayerScreen({
    super.key,
    this.vod,
    this.directUrl,
    this.displayTitle,
  });

  @override
  State<VodPlayerScreen> createState() => _VodPlayerScreenState();
}

class _VodPlayerScreenState extends State<VodPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;

  bool _showOsd = true;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();
    _player = Player();
    _videoController = VideoController(_player);

    _player.stream.playing.listen((p) {
      if (mounted) setState(() => _isPlaying = p);
    });
    _player.stream.buffering.listen((b) {
      if (mounted) setState(() => _isBuffering = b);
    });
    _player.stream.position.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.stream.duration.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _init();
    _autoHideOsd();
  }

  void _init() {
    final String url;
    if (widget.directUrl != null) {
      url = widget.directUrl!;
    } else {
      final provider = context.read<AppProvider>();
      url = provider.vodUrl(
          widget.vod!.streamId, widget.vod!.containerExtension);
    }
    _player.open(Media(url));
  }

  void _toggleOsd() {
    setState(() => _showOsd = !_showOsd);
    if (_showOsd) _autoHideOsd();
  }

  void _showOsdBriefly() {
    setState(() => _showOsd = true);
    _autoHideOsd();
  }

  void _autoHideOsd() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showOsd = false);
    });
  }

  void _seek(Duration delta) {
    final pos = _player.state.position + delta;
    _player.seek(pos.isNegative ? Duration.zero : pos);
    _showOsdBriefly();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String get _title {
    if (widget.displayTitle != null && widget.displayTitle!.isNotEmpty) {
      return widget.displayTitle!;
    }
    return widget.vod?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.goBack ||
              key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.browserBack) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter) {
            if (_showOsd) {
              _player.playOrPause();
            } else {
              _showOsdBriefly();
            }
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowRight) {
            _seek(const Duration(seconds: 10));
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowLeft) {
            _seek(const Duration(seconds: -10));
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown) {
            _toggleOsd();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleOsd,
          child: Stack(
            children: [
              // ── Video ──────────────────────────────────────────────
              SizedBox.expand(
                child: Video(
                  controller: _videoController,
                  controls: NoVideoControls,
                ),
              ),

              // ── Buffering ─────────────────────────────────────────
              if (_isBuffering)
                const Center(
                  child: CircularProgressIndicator(
                    color: UhvaColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),

              // ── Centre pause icon (shown when paused) ─────────────
              if (!_isPlaying && !_isBuffering)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white54,
                    size: 72,
                  ),
                ),

              // ── OSD overlay ───────────────────────────────────────
              AnimatedOpacity(
                opacity: _showOsd ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showOsd,
                  child: _VodOsd(
                    title: _title,
                    isPlaying: _isPlaying,
                    position: _position,
                    duration: _duration,
                    onBack: () => Navigator.pop(context),
                    onPlayPause: () => _player.playOrPause(),
                    onSeek: _seek,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom OSD overlay for VOD ───────────────────────────────────────────────

class _VodOsd extends StatelessWidget {
  final String title;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final void Function(Duration) onSeek;

  const _VodOsd({
    required this.title,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inSeconds > 0
        ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        // ── Top gradient bar ──────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 36, 16, 16),
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
                if (title.isNotEmpty)
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Bottom gradient bar ───────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Control buttons ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OsdBtn(
                      icon: Icons.replay_10,
                      size: 38,
                      onTap: () => onSeek(const Duration(seconds: -10)),
                    ),
                    const SizedBox(width: 20),
                    _OsdBtn(
                      icon: isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 56,
                      onTap: onPlayPause,
                    ),
                    const SizedBox(width: 20),
                    _OsdBtn(
                      icon: Icons.forward_10,
                      size: 38,
                      onTap: () => onSeek(const Duration(seconds: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Progress bar ───────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(UhvaColors.primary),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Position / duration ────────────────────────────
                Row(
                  children: [
                    Text(
                      _fmt(position),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(duration),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),

                // ── Remote hint ────────────────────────────────────
                const SizedBox(height: 4),
                const Text(
                  '◀ ▶  Seek 10s   •   OK  Play/Pause   •   ↑↓  Hide',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OsdBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _OsdBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
