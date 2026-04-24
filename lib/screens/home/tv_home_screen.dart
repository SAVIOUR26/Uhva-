import 'dart:async';

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

// ── Hub launcher ─────────────────────────────────────────────────────────────

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

class _TopBar extends StatefulWidget {
  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr =
        '$h:$m  ${days[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          UhvaLogo(size: 32, horizontal: true),
          const Spacer(),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
    // Neighbour map: [left, right, up, down]  (-1 = none)
    const nav = [
      /* 0 Live TV   */ [2,  1,  -1,  3],
      /* 1 Movies    */ [0,  2,  -1,  4],
      /* 2 Series    */ [1,  0,  -1,  5],
      /* 3 Catch Up  */ [6,  4,   0, -1],
      /* 4 Radio     */ [3,  5,   1, -1],
      /* 5 Search    */ [4,  6,   2, -1],
      /* 6 Settings  */ [5,  3,   2, -1],
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

    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    final mainSize = isPhone ? 100.0 : 148.0;
    final mainIcon = isPhone ? 36.0  : 52.0;
    final subSize  = isPhone ? 70.0  : 96.0;
    final subIcon  = isPhone ? 24.0  : 32.0;
    final mainGap  = isPhone ? 20.0  : 32.0;
    final subGap   = isPhone ? 16.0  : 28.0;
    final rowGap   = isPhone ? 24.0  : 36.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main row ──────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HubButton(
                focusNode: _nodes[0],
                icon: Icons.live_tv_rounded,
                label: 'Live TV',
                size: mainSize, iconSize: mainIcon,
                color: const Color(0xFFE53935),
                onKey: (k) => onKey(0, k),
                onSelect: () => _go(const _TvLiveScreen()),
              ),
              SizedBox(width: mainGap),
              _HubButton(
                focusNode: _nodes[1],
                icon: Icons.movie_rounded,
                label: 'VOD',
                size: mainSize, iconSize: mainIcon,
                color: const Color(0xFF6C63FF),
                onKey: (k) => onKey(1, k),
                onSelect: () {
                  context.read<AppProvider>().loadVod();
                  _go(const VodScreen());
                },
              ),
              SizedBox(width: mainGap),
              _HubButton(
                focusNode: _nodes[2],
                icon: Icons.video_library_rounded,
                label: 'Series',
                size: mainSize, iconSize: mainIcon,
                color: const Color(0xFF2196F3),
                onKey: (k) => onKey(2, k),
                onSelect: () {
                  context.read<AppProvider>().loadSeries();
                  _go(const SeriesScreen());
                },
              ),
            ],
          ),

          SizedBox(height: rowGap),

          // ── Sub row ───────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HubButton(
                focusNode: _nodes[3],
                icon: Icons.history_rounded,
                label: 'Catch Up',
                size: subSize, iconSize: subIcon,
                color: const Color(0xFF4CAF50),
                onKey: (k) => onKey(3, k),
                onSelect: () => _go(const EpgScreen()),
              ),
              SizedBox(width: subGap),
              _HubButton(
                focusNode: _nodes[4],
                icon: Icons.radio_rounded,
                label: 'Radio',
                size: subSize, iconSize: subIcon,
                color: const Color(0xFFFF9800),
                onKey: (k) => onKey(4, k),
                onSelect: () {
                  context.read<AppProvider>().loadRadio();
                  _go(const RadioScreen());
                },
              ),
              SizedBox(width: subGap),
              _HubButton(
                focusNode: _nodes[5],
                icon: Icons.search_rounded,
                label: 'Search',
                size: subSize, iconSize: subIcon,
                color: const Color(0xFF9C27B0),
                onKey: (k) => onKey(5, k),
                onSelect: () => _go(const SearchScreen()),
              ),
              SizedBox(width: subGap),
              _HubButton(
                focusNode: _nodes[6],
                icon: Icons.settings_rounded,
                label: 'Settings',
                size: subSize, iconSize: subIcon,
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
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
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

// ── Live TV screen (pushed from hub) ────────────────────────────────────────
//
// Layout: top bar + scrollable list of category rows.
// Each row: fixed-width label on the left, horizontal channel cards on the right.
// D-pad: up/down moves between rows, left/right moves within a row.
// Scrollable.ensureVisible() is called on focus so the card scrolls into view.

class _TvLiveScreen extends StatefulWidget {
  const _TvLiveScreen();

  @override
  State<_TvLiveScreen> createState() => _TvLiveScreenState();
}

class _TvLiveScreenState extends State<_TvLiveScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // ── Loading / empty state ─────────────────────────────────────────
    if (provider.allChannels.isEmpty) {
      final isLoading = provider.state == AppState.loading;
      return Scaffold(
        backgroundColor: UhvaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: UhvaColors.primary))
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.live_tv_outlined,
                                color: UhvaColors.onSurfaceMuted, size: 56),
                            const SizedBox(height: 16),
                            const Text('No channels available',
                                style: TextStyle(
                                    color: UhvaColors.onSurface,
                                    fontSize: 15)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => provider.reloadLiveChannels(),
                              icon: const Icon(Icons.refresh,
                                  color: UhvaColors.primaryLight),
                              label: const Text('Retry',
                                  style: TextStyle(
                                      color: UhvaColors.primaryLight)),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Full channel guide ────────────────────────────────────────────
    return Scaffold(
      backgroundColor: UhvaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildCategoryRows(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: UhvaColors.divider)),
      ),
      child: Row(
        children: [
          Focus(
            onKeyEvent: (_, ev) {
              if (ev is KeyDownEvent &&
                  (ev.logicalKey == LogicalKeyboardKey.select ||
                   ev.logicalKey == LogicalKeyboardKey.enter)) {
                Navigator.pop(context);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.live_tv_rounded,
              color: UhvaColors.liveRed, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Live TV',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          const _LiveClock(),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildCategoryRows(AppProvider provider) {
    final rows = <_CategoryRow>[];
    bool firstSet = false;

    // Favourites
    final favs = provider.favouriteChannels;
    if (favs.isNotEmpty) {
      rows.add(_CategoryRow(
        label: 'FAVORITES',
        channels: favs,
        onSelect: _play,
        autofocusFirst: !firstSet,
      ));
      firstSet = true;
    }

    // Continue watching
    final recent = provider.recentChannels;
    if (recent.isNotEmpty) {
      rows.add(_CategoryRow(
        label: 'CONTINUE WATCHING',
        channels: recent,
        onSelect: _play,
        autofocusFirst: !firstSet,
      ));
      firstSet = true;
    }

    // One row per category
    for (final cat in provider.liveCategories) {
      final chs = provider.allChannels
          .where((c) => c.categoryId == cat.categoryId)
          .toList();
      if (chs.isEmpty) continue;
      rows.add(_CategoryRow(
        label: '${cat.categoryName.toUpperCase()}  (${chs.length})',
        channels: chs,
        onSelect: _play,
        autofocusFirst: !firstSet,
      ));
      firstSet = true;
    }

    // Fallback when no categories returned
    if (rows.isEmpty) {
      rows.add(_CategoryRow(
        label: 'ALL CHANNELS  (${provider.allChannels.length})',
        channels: provider.allChannels,
        onSelect: _play,
        autofocusFirst: true,
      ));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      itemCount: rows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: UhvaColors.divider, indent: 20),
      itemBuilder: (_, i) => rows[i],
    );
  }

  void _play(LiveChannel ch) {
    context.read<AppProvider>().addToHistory(ch);
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch)));
  }
}

