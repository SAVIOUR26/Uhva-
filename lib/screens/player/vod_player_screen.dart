import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';

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
    _init();
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
            _player.playOrPause();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowRight) {
            final pos = _player.state.position + const Duration(seconds: 10);
            _player.seek(pos);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowLeft) {
            final pos = _player.state.position - const Duration(seconds: 10);
            _player.seek(pos < Duration.zero ? Duration.zero : pos);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            SizedBox.expand(
              child: Video(controller: _videoController),
            ),
          // Top bar with back button + title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 32, 16, 16),
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_title.isNotEmpty)
                    Expanded(
                      child: Text(
                        _title,
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
        ],
        ),
      ),
    );
  }
}
