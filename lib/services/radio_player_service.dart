import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RadioPlayerService {
  final Player _player = Player();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> play(String url) async {
    await WakelockPlus.enable();
    await _player.open(Media(url));
    _isPlaying = true;
  }

  Future<void> togglePlayPause() async {
    await _player.playOrPause();
    _isPlaying = _player.state.playing;
  }

  Future<void> stop() async {
    await _player.stop();
    await WakelockPlus.disable();
    _isPlaying = false;
  }

  void dispose() {
    _player.dispose();
    WakelockPlus.disable();
  }
}