// ── Live clock ────────────────────────────────────────────────────────────────

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return Text(
      '$h:$m  ${days[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}',
      style: const TextStyle(
        fontSize: 12,
        color: UhvaColors.onSurfaceMuted,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ── Category row: label on left, horizontal channel cards on right ────────────

class _CategoryRow extends StatelessWidget {
  final String label;
  final List<LiveChannel> channels;
  final ValueChanged<LiveChannel> onSelect;
  final bool autofocusFirst;

  const _CategoryRow({
    required this.label,
    required this.channels,
    required this.onSelect,
    this.autofocusFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left label column (fixed width) ──────────────────────
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: UhvaColors.onSurfaceMuted,
                  letterSpacing: 0.7,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // ── Horizontal channel cards ──────────────────────────────
          Expanded(
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 20),
                itemCount: channels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _TvChannelCard(
                  channel: channels[i],
                  onSelect: onSelect,
                  autofocus: autofocusFirst && i == 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Channel card ──────────────────────────────────────────────────────────────

class _TvChannelCard extends StatefulWidget {
  final LiveChannel channel;
  final ValueChanged<LiveChannel> onSelect;
  final bool autofocus;

  const _TvChannelCard({
    required this.channel,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  State<_TvChannelCard> createState() => _TvChannelCardState();
}

class _TvChannelCardState extends State<_TvChannelCard> {
  bool _focused = false;

  void _onFocusChange(bool focused) {
    setState(() => _focused = focused);
    if (focused) {
      // Scroll both the horizontal row and outer vertical list so card is visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: _onFocusChange,
      onKeyEvent: (_, ev) {
        if (ev is KeyDownEvent &&
            (ev.logicalKey == LogicalKeyboardKey.select ||
             ev.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onSelect(widget.channel);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => widget.onSelect(widget.channel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 160,
          decoration: BoxDecoration(
            color: _focused
                ? UhvaColors.primary.withValues(alpha: 0.18)
                : UhvaColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? UhvaColors.primary : UhvaColors.divider,
              width: _focused ? 2.0 : 0.5,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: UhvaColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChannelLogoTv(
                url: widget.channel.streamIcon,
                name: widget.channel.name,
              ),
              const SizedBox(height: 8),
              Text(
                widget.channel.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: _focused ? FontWeight.w600 : FontWeight.w400,
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

// ── Channel logo / initials fallback ─────────────────────────────────────────

class _ChannelLogoTv extends StatelessWidget {
  final String url;
  final String name;
  const _ChannelLogoTv({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 60,
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => _initials(),
              errorWidget: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() {
    final parts = name.trim().split(' ');
    final t = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : name.substring(0, name.length.clamp(0, 2));
    return Center(
      child: Text(
        t.toUpperCase(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: UhvaColors.primary,
        ),
      ),
    );
  }
}
