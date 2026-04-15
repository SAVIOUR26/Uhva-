import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/uhva_logo.dart';
import '../../widgets/channel/channel_tile.dart';
import '../../widgets/channel/category_bar.dart';
import '../player/player_screen.dart';
import '../vod/vod_screen.dart';
import '../series/series_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  LiveChannel? _nowPlaying;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  final _tabs = ['Live TV', 'Movies', 'Series', 'Favourites'];

  void _openChannel(LiveChannel channel) async {
    final provider = context.read<AppProvider>();
    await provider.addToHistory(channel);
    setState(() => _nowPlaying = channel);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(channel: channel),
      ),
    ).then((_) => setState(() => _nowPlaying = channel));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: UhvaColors.onBackground),
                decoration: const InputDecoration(
                  hintText: 'Search channels...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: UhvaColors.onSurfaceMuted),
                ),
                onChanged: provider.search,
              )
            : const UhvaLogo(size: 28, horizontal: true),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search,
                color: UhvaColors.onSurface),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  provider.search('');
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: UhvaColors.onSurface),
            color: UhvaColors.card,
            onSelected: (v) {
              if (v == 'settings') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (v == 'logout') {
                context.read<AppProvider>().logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings', style: TextStyle(color: UhvaColors.onBackground)),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Sign out', style: TextStyle(color: UhvaColors.onBackground)),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Column(
            children: [
              const Divider(height: 0),
              _TabBar(
                tabs: _tabs,
                selectedIndex: _navIndex,
                onSelect: (i) {
                  setState(() => _navIndex = i);
                  if (i == 1) provider.loadVod();
                  if (i == 2) provider.loadSeries();
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_navIndex == 0) ...[
            const SizedBox(height: 10),
            CategoryBar(
              categories: provider.liveCategories,
              selectedId: provider.selectedCategoryId,
              onSelect: provider.selectCategory,
            ),
            const SizedBox(height: 6),
          ],
          Expanded(child: _buildBody(provider)),
          if (_nowPlaying != null) _MiniPlayer(channel: _nowPlaying!, onTap: () => _openChannel(_nowPlaying!)),
        ],
      ),
    );
  }

  Widget _buildBody(AppProvider provider) {
    switch (_navIndex) {
      case 0:
        return _ChannelList(
          channels: provider.filteredChannels,
          selectedChannel: _nowPlaying,
          onTap: _openChannel,
          onFavTap: provider.toggleFavourite,
        );
      case 1:
        return const VodScreen();
      case 2:
        return const SeriesScreen();
      case 3:
        return _ChannelList(
          channels: provider.favouriteChannels,
          selectedChannel: _nowPlaying,
          onTap: _openChannel,
          onFavTap: provider.toggleFavourite,
          emptyMessage: 'No favourites yet.\nStar a channel to add it here.',
        );
      default:
        return const SizedBox();
    }
  }
}

class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TabBar({required this.tabs, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final sel = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 44,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: sel ? UhvaColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? UhvaColors.primaryLight : UhvaColors.onSurfaceMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ChannelList extends StatelessWidget {
  final List<LiveChannel> channels;
  final LiveChannel? selectedChannel;
  final void Function(LiveChannel) onTap;
  final Future<void> Function(LiveChannel) onFavTap;
  final String? emptyMessage;

  const _ChannelList({
    required this.channels,
    required this.onTap,
    required this.onFavTap,
    this.selectedChannel,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? 'No channels found',
          textAlign: TextAlign.center,
          style: const TextStyle(color: UhvaColors.onSurfaceMuted),
        ),
      );
    }
    return ListView.separated(
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 68),
      itemBuilder: (_, i) => ChannelTile(
        channel: channels[i],
        isSelected: selectedChannel?.streamId == channels[i].streamId,
        onTap: () => onTap(channels[i]),
        onFavouriteTap: () => onFavTap(channels[i]),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final LiveChannel channel;
  final VoidCallback onTap;

  const _MiniPlayer({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        color: UhvaColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: UhvaColors.liveRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: UhvaColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (channel.currentProgram != null)
                    Text(
                      channel.currentProgram!.title,
                      style: const TextStyle(
                          fontSize: 10, color: UhvaColors.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow, color: UhvaColors.primary, size: 26),
            const SizedBox(width: 4),
            const Icon(Icons.expand_less, color: UhvaColors.onSurfaceMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
