import 'dart:io';

import 'package:dating/constants.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/ui/chat/PlayerWidget.dart';
import 'package:dating/ui/chat/WidgetBubble.dart';
import 'package:dating/ui/chat/helpers.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';

class AudioBubble extends StatefulWidget {
  final MessageData messageData;
  final String audioURL;

  const AudioBubble({
    Key key,
    @required this.messageData,
    @required this.audioURL,
  }) : super(key: key);

  @override
  _AudioBubbleState createState() => _AudioBubbleState(this.messageData, this.audioURL);

}

class _AudioBubbleState extends State<AudioBubble> {

  AppUser currentUser;
  MemoryFileSystem memoryFileSystem;
  KeyPair keyPair;
  final MessageData messageData;
  final String audioURL;

  Widget _decryptedResults;

  _AudioBubbleState(this.messageData, this.audioURL);

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    memoryFileSystem = context.read<MemoryFileSystem>();
    keyPair = context.read<KeyPair>();
  }

  @override
  Widget build(BuildContext context) {

    if (_decryptedResults != null) {
      return _decryptedResults;
    }

    var fileName = Uri.parse(audioURL).queryParameters["token"];
    if (memoryFileSystem.file(fileName).existsSync()) {
      _decryptedResults = WidgetBubble(
        byCurrentUser: messageData.senderID == currentUser.userID,
        child: PlayerWidget(
          file: memoryFileSystem.file(fileName),
        ),
      );
      return _decryptedResults;
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        Gecies.decrypt(keyPair.privateKeyBase64, messageData.content.content[currentUser.userID]),
        getFile(memoryFileSystem, audioURL),
      ]),
      builder: (BuildContext innerContext, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<File>(
            future: decryptFileHelper(memoryFileSystem, (snapshot.data[0] as String), (snapshot.data[1] as File), fileName),
            builder: (BuildContext deepContext, AsyncSnapshot<File> innerSnap) {
              if (innerSnap.hasData) {
                _decryptedResults =  WidgetBubble(
                  byCurrentUser: messageData.senderID == currentUser.userID,
                  child: PlayerWidget(
                    file: memoryFileSystem.file(fileName),
                  ),
                );
                return _decryptedResults;
              } else if (innerSnap.hasError) {
                return WidgetBubble(
                  byCurrentUser:  messageData.senderID == currentUser.userID,
                  child: CircularProgressIndicator(),
                );
              } else {
                return SpinKitCubeGrid(color: Color(COLOR_PRIMARY_DARK));
              }
            },
          );
        } else if (snapshot.hasError) {
          _decryptedResults =  WidgetBubble(
            byCurrentUser:  messageData.senderID == currentUser.userID,
            child: Icon(Icons.error, color: Colors.redAccent),
          );
          return _decryptedResults;
        } else {
          return WidgetBubble(
            byCurrentUser:  messageData.senderID == currentUser.userID,
            child: CircularProgressIndicator(),
          );
        }
      },
    );

  }
}
