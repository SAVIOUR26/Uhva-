import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/uhva_logo.dart';
import '../player/player_screen.dart';
import '../series/series_screen.dart';
import '../vod/vod_screen.dart';
import '../radio/radio_screen.dart';
import '../epg/epg_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

// ── Hub launcher (Star-IPTV style) ──────────────────────────────────────────

class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UhvaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(child: _HubMenu()),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          UhvaLogo(size: 32, horizontal: true),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: UhvaColors.onSurfaceMuted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hub menu with explicit D-pad focus management ────────────────────────────

class _HubMenu extends StatefulWidget {
  const _HubMenu();

  @override
  State<_HubMenu> createState() => _HubMenuState();
}

class _HubMenuState extends State<_HubMenu> {
  // Row 0: Live TV(0), Movies(1), Series(2)
  // Row 1: Catch Up(3), Radio(4), Search(5), Settings(6)
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(7, (_) => FocusNode());
    // Auto-focus Live TV when hub loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // Neighbour map: each entry = [left, right, up, down] node index (-1 = none)
    const nav = [
      // idx  left  right  up   down
      /* 0  */ [2,    1,    -1,   3],  // Live TV
      /* 1  */ [0,    2,    -1,   4],  // Movies
      /* 2  */ [1,    0,    -1,   5],  // Series
      /* 3  */ [6,    4,     0,  -1],  // Catch Up
      /* 4  */ [3,    5,     1,  -1],  // Radio
      /* 5  */ [4,    6,     2,  -1],  // Search
      /* 6  */ [5,    3,     2,  -1],  // Settings
    ];

