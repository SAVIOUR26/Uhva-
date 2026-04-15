import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/uhva_logo.dart';
import '../player/player_screen.dart';

class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  int _navIndex = 0;
  LiveChannel? _focusedChannel;
  final _navItems = ['Live TV', 'Movies', 'Favourites', 'Search', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: Row(
        children: [
          // ── Side nav ───────────────────────────────────────────────────
          _TvSideNav(
            items: _navItems,
            selectedIndex: _navIndex,
            onSelect: (i) => setState(() => _navIndex = i),
          ),
          const VerticalDivider(width: 0),
          // ── Content area ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TvTopBar(channel: _focusedChannel),
                Expanded(
                  child: _navIndex == 0
                      ? _TvLiveContent(
                          provider: provider,
                          onFocus: (ch) => setState(() => _focusedChannel = ch),
                          onSelect: (ch) {
                            provider.addToHistory(ch);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PlayerScreen(channel: ch)),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _navItems[_navIndex],
                            style: const TextStyle(
                                color: UhvaColors.onSurfaceMuted, fontSize: 22),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TvSideNav extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TvSideNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  IconData _icon(int i) {
    const icons = [
      Icons.live_tv,
      Icons.movie_outlined,
      Icons.star_border,
      Icons.search,
      Icons.settings_outlined,
    ];
    return icons[i];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: UhvaColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: UhvaLogo(size: 36, horizontal: true),
          ),
          ...List.generate(items.length, (i) {
            final sel = i == selectedIndex;
            return Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.select) {
                  onSelect(i);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: sel
                        ? UhvaColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: sel ? UhvaColors.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _icon(i),
                        size: 20,
                        color: sel
                            ? UhvaColors.primaryLight
                            : UhvaColors.onSurfaceMuted,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        items[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? UhvaColors.primaryLight
                              : UhvaColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TvTopBar extends StatelessWidget {
  final LiveChannel? channel;
  const _TvTopBar({this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: UhvaColors.divider)),
      ),
      child: Row(
        children: [
          if (channel != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: UhvaColors.liveRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Now: ${channel!.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: UhvaColors.onBackground,
              ),
            ),
            if (channel!.currentProgram != null) ...[
              const Text(' — ',
                  style: TextStyle(color: UhvaColors.onSurfaceHint)),
              Text(
                channel!.currentProgram!.title,
                style: const TextStyle(
                    fontSize: 13, color: UhvaColors.onSurfaceMuted),
              ),
            ],
          ] else
            const Text(
              'What would you like to watch?',
              style: TextStyle(
                  fontSize: 15, color: UhvaColors.onSurfaceMuted),
            ),
          const Spacer(),
          _ClockWidget(),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Text(
      time,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: UhvaColors.onSurfaceMuted,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _TvLiveContent extends StatefulWidget {
  final AppProvider provider;
  final ValueChanged<LiveChannel> onFocus;
  final ValueChanged<LiveChannel> onSelect;

  const _TvLiveContent({
    required this.provider,
    required this.onFocus,
    required this.onSelect,
  });

  @override
  State<_TvLiveContent> createState() => _TvLiveContentState();
}

class _TvLiveContentState extends State<_TvLiveContent> {
  String _catId = '';

  @override
  Widget build(BuildContext context) {
    final channels = _catId.isEmpty
        ? widget.provider.allChannels
        : widget.provider.allChannels
            .where((c) => c.categoryId == _catId)
            .toList();

    final recent = widget.provider.recentChannels;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pills
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TvPill(label: 'All', selected: _catId.isEmpty,
                    onTap: () => setState(() => _catId = '')),
                ...widget.provider.liveCategories.map((c) => _TvPill(
                      label: c.categoryName,
                      selected: _catId == c.categoryId,
                      onTap: () =>
                          setState(() => _catId = c.categoryId),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Continue watching
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
                  onFocus: widget.onFocus,
                  onSelect: widget.onSelect,
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // All channels
          _SectionHeader(title: _catId.isEmpty ? 'All channels' : ''),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: channels.length,
            itemBuilder: (_, i) => _TvChannelCard(
              channel: channels[i],
              onFocus: widget.onFocus,
              onSelect: widget.onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _TvChannelCard extends StatefulWidget {
  final LiveChannel channel;
  final ValueChanged<LiveChannel> onFocus;
  final ValueChanged<LiveChannel> onSelect;

  const _TvChannelCard({
    required this.channel,
    required this.onFocus,
    required this.onSelect,
  });

  @override
  State<_TvChannelCard> createState() => _TvChannelCardState();
}

class _TvChannelCardState extends State<_TvChannelCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) widget.onFocus(widget.channel);
      },
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
                ? UhvaColors.primary.withOpacity(0.2)
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
                  url: widget.channel.streamIcon,
                  name: widget.channel.name),
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
  const _TvPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
