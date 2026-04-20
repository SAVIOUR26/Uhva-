import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/channel/category_bar.dart';
import 'series_detail_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  String _selectedCat = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadSeries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final isLoading = provider.series.isEmpty;
    final items = _selectedCat.isEmpty
        ? provider.series
        : provider.series
            .where((s) => s.categoryId == _selectedCat)
            .toList();

    return Scaffold(
      backgroundColor: UhvaColors.background,
      appBar: AppBar(
        backgroundColor: UhvaColors.surface,
        title: const Text('Series', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: const BackButton(color: Colors.white70),
        bottom: isLoading ? null : PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: CategoryBar(
            categories: provider.seriesCategories,
            selectedId: _selectedCat,
            onSelect: (id) => setState(() => _selectedCat = id),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: UhvaColors.primary))
          : FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _SeriesCard(
                  series: items[i],
                  autofocus: i == 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SeriesDetailScreen(series: items[i])),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SeriesCard extends StatefulWidget {
  final SeriesStream series;
  final VoidCallback onTap;
  final bool autofocus;

  const _SeriesCard({required this.series, required this.onTap, this.autofocus = false});

  @override
  State<_SeriesCard> createState() => _SeriesCardState();
}

class _SeriesCardState extends State<_SeriesCard> {
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
                    widget.series.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.series.cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: UhvaColors.surfaceAlt),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    if (widget.series.rating5based > 0)
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
                                widget.series.rating5based.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Focus highlight border
                    if (_focused)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: UhvaColors.primary,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.series.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: _focused ? UhvaColors.primaryLight : UhvaColors.onSurface,
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
        child: Icon(Icons.video_library_outlined,
            color: UhvaColors.onSurfaceHint, size: 28),
      ),
    );
  }
}
