import 'dart:io';

import 'package:dating/constants.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/ui/chat/WidgetBubble.dart';
import 'package:dating/ui/chat/helpers.dart';
import 'package:dating/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:dating/ui/fullScreenVideoViewer/FullScreenVideoViewer.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';

class FileBubble extends StatefulWidget {

  final MessageData messageData;
  final  String mediaURL;
  final bool isVideo;

  const FileBubble({
    Key key,
    @required this.messageData,
    @required this.mediaURL,
    this.isVideo = false,
  }) : super(key: key);

  @override
  _FileBubbleState createState() => _FileBubbleState(this.messageData, this.mediaURL, this.isVideo);

}

class _FileBubbleState extends State<FileBubble> {

  final MessageData messageData;
  final String mediaURL;
  final bool isVideo;

  AppUser currentUser;
  MemoryFileSystem memoryFileSystem;
  KeyPair keyPair;
  Image image;
  bool processFailure = false;

  _FileBubbleState(this.messageData, this.mediaURL, this.isVideo);

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    memoryFileSystem = context.read<MemoryFileSystem>();
    keyPair = context.read<KeyPair>();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 50,
        maxWidth: 200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _decryptedImageFileContent(messageData, mediaURL),
            isVideo && messageData.videoThumbnail != null ?
            FloatingActionButton(
              mini: true,
              heroTag: messageData.messageID,
              backgroundColor: Color(COLOR_ACCENT),
              onPressed: () {
                push(context, FullScreenVideoViewer(heroTag: messageData.messageID, videoUrl: messageData.url.url));
              },
              child: Icon(
                Icons.play_arrow,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            )
                :
            Container(),
          ],
        ),
      ),
    );
  }

  Widget imageRenderer (Image image) {
    return GestureDetector(
      onTap: () {
        if (messageData.videoThumbnail == null) {
          push(context, FullScreenImageViewer(image: image.image, tag: messageData.messageID));
        }
      },
      child: Hero(
        tag: mediaURL,
        child: image,
      ),
    );
  }

  Widget _decryptedImageFileContent(MessageData messageData, String mediaURL) {

    if (image != null) {
      return imageRenderer(image);
    } else if (processFailure) {
      return WidgetBubble(
        byCurrentUser:  messageData.senderID == currentUser.userID,
        child: Icon(Icons.error, color: Colors.redAccent),
      );
    }

    var fileName = Uri.parse(mediaURL).queryParameters["token"];
    if (memoryFileSystem.file(fileName).existsSync()) {
      image = Image.memory(memoryFileSystem.file(fileName).readAsBytesSync());
      return imageRenderer(image);
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        Gecies.decrypt(keyPair.privateKeyBase64, messageData.content.content[currentUser.userID]),
        getFile(memoryFileSystem, mediaURL),
      ]),
      builder: (BuildContext innerContext, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<File>(
            future: decryptFileHelper(memoryFileSystem,(snapshot.data[0] as String), (snapshot.data[1] as File), fileName),
            builder: (BuildContext deepContext, AsyncSnapshot<File> innerSnap) {
              if (innerSnap.hasData) {
                image = Image.memory(innerSnap.data.readAsBytesSync());
                return imageRenderer(image);
              } else if (innerSnap.hasError) {
                return WidgetBubble(
                  byCurrentUser:  messageData.senderID == currentUser.userID,
                  child: Icon(Icons.error, color: Colors.redAccent),
                );
              } else {
                return SpinKitCubeGrid(color: Color(COLOR_PRIMARY_DARK));
              }
            },
          );
        } else if (snapshot.hasError) {
          processFailure = true;
          return WidgetBubble(
            byCurrentUser:  messageData.senderID == currentUser.userID,
            child: Icon(Icons.error, color: Colors.redAccent),
          );
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
