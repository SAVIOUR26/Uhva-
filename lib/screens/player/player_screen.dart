import 'dart:async';

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

  /// Optional: pass the full channel list so the user can switch channels
  /// with left/right on the remote without returning to the guide.
  final List<LiveChannel> channels;
  final int channelIndex;

  const PlayerScreen({
    super.key,
    required this.channel,
    this.channels = const [],
    this.channelIndex = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;

  bool _showOsd = true;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Retry state
  int _retryCount = 0;
  static const _maxRetries = 3;

  // Channel switching
  late List<LiveChannel> _channels;
  late int _channelIdx;
  LiveChannel get _channel => _channels.isNotEmpty
      ? _channels[_channelIdx]
      : widget.channel;

  // EPG
  List<EpgEntry> _epg = [];

  // Timers
  Timer? _osdTimer;
  Timer? _bufferTimeoutTimer;

  // Channel switch overlay
  bool _showChannelSwitch = false;
  Timer? _channelSwitchTimer;

  // Retry focus node
  final _retryFocus = FocusNode();

  // Stream subscriptions
  StreamSubscription<bool>? _bufferSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _channels = widget.channels.isNotEmpty ? widget.channels : [widget.channel];
    _channelIdx = widget.channelIndex;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();

    _player = Player();
    _videoController = VideoController(_player);

    _bufferSub = _player.stream.buffering.listen(_onBuffering);
    _errorSub = _player.stream.error.listen(_onError);

    _openChannel(_channel);
    _loadEpg();
    _scheduleOsdHide();
  }

  @override
  void dispose() {
    _osdTimer?.cancel();
    _bufferTimeoutTimer?.cancel();
    _channelSwitchTimer?.cancel();
    _bufferSub?.cancel();
    _errorSub?.cancel();
    _retryFocus.dispose();
    WakelockPlus.disable();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ── Stream loading ─────────────────────────────────────────────────────────

  void _openChannel(LiveChannel ch) {
    _retryCount = 0;
    _bufferTimeoutTimer?.cancel();
    final url = _buildUrl(ch, ts: false);
    _player.open(Media(url));
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isBuffering = true;
    });
    _startBufferTimeout();
    _loadEpg();
  }

  String _buildUrl(LiveChannel ch, {bool ts = false}) {
    final provider = context.read<AppProvider>();
    if (!ts && ch.directSource.isNotEmpty) return ch.directSource;
    return provider.streamUrl(ch.streamId, ext: ts ? 'ts' : 'm3u8');
  }

  void _startBufferTimeout() {
    _bufferTimeoutTimer?.cancel();
    _bufferTimeoutTimer =
        Timer(const Duration(seconds: 20), _onBufferTimeout);
  }

  void _onBufferTimeout() {
    if (!mounted || _hasError) return;
    if (_isBuffering && _retryCount < _maxRetries) {
      _retryWithFallback();
    }
  }

  void _onBuffering(bool buffering) {
    if (!mounted) return;
    setState(() => _isBuffering = buffering);
    if (!buffering) {
      _bufferTimeoutTimer?.cancel();
    } else {
      _startBufferTimeout();
    }
  }

  void _onError(String error) {
    if (!mounted || error.isEmpty) return;
    _bufferTimeoutTimer?.cancel();

    if (_retryCount < _maxRetries) {
      _retryWithFallback();
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  void _retryWithFallback() {
    _retryCount++;
    final useTs = _retryCount.isOdd; // alternate m3u8 → ts → m3u8 → ts
    final url = _buildUrl(_channel, ts: useTs);
    _player.open(Media(url));
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _startBufferTimeout();
  }

  void _manualRetry() {
    _openChannel(_channel);
  }

  String _friendlyError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('403') || r.contains('forbidden'))
      return 'Access denied (403) — stream may be geo-restricted.';
    if (r.contains('404') || r.contains('not found'))
      return 'Stream not found (404) — channel may be offline.';
    if (r.contains('401') || r.contains('unauthorized'))
      return 'Authentication failed — check your IPTV credentials.';
    if (r.contains('timeout') || r.contains('timed out'))
      return 'Connection timed out — check your internet.';
    if (r.contains('refused'))
      return 'Server refused connection — server may be down.';
    return 'Stream unavailable. Please retry.';
  }

  // ── EPG ────────────────────────────────────────────────────────────────────

  Future<void> _loadEpg() async {
    if (_channel.epgChannelId.isEmpty) return;
    final entries =
        await context.read<AppProvider>().getEpg(_channel.epgChannelId);
    if (mounted) setState(() => _epg = entries);
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

  // ── OSD ────────────────────────────────────────────────────────────────────

  void _showOsdNow() {
    setState(() => _showOsd = true);
    _scheduleOsdHide();
  }

  void _toggleOsd() {
    if (_showOsd) {
      _osdTimer?.cancel();
      setState(() => _showOsd = false);
    } else {
      _showOsdNow();
    }
  }

  void _scheduleOsdHide() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showOsd = false);
    });
  }

  // ── Channel switching ─────────────────────────────────────────────────────

  bool get _canSwitchChannels => _channels.length > 1;

  void _switchChannel(int delta) {
    if (!_canSwitchChannels) return;
    final next = (_channelIdx + delta).clamp(0, _channels.length - 1);
    if (next == _channelIdx) return;
    setState(() {
      _channelIdx = next;
      _showChannelSwitch = true;
      _epg = [];
    });
    context.read<AppProvider>().addToHistory(_channel);
    _openChannel(_channel);
    _showOsdNow();

    _channelSwitchTimer?.cancel();
    _channelSwitchTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showChannelSwitch = false);
    });
  }

  // ── Catch-up ───────────────────────────────────────────────────────────────

  void _showCatchupSheet() {
    if (_epg.isEmpty) return;
    final provider = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: UhvaColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CatchupSheet(
        epgEntries: _epg,
        channel: _channel,
        onSelect: (entry) {
          final dur = entry.end
              .difference(entry.start)
              .inMinutes
              .clamp(1, 480);
          final url =
              provider.catchupUrl(_channel.streamId, entry.start, dur);
          _player.open(Media(url));
          setState(() => _hasError = false);
        },
      ),
    );
  }

  // ── Remote key handler ─────────────────────────────────────────────────────

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Back / Exit
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.browserBack) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    // Channel Up / Down (dedicated remote keys + Page keys)
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.pageUp) {
      _switchChannel(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageDown) {
      _switchChannel(1);
      return KeyEventResult.handled;
    }

    // Arrow navigation
    if (key == LogicalKeyboardKey.arrowUp) {
      _showOsdNow();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_showOsd) {
        setState(() => _showOsd = false);
      } else {
        _showOsdNow();
      }
      return KeyEventResult.handled;
    }

    // Arrow left/right = previous/next channel when OSD visible
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_showOsd && _canSwitchChannels) {
        _switchChannel(-1);
      } else {
        _showOsdNow();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (_showOsd && _canSwitchChannels) {
        _switchChannel(1);
      } else {
        _showOsdNow();
      }
      return KeyEventResult.handled;
    }

    // Select / Enter = toggle OSD
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {
      _toggleOsd();
      return KeyEventResult.handled;
    }

    // Info key
    if (key == LogicalKeyboardKey.info) {
      _showOsdNow();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => _handleKey(event),
        child: GestureDetector(
          onTap: _toggleOsd,
          child: Stack(
            children: [
              // ── Video ───────────────────────────────────────────────
              SizedBox.expand(
                child: Video(
                  controller: _videoController,
                  controls: NoVideoControls,
                ),
              ),

              // ── Buffering spinner ───────────────────────────────────
              if (_isBuffering && !_hasError)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: UhvaColors.primary, strokeWidth: 2.5),
                      if (_retryCount > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Retrying… ($_retryCount/$_maxRetries)',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ]
                    ],
                  ),
                ),

              // ── Error state ─────────────────────────────────────────
              if (_hasError)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.signal_wifi_off,
                          color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage.isEmpty
                            ? 'Stream unavailable.'
                            : _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Focus(
                            focusNode: _retryFocus,
                            autofocus: true,
                            onKeyEvent: (_, ev) {
                              if (ev is! KeyDownEvent)
                                return KeyEventResult.ignored;
                              if (ev.logicalKey == LogicalKeyboardKey.select ||
                                  ev.logicalKey == LogicalKeyboardKey.enter) {
                                _manualRetry();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Builder(builder: (ctx) {
                              final focused = Focus.of(ctx).hasFocus;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: focused
                                        ? UhvaColors.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: TextButton.icon(
                                  onPressed: _manualRetry,
                                  icon: const Icon(Icons.refresh,
                                      color: UhvaColors.primaryLight),
                                  label: const Text('Retry',
                                      style: TextStyle(
                                          color: UhvaColors.primaryLight)),
                                ),
                              );
                            }),
                          ),
                          if (_canSwitchChannels) ...[
                            const SizedBox(width: 12),
                            Focus(
                              onKeyEvent: (_, ev) {
                                if (ev is! KeyDownEvent)
                                  return KeyEventResult.ignored;
                                if (ev.logicalKey ==
                                        LogicalKeyboardKey.select ||
                                    ev.logicalKey ==
                                        LogicalKeyboardKey.enter) {
                                  Navigator.pop(context);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Back to Guide',
                                    style: TextStyle(
                                        color: UhvaColors.onSurfaceMuted)),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

              // ── OSD ─────────────────────────────────────────────────
              AnimatedOpacity(
                opacity: _showOsd ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showOsd,
                  child: _OsdOverlay(
                    channel: _channel,
                    currentEpg: _currentEpg,
                    nextEpg: _nextEpg,
                    channelIdx: _channelIdx,
                    totalChannels: _channels.length,
                    canSwitchChannels: _canSwitchChannels,
                    onBack: () => Navigator.pop(context),
                    onFavourite: () {
                      context
                          .read<AppProvider>()
                          .toggleFavourite(_channel);
                      setState(() {});
                    },
                    onCatchup: _channel.tvArchive
                        ? _showCatchupSheet
                        : null,
                    onPrevChannel: _canSwitchChannels
                        ? () => _switchChannel(-1)
                        : null,
                    onNextChannel: _canSwitchChannels
                        ? () => _switchChannel(1)
                        : null,
                  ),
                ),
              ),

              // ── Channel switch banner ─────────────────────────────
              if (_showChannelSwitch)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _ChannelSwitchBanner(channel: _channel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── OSD Overlay ───────────────────────────────────────────────────────────────

class _OsdOverlay extends StatelessWidget {
  final LiveChannel channel;
  final EpgEntry? currentEpg;
  final EpgEntry? nextEpg;
  final int channelIdx;
  final int totalChannels;
  final bool canSwitchChannels;
  final VoidCallback onBack;
  final VoidCallback onFavourite;
  final VoidCallback? onCatchup;
  final VoidCallback? onPrevChannel;
  final VoidCallback? onNextChannel;

  const _OsdOverlay({
    required this.channel,
    required this.currentEpg,
    required this.nextEpg,
    required this.channelIdx,
    required this.totalChannels,
    required this.canSwitchChannels,
    required this.onBack,
    required this.onFavourite,
    this.onCatchup,
    this.onPrevChannel,
    this.onNextChannel,
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
                  tooltip: 'Back',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (canSwitchChannels)
                        Text(
                          'CH ${channelIdx + 1} / $totalChannels',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                // Channel nav arrows
                if (canSwitchChannels) ...[
                  _OsdIconBtn(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Prev channel',
                    onTap: onPrevChannel,
                  ),
                  _OsdIconBtn(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Next channel',
                    onTap: onNextChannel,
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                const SizedBox(width: 8),
                _OsdIconBtn(
                  icon: channel.isFavourite
                      ? Icons.star
                      : Icons.star_border,
                  tooltip: channel.isFavourite
                      ? 'Remove favourite'
                      : 'Add favourite',
                  color:
                      channel.isFavourite ? Colors.amber : Colors.white70,
                  onTap: onFavourite,
                ),
                if (channel.tvArchive && onCatchup != null)
                  _OsdIconBtn(
                    icon: Icons.history,
                    tooltip: 'Catch-up',
                    onTap: onCatchup,
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
                      valueColor: const AlwaysStoppedAnimation(
                          UhvaColors.primary),
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
                        Expanded(
                          child: Text(nextEpg!.title,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
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
                // Remote hint
                if (canSwitchChannels) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '◀ ▶  Switch channel    ▲  Show info    ⏎  Toggle OSD',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── OSD icon button ───────────────────────────────────────────────────────────

class _OsdIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _OsdIconBtn({
    required this.icon,
    required this.tooltip,
    this.color = Colors.white70,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

// ── Channel switch banner ─────────────────────────────────────────────────────

class _ChannelSwitchBanner extends StatelessWidget {
  final LiveChannel channel;

  const _ChannelSwitchBanner({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: UhvaColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.streamIcon.isNotEmpty)
            CachedNetworkImage(
              imageUrl: channel.streamIcon,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.tv, color: Colors.white54, size: 20),
            )
          else
            const Icon(Icons.live_tv_rounded,
                color: UhvaColors.primary, size: 22),
          const SizedBox(width: 12),
          Text(
            channel.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Catch-up Sheet ────────────────────────────────────────────────────────────

class _CatchupSheet extends StatelessWidget {
  final List<EpgEntry> epgEntries;
  final LiveChannel channel;
  final void Function(EpgEntry) onSelect;

  const _CatchupSheet({
    required this.epgEntries,
    required this.channel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final past = epgEntries
        .where((e) => e.end.isBefore(DateTime.now()))
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: UhvaColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.history, color: UhvaColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Catch-up',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: UhvaColors.onBackground),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (past.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No past programmes available',
                style: TextStyle(color: UhvaColors.onSurfaceMuted)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: past.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 0, indent: 16),
              itemBuilder: (_, i) {
                final entry = past[i];
                return ListTile(
                  leading: const Icon(Icons.play_circle_outline,
                      color: UhvaColors.primary),
                  title: Text(entry.title,
                      style: const TextStyle(
                          fontSize: 13, color: UhvaColors.onBackground)),
                  subtitle: Text(entry.timeRange,
                      style: const TextStyle(
                          fontSize: 11,
                          color: UhvaColors.onSurfaceMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(entry);
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