    void onKey(int idx, LogicalKeyboardKey key) {
      final map = nav[idx];
      int target = -1;
      if (key == LogicalKeyboardKey.arrowLeft)  target = map[0];
      if (key == LogicalKeyboardKey.arrowRight) target = map[1];
      if (key == LogicalKeyboardKey.arrowUp)    target = map[2];
      if (key == LogicalKeyboardKey.arrowDown)  target = map[3];
      if (target >= 0) _nodes[target].requestFocus();
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main row ──────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HubButton(
                focusNode: _nodes[0],
                icon: Icons.live_tv_rounded,
                label: 'Live TV',
                size: 148, iconSize: 52,
                color: const Color(0xFFE53935),
                onKey: (k) => onKey(0, k),
                onSelect: () => _go(const _TvLiveScreen()),
              ),
              const SizedBox(width: 32),
              _HubButton(
                focusNode: _nodes[1],
                icon: Icons.movie_rounded,
                label: 'VOD',
                size: 148, iconSize: 52,
                color: const Color(0xFF6C63FF),
                onKey: (k) => onKey(1, k),
                onSelect: () {
                  context.read<AppProvider>().loadVod();
                  _go(const VodScreen());
                },
              ),
              const SizedBox(width: 32),
              _HubButton(
                focusNode: _nodes[2],
                icon: Icons.video_library_rounded,
                label: 'Series',
                size: 148, iconSize: 52,
                color: const Color(0xFF2196F3),
                onKey: (k) => onKey(2, k),
                onSelect: () {
                  context.read<AppProvider>().loadSeries();
                  _go(const SeriesScreen());
                },
              ),
            ],
          ),

          const SizedBox(height: 36),

          // ── Sub row ───────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HubButton(
                focusNode: _nodes[3],
                icon: Icons.history_rounded,
                label: 'Catch Up',
                size: 96, iconSize: 32,
                color: const Color(0xFF4CAF50),
                onKey: (k) => onKey(3, k),
                onSelect: () => _go(const EpgScreen()),
              ),
              const SizedBox(width: 28),
              _HubButton(
                focusNode: _nodes[4],
                icon: Icons.radio_rounded,
                label: 'Radio',
                size: 96, iconSize: 32,
                color: const Color(0xFFFF9800),
                onKey: (k) => onKey(4, k),
                onSelect: () {
                  context.read<AppProvider>().loadRadio();
                  _go(const RadioScreen());
                },
              ),
              const SizedBox(width: 28),
              _HubButton(
                focusNode: _nodes[5],
                icon: Icons.search_rounded,
                label: 'Search',
                size: 96, iconSize: 32,
                color: const Color(0xFF9C27B0),
                onKey: (k) => onKey(5, k),
                onSelect: () => _go(const SearchScreen()),
              ),
              const SizedBox(width: 28),
              _HubButton(
                focusNode: _nodes[6],
                icon: Icons.settings_rounded,
                label: 'Settings',
                size: 96, iconSize: 32,
                color: const Color(0xFF607D8B),
                onKey: (k) => onKey(6, k),
                onSelect: () => _go(const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Single circular hub button ───────────────────────────────────────────────

class _HubButton extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final double size;
  final double iconSize;
  final Color color;
  final void Function(LogicalKeyboardKey) onKey;
  final VoidCallback onSelect;

  const _HubButton({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.size,
    required this.iconSize,
    required this.color,
    required this.onKey,
    required this.onSelect,
  });

  @override
  State<_HubButton> createState() => _HubButtonState();
}

class _HubButtonState extends State<_HubButton>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocus(bool f) {
    setState(() => _focused = f);
    if (f) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: _onFocus,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        final arrows = {
          LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowUp,   LogicalKeyboardKey.arrowDown,
        };
        if (arrows.contains(event.logicalKey)) {
          widget.onKey(event.logicalKey);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
        child: GestureDetector(
          onTap: widget.onSelect,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _focused
                        ? widget.color.withValues(alpha: 0.25)
                        : UhvaColors.card,
                    border: Border.all(
                      color: _focused ? widget.color : UhvaColors.divider,
                      width: _focused ? 3 : 1.5,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: _focused ? widget.color : UhvaColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.size >= 130 ? 15 : 12,
                    fontWeight:
                        _focused ? FontWeight.w700 : FontWeight.w400,
                    color: _focused ? Colors.white : UhvaColors.onSurfaceMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

// ── Full-screen Live TV (pushed from hub) ────────────────────────────────────

class _TvLiveScreen extends StatefulWidget {
  const _TvLiveScreen();

  @override
  State<_TvLiveScreen> createState() => _TvLiveScreenState();
}

class _TvLiveScreenState extends State<_TvLiveScreen> {
  String _catId = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final channels = _catId.isEmpty
        ? provider.allChannels
        : provider.allChannels.where((c) => c.categoryId == _catId).toList();
    final recent = provider.recentChannels;

    return Scaffold(
      backgroundColor: UhvaColors.background,
      body: Column(
        children: [
          // ── Top bar with back ──────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: UhvaColors.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.live_tv_rounded,
                    color: UhvaColors.liveRed, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Live TV',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Category pills
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: [
                      _TvPill(
                          label: 'All',
                          selected: _catId.isEmpty,
                          onTap: () => setState(() => _catId = '')),
                      ...provider.liveCategories.map((c) => _TvPill(
                            label: c.categoryName,
                            selected: _catId == c.categoryId,
                            onTap: () =>
                                setState(() => _catId = c.categoryId),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Channel grid ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recent.isNotEmpty) ...[
                    _SectionHeader(title: 'Continue watching'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recent.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _TvChannelCard(
                          channel: recent[i],
                          onSelect: _play,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  _SectionHeader(
                      title: _catId.isEmpty ? 'All channels' : ''),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: channels.length,
                    itemBuilder: (_, i) => _TvChannelCard(
                      channel: channels[i],
                      onSelect: _play,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _play(LiveChannel ch) {
    context.read<AppProvider>().addToHistory(ch);
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch)));
  }
}

// ── Shared channel card ──────────────────────────────────────────────────────

class _TvChannelCard extends StatefulWidget {
  final LiveChannel channel;
  final ValueChanged<LiveChannel> onSelect;

  const _TvChannelCard({required this.channel, required this.onSelect});

  @override
  State<_TvChannelCard> createState() => _TvChannelCardState();
}

class _TvChannelCardState extends State<_TvChannelCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          widget.onSelect(widget.channel);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => widget.onSelect(widget.channel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _focused
                ? UhvaColors.primary.withValues(alpha: 0.2)
                : UhvaColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? UhvaColors.primary : UhvaColors.divider,
              width: _focused ? 2 : 0.5,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChannelLogoTv(
                  url: widget.channel.streamIcon, name: widget.channel.name),
              const SizedBox(height: 6),
              Text(
                widget.channel.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      _focused ? FontWeight.w600 : FontWeight.w400,
                  color: _focused
                      ? UhvaColors.primaryLight
                      : UhvaColors.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.channel.currentProgram != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.channel.currentProgram!.title,
                  style: const TextStyle(
                      fontSize: 9, color: UhvaColors.onSurfaceHint),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelLogoTv extends StatelessWidget {
  final String url;
  final String name;
  const _ChannelLogoTv({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 50,
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => _ini(),
              errorWidget: (_, __, ___) => _ini(),
            )
          : _ini(),
    );
  }

  Widget _ini() {
    final p = name.trim().split(' ');
    final t = p.length >= 2
        ? '${p[0][0]}${p[1][0]}'
        : name.substring(0, name.length.clamp(0, 2));
    return Center(
      child: Text(t.toUpperCase(),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: UhvaColors.primary)),
    );
  }
}

class _TvPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TvPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? UhvaColors.primary : UhvaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : UhvaColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: UhvaColors.onSurfaceMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}
