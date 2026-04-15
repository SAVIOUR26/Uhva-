import 'package:flutter/material.dart';
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

    if (provider.vodStreams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: UhvaColors.primary),
      );
    }

    final vods = _selectedCat.isEmpty
        ? provider.vodStreams
        : provider.vodStreams
            .where((v) => v.categoryId == _selectedCat)
            .toList();

    return Column(
      children: [
        const SizedBox(height: 10),
        CategoryBar(
          categories: provider.vodCategories,
          selectedId: _selectedCat,
          onSelect: (id) => setState(() => _selectedCat = id),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: vods.length,
            itemBuilder: (_, i) => _VodCard(
              vod: vods[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VodPlayerScreen(vod: vods[i])),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VodCard extends StatelessWidget {
  final VodStream vod;
  final VoidCallback onTap;

  const _VodCard({required this.vod, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  vod.streamIcon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vod.streamIcon,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: UhvaColors.surfaceAlt),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 9),
                          const SizedBox(width: 2),
                          Text(
                            vod.rating5based.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            vod.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: UhvaColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: UhvaColors.surfaceAlt,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: UhvaColors.onSurfaceHint, size: 28),
      ),
    );
  }
}
