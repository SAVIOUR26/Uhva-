import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel/category_bar.dart';
import '../player/vod_player_screen.dart';

class VodScreen extends StatefulWidget {
  const VodScreen({super.key});

  @override
  State<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends State<VodScreen> {
  String _selectedCat = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadVod();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final isLoading = provider.vodStreams.isEmpty;
    final vods = _selectedCat.isEmpty
        ? provider.vodStreams
        : provider.vodStreams
            .where((v) => v.categoryId == _selectedCat)
            .toList();

    return Scaffold(
      backgroundColor: UhvaColors.background,
      appBar: AppBar(
        backgroundColor: UhvaColors.surface,
        title: const Text('Movies',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        leading: const BackButton(color: Colors.white70),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: UhvaColors.primary))
          : Column(
              children: [
                // Category pills — in body so D-pad "down" reaches the grid
                CategoryBar(
                  categories: provider.vodCategories,
                  selectedId: _selectedCat,
                  onSelect: (id) => setState(() => _selectedCat = id),
                ),
                // Grid
                Expanded(
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: vods.length,
                      itemBuilder: (_, i) => _VodCard(
                        vod: vods[i],
                        autofocus: i == 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VodPlayerScreen(vod: vods[i])),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _VodCard extends StatefulWidget {
  final VodStream vod;
  final VoidCallback onTap;
  final bool autofocus;

  const _VodCard(
      {required this.vod, required this.onTap, this.autofocus = false});

  @override
  State<_VodCard> createState() => _VodCardState();
}

class _VodCardState extends State<_VodCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.vod.streamIcon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.vod.streamIcon,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: UhvaColors.surfaceAlt),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 9),
                            const SizedBox(width: 2),
                            Text(
                              widget.vod.rating5based.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_focused)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: UhvaColors.primary, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.vod.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: _focused
                    ? UhvaColors.primaryLight
                    : UhvaColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: UhvaColors.surfaceAlt,
      child: const Center(
        child: Icon(Icons.movie_outlined,
            color: UhvaColors.onSurfaceHint, size: 28),
      ),
    );
  }
}
