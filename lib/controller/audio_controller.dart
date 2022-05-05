import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioController {
  final AudioCache _cache = AudioCache(
    fixedPlayer: AudioPlayer(),
  );

  AudioController() {
    load();
  }

  Completer _completer = Completer();

  void load(){
    _cache.fixedPlayer!.onPlayerCompletion.listen((event) async {
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    });
  }

  Future<void> play(List<String> files) async {
    for (int i = 0; i < files.length; i++) {
      _completer = Completer();
      _cache.play("sounds/" + files[i] + ".mp3");
      await _completer.future;
    }
  }
}