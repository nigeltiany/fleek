import 'dart:io';

import 'package:dating/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class PlayerWidget extends StatefulWidget {

  final File file;

  const PlayerWidget({
    Key key,
    this.file,
  }) : super(key: key);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState(file);

}

class _PlayerWidgetState extends State<PlayerWidget> {

  final File file;
  _PlayerWidgetState(this.file);

  @override
  void initState() {
    super.initState();
  }

  Future<Track> _loader(BuildContext context) async {
    var bytes = await file.readAsBytes();
    return Track(
      dataBuffer: bytes,
      codec: Codec.aacADTS,
    );
  }

  Widget get _player {
    return SoundPlayerUI.fromLoader(_loader,
      showTitle: false,
      audioFocus: AudioFocus.requestFocusAndDuckOthers,
      iconColor: Color(COLOR_PRIMARY_DARK),
      backgroundColor: Colors.white,
      textStyle: TextStyle(
        color: Color(COLOR_PRIMARY_DARK),
      ),
      sliderThemeData: SliderTheme.of(context).copyWith(
        trackHeight: 0,
        thumbColor: Colors.transparent,
        thumbShape: SliderComponentShape.noThumb,
        overlayShape: SliderComponentShape.noOverlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _player;
  }

}
